{
  config,
  lib,
  pkgs,
  machineLib,
  ...
}: let
  ternDir =
    if pkgs.stdenv.hostPlatform.isDarwin
    then "${config.home.homeDirectory}/Library/Application Support/Tern"
    else "${config.xdg.configHome}/tern";
  machine = machineLib.forConfig config;
  nu = config.programs.nushell;
  nuExe = lib.getExe nu.package;
  nuArgs = lib.escapeShellArgs [
    "--env-config"
    "${nu.configDir}/env.nu"
    "--config"
    "${nu.configDir}/config.nu"
  ];
  xdgEnv = ''
    export XDG_CONFIG_HOME=${lib.escapeShellArg config.xdg.configHome}
    export XDG_DATA_HOME=${lib.escapeShellArg config.xdg.dataHome}
  '';

  # Probe protocol adapted from:
  # https://github.com/plumj-am/nixos/blob/master/packages/tern/tern.nix
  # Tern probes $SHELL with POSIX syntax, independently of settings.json's shell.
  loginProbe = pkgs.writeShellScript "tern-login-shell-probe" ''
    ${xdgEnv}
    case " $* " in
      *__stencil_login_env__*|*__tern_login_env__*|*__tern_login_path__*)
        exec ${lib.getExe pkgs.bashInteractive} "$@"
        ;;
    esac
    # login(1)'s leading '-' in argv[0] is lost when the shell is a script.
    # Its argument-free invocation should still start a Nu login shell.
    if [ "$#" -eq 0 ]; then
      set -- --login
    fi
    exec ${nuExe} ${nuArgs} "$@"
  '';
  # Keep the basename "nu" for Tern's shell detection, but do not put this on
  # PATH: it would collide with the real Nushell package's bin/nu.
  loginShell = pkgs.runCommand "tern-login-shell" {} ''
    install -Dm755 ${loginProbe} "$out/bin/nu"
  '';
  paneShell = pkgs.writeShellScriptBin "tern-nu-pane" ''
    ${xdgEnv}
    export SHELL=${loginShell}/bin/nu
    exec ${nuExe} --login ${nuArgs} "$@"
  '';
  json = pkgs.formats.json {};
  settings = {
    theme = "System";
    theme_dark = "dark-arctic";
    link_click = "Command";
    link_target = "Browser";
    font_family = "FiraCode Nerd Font Mono";
    code_font = "FiraCode Nerd Font Mono";
    pane_headers = "Always";
    status_bar = true;
    composer_text = "Markdown";
    # Saved pane commands must survive rebuilds and garbage collection.
    shell = "${config.home.profileDirectory}/bin/tern-nu-pane";
    prefs_width = 641;
    file_tree = {
      open = true;
    };
    agents = {
      own_tools = [
        "codex"
      ];
    };
  };
in {
  config = lib.mkIf (pkgs.stdenv.hostPlatform.isDarwin && machine.hasRole "desktop" && nu.enable) {
    home.packages = [paneShell];
    # After changing SHELL, use Tern's "Restart session daemon" to refresh the
    # login shell advertised to remote clients without ending running panes.
    home.sessionVariables.SHELL = "${loginShell}/bin/nu";

    # Use the normal Home Manager config so plain `nu` panes, including restored
    # panes, get the payload too. Append after the existing title/config hooks.
    programs.nushell.extraConfig = lib.mkAfter ''
      if $env.TERM_PROGRAM? == "tern" {
        # Apply after config.nu's PATH additions. Native shell integration may
        # consume TERN_PATH_PREPEND before a nested Nu starts.
        let tern_paths = (
          $env.TERN_PATH_PREPEND?
          | default ${builtins.toJSON "${ternDir}/omp/bin"}
          | split row (char esep)
          | where $it != ""
          | path expand --no-symlink
          | where {|dir| $dir | path exists}
          | uniq
        )
        $env.PATH = $tern_paths ++ ($env.PATH | where {|dir| $dir not-in $tern_paths})

        $env.config.hooks.pre_execution = (
          $env.config.hooks.pre_execution? | default [] | append [
            {||
              try {
                let line = (commandline)
                if not ($line | is-empty) {
                  # Quote each payload field as one POSIX word, including
                  # embedded apostrophes, for Tern's command-line decoder.
                  let sq = "\u{27}"
                  let esc = ($sq + "\u{5c}" + $sq + $sq)
                  let trimmed = ($line | str trim --left)
                  let head = ($trimmed | split row --regex '\s+' | first)
                  let hit = (scope aliases | where name == $head | get expansion)
                  let rest = ($trimmed | str replace --regex '^\S+' "")
                  let full = (if ($hit | is-empty) { $line } else { ($hit | first) + $rest })
                  let typed = ($sq + ($line | str replace --all -- $sq $esc) + $sq)
                  let expanded = ($sq + ($full | str replace --all -- $sq $esc) + $sq)
                  print -n $"\u{1b}]133;C;cmdline=($typed);cmdline_expanded=($expanded)\u{7}"
                }
              } catch { }
            }
          ]
        )
      }
    '';
    home.activation.ternConfig = lib.hm.dag.entryAfter ["linkGeneration"] (
      lib.hm.generators.mkImpureConfigMerger {
        inherit pkgs;
        format = "json";
        empty = "{}";
        jqOperation = "$dynamic * $static";
        path = "${ternDir}/settings.json";
        staticSettings = json.generate "tern-settings.json" settings;
      }
    );
  };
}
