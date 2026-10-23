# Build a nix-darwin configuration locally and deploy it over SSH.
#
# Includes Home Manager when it is embedded in the selected nix-darwin system.
# Returns the configuration, target, and verified active store path.
#
# The target needs Nix, a trusted admin account, its agenix decryption keys, and
# remote-login Full Disk Access if macOS requires it for application updates.
# Non-interactive --yes execution uses sudo -n and requires passwordless sudo.
# No automatic rollback: failed activation can leave the system profile updated.
#
# Examples:
#   nixdeploy Kens-Mac-mini kjohnson@Kens-Mac-mini.local --dry-run
#   nixdeploy Kens-Mac-mini kjohnson@Kens-Mac-mini.local
#   nixdeploy Kens-Mac-mini mini --flake ~/.config/nix-config --yes
export def nixdeploy [
  configuration: string  # Name under darwinConfigurations.
  target?: string         # SSH destination, e.g. user@host or an SSH alias.
  --flake(-f): path      # Local checkout; defaults to NIX_CONFIG_DIR or the current directory.
  --yes(-y)              # Skip deployment confirmation, not sudo authentication.
  --dry-run(-n)          # Show the plan without building or contacting the target.
] {
  let flake = ($flake | default ($env.NIX_CONFIG_DIR? | default '.') | path expand)
  let target = ($target | default $configuration)

  if $dry_run {
    print $"Would build darwinConfigurations.($configuration) locally from ($flake)."
    print $"Would copy its closure to ($target), set the system profile, and activate it."
    print 'Would verify /run/current-system on the target.'
    return
  }

  let interactive = (is-terminal --stdin)

  let temporary = (mktemp --directory)
  let out_link = ($temporary | path join 'result')
  let result = try {
    print -e $"Building ($configuration) locally..."
    do --capture-errors {
      ^nh darwin build $flake --hostname $configuration --out-link $out_link
      # ^nh darwin build $flake --hostname $configuration --out-link $out_link --diff never out> /dev/stderr
    }
    let system = ($out_link | path expand --strict)

    print -e $"Copying ($system) to ($target)..."
    do --capture-errors {
      ^nix copy --no-check-sigs --to $"ssh-ng://($target)?remote-program=/nix/var/nix/profiles/default/bin/nix-daemon" $system out> /dev/stderr
    }

    print -e $"Activating ($configuration) on ($target)..."
    let ssh_options = if $interactive { ['-t'] } else { [] }
    let sudo = if $interactive { 'sudo -H' } else { 'sudo -n -H' }
    # Explicit sh keeps this independent of the remote account's login shell.
    # The store path is passed as data; set -e stops activation if profile registration fails.
    let activate = $"($sudo) /bin/sh -c 'set -eu; /nix/var/nix/profiles/default/bin/nix-env -p /nix/var/nix/profiles/system --set \"$1\"; exec \"$1/sw/bin/darwin-rebuild\" activate' sh '($system)'"
    do --capture-errors {
      ^ssh ...$ssh_options -- $target $activate out> /dev/stderr
    }

    let active_system = (do --capture-errors {
      ^ssh -- $target '/usr/bin/readlink /run/current-system'
    } | str trim)
    if $active_system != $system {
      error make {
        msg: 'Remote activation did not select the expected system.'
        help: $"Expected ($system); found ($active_system). No automatic rollback was attempted."
      }
    }

    {configuration: $configuration, target: $target, system: $system}
  } catch {|err|
    rm --recursive $temporary
    error make $err
  }
  rm --recursive $temporary
  $result
}


export alias "nixdeploy mini" = nixdeploy Kens-Mac-mini kjohnson@Kens-Mac-mini.local
# # Build a nix-darwin configuration locally and deploy it over SSH to the mac mini.
# #
# # Includes Home Manager when it is embedded in the selected nix-darwin system.
# # Returns the configuration, target, and verified active store path.
# export def "nixdeploy mini" [
#   --flake(-f): path      # Local checkout; defaults to NIX_CONFIG_DIR or the current directory.
#   --yes(-y)              # Skip deployment confirmation, not sudo authentication.
#   --dry-run(-n)          # Show the plan without building or contacting the target.
# ] {
#   nixdeploy Kens-Mac-mini kjohnson@Kens-Mac-mini.local --flake=$flake --yes=$yes --dry-run=$dry_run
# }
