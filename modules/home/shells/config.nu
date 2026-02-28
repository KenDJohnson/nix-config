use std
use std null_device

use std/formats *
use std/iter

def mk_env_conv [ sep: string ] {
    {
        from_string: { |s| $s | split row $sep | path expand --no-symlink }
        to_string: { |v| $v | path expand --no-symlink | str join $sep }
    }
}

# format input string with an ansi code
def with-ansi [
    code: string              # ansi code to use (from `ansi -l`)
    --no-reset                # do not emit an `(ansi emit)` at the end
]: any -> string {
    let string = $in | into string
    let end = if $no_reset {
        ""
    } else {
        ansi reset
    }
    $"(ansi $code)($string)($end)"
}

std path add ($nu.default-config-dir | path join nupm plugins bin)

$env.ENV_CONVERSIONS = $env.ENV_CONVERSIONS | merge {
    "XDG_DATA_DIRS": (mk_env_conv (char esep)),
    "XDG_CONFIG_DIRS": (mk_env_conv (char esep)),
    "TERMINFO_DIRS": (mk_env_conv (char esep)),
    "MANPATH": (mk_env_conv (char esep)),
    "NIX_PROFILES": (mk_env_conv " ")
}

$env.config.show_banner = false
$env.config.buffer_editor = ["emacsclient", "--tty"]

$env.EDITOR = $env.config.buffer_editor | str join " "

$env.config.history.file_format = "sqlite"
$env.config.history.isolation = true
$env.config.history.max_size = 10_000_000

$env.config.use_kitty_protocol = true

$env.config.shell_integration.osc2 = true
$env.config.shell_integration.osc7 = true
$env.config.shell_integration.osc8 = true
$env.config.shell_integration.osc9_9 = true
$env.config.shell_integration.osc133 = true
$env.config.shell_integration.osc633 = true
$env.config.shell_integration.reset_application_mode = true

$env.config.bracketed_paste = true

$env.config.use_ansi_coloring = "auto"

$env.config.error_style = "fancy"

$env.config.highlight_resolved_externals = true

$env.config.display_errors.exit_code = false
$env.config.display_errors.termination_signal = true

$env.config.completions.algorithm = "fuzzy"
$env.config.completions.sort = "smart"
$env.config.completions.case_sensitive = false
$env.config.completions.quick = true
$env.config.completions.partial = true

$env.config.recursion_limit = 100

$env.config.table.mode = "single"
$env.config.table.index_mode = "always"
$env.config.table.show_empty = true
$env.config.table.padding.left = 1
$env.config.table.padding.right = 1
$env.config.table.trim.methodology = "wrapping"
$env.config.table.trim.wrapping_try_keep_words = true
$env.config.table.trim.truncating_suffix = "..."
$env.config.table.header_on_separator = true
$env.config.table.abbreviated_row_count = null
$env.config.table.footer_inheritance = true
$env.config.table.missing_value_symbol = $"(ansi magenta_bold)nope(ansi reset)"

$env.config.datetime_format.table = null
$env.config.datetime_format.normal = $"(ansi blue_bold)%Y(ansi reset)(ansi yellow)-(ansi blue_bold)%m(ansi reset)(ansi yellow)-(ansi blue_bold)%d(ansi reset)(ansi black)T(ansi magenta_bold)%H(ansi reset)(ansi yellow):(ansi magenta_bold)%M(ansi reset)(ansi yellow):(ansi magenta_bold)%S(ansi reset)"

$env.config.filesize.unit = "metric"
$env.config.filesize.show_unit = true
$env.config.filesize.precision = 1

$env.config.render_right_prompt_on_last_line = false

$env.config.float_precision = 2

$env.config.completions.use_ls_colors = true

$env.config.hooks.pre_prompt = []

$env.config.hooks.pre_execution = [
  {||
    commandline
    | str trim
    | if ($in | is-not-empty) { print $"(ansi title)($in) — nu(char bel)" }
  }
]

$env.config.hooks.env_change = {}

$env.config.hooks.display_output = {||
  tee { table --expand | print }
  # SQLiteDatabase doesn't support equality comparisions
  | try { if $in != null { $env.last = $in } }
}

$env.config.hooks.command_not_found = []

# `nu-highlight` with default colors
#
# Custom themes can produce a lot more ansi color codes and make the output
# exceed discord's character limits
def nu-highlight-default [] {
  let input = $in
  $env.config.color_config = {}
  $input | nu-highlight
}

# Copy the current commandline, add syntax highlighting, wrap it in a
# markdown code block, copy that to the system clipboard.
#
# Perfect for sharing code snippets on Discord.
def "nu-keybind commandline-copy" []: nothing -> nothing {
  commandline
  | nu-highlight-default
  | [
    "```ansi"
    $in
    "```"
  ]
  | str join (char nl)
  | clip copy --ansi
}

$env.config.keybindings ++= [
  {
    name: copy_color_commandline
    modifier: control_alt
    keycode: char_c
    mode: [ emacs vi_insert vi_normal ]
    event: {
      send: executehostcommand
      cmd: 'nu-keybind commandline-copy'
    }
  }
]

$env.config.color_config.bool = {||
  if $in {
    "light_green_bold"
  } else {
    "light_red_bold"
  }
}

$env.config.color_config.string = {||
  if $in =~ "^(#|0x)[a-fA-F0-9]+$" {
    $in | str replace "0x" "#"
  } else {
    "white"
  }
}

$env.config.color_config.row_index = "light_yellow_bold"
$env.config.color_config.header = "light_yellow_bold"


# Retrieve the output of the last command.
def _ []: nothing -> any {
  $env.last?
}

# Create a directory and cd into it.
def --env mc [path: path]: nothing -> nothing {
  mkdir $path
  cd $path
}

def full-hostname []: nothing -> string {
  sys host | get hostname
}

def hostname []: nothing -> string {
  let full = full-hostname
  if ($full | str contains '.') {
    $full | split row '.' | first
  } else {
    $full
  }
}

def "path shorten-home" []: path -> path {
    let path = $in
    if ($path | str starts-with $env.HOME) {
        "~" | path join ($path | path relative-to $env.HOME)
    } else {
        $path
    }
}

def os-icon [] {
    let os = $nu.os-info | get name
    if ($os == macos) {
        # 
        (char -u f179)
    } else if ($os == linux) {
        (char -u f17c)
    } else {
        ''
    }
}

# Get the top-level directory for the current git directory
#
# Error if the current directory is not a subdirectory of a git repo
def git-root-dir []: nothing -> path {
    let result = ^git rev-parse --show-toplevel | complete
    if $result.exit_code != 0 {
        error make -u { msg: "current directory is not a subdirectory of a git worktree" }
    } else {
        $result.stdout | str trim
    }
}

def repo-name-from-url [url:string]: nothing -> string {
    if ($url | str starts-with 'git@') {
      $url | split row '/' | last | str replace ".git" ""
    } else if ($url | str starts-with 'http') {
      $url | url parse | get path | split row '/' | last | str replace ".git" ""
    } else {
      error make {
          msg: $"unknown repo URL format",
          label: {
              text: "this URL",
              span: (metadata $url).span,
          }
      }
    }
}

# Get the name of the current git repo based on remote name
#
# Error if the current directory is not a subdirectory of a git repo
def git-repo-name [
    remote: string = "origin"         # git remote to parse the repo name from
]: nothing -> string {
    let remote = ^git remote get-url $remote | complete
    if $remote.exit_code != 0 {
        error make -u { msg: "current directory is not a subdirectory of a git worktree" }
    } else {
        let remote_url = $remote.stdout | lines | first | str trim
        repo-name-from-url $remote_url
    }
}

# Get the name of the current git repo based on remote name
def jj-repo-name [
    remote: string = "origin"
]: nothing -> string {
    let remotes = ^jj git remote list | complete
    if $remotes.exit_code != 0 {
        error make -u { msg: "current directory is not a subdirectory of a jj workspace" }
    } else {
        let remote_url = $remotes.stdout
            | lines
            | each { split row " " }
            | iter filter-map { if ($in.0 == $remote) { $in.1 } }
            | first
        repo-name-from-url $remote_url
    }
}

def "cwd in-jj" []: nothing -> bool {
    (^jj workspace root | complete | get exit_code) == 0
}

def "cwd in-git" []: nothing -> bool {
    (^git rev-parse --show-toplevel | complete | get exit_code) == 0
}

do --env {

    def repo-prompt-fmt [
        base: path
        reponame: string
        branch?: string
    ]: nothing -> string {
        mut parts = []

        let branch = if ($branch | is-not-empty) {
            $"(char -u e725) ($branch)"
        }

        let repo_dir = $base | path basename
        if $repo_dir == $reponame {
            $parts ++= [$"(ansi cyan_bold)(char -u e702)($branch) "]
        } else {
            $parts ++= [$"(ansi cyan_bold)(char -u e702) ($reponame)($branch) "]
        }


        $parts ++= [($"(char -u f413) ($base | path basename)" | with-ansi light_yellow_bold)]
        let subpath = pwd | path expand | path relative-to $base
        if ($subpath | is-not-empty) {
            # $" (char -u '2192') "
            $parts ++= [($"(ansi magenta_bold) → (ansi reset)(ansi blue)($subpath)")]
        }


        $parts | str join $"(ansi reset)"
    }

    def jj-prompt-body []: nothing -> string {
        repo-prompt-fmt (jj workspace root | str trim) (jj-repo-name)
    }
    def path-prompt-body []: nothing -> string {
        $"(ansi cyan)(pwd | path shorten-home)(ansi reset)"
    }

    def prompt-header [
        --left-char: string
    ]: nothing -> string {
        let code = $env.LAST_EXIT_CODE

        let hostname = if ($env.SSH_CONNECTION? | is-not-empty) {
            let hostname = try {
                hostname
            } catch {
                "remote"
            }
            $"@($hostname)" | with-ansi light_green_bold
        } else {
            ""
        }

        let repo_body = if (cwd in-jj) {
            repo-prompt-fmt (jj workspace root | str trim) (jj-repo-name)
        } else if (cwd in-git) {
            repo-prompt-fmt (git-root-dir) (^git branch --show-current err> $null_device | str trim)
        } else {
            path-prompt-body
        }
        let body = $"($hostname)($repo_body)"

        def make_prefix []: string -> string {
            $"┫($in)(ansi light_yellow_bold)┣"
        }
        let prefix = do {
            mut prefix = []
            let command_duration = ($env.CMD_DURATION_MS | into int) * 1ms
            if $command_duration >= 2sec {
                $prefix ++= [($"($command_duration)" | with-ansi light_magenta_bold)]
            }
            if $code != 0 {
                $prefix ++= [($code | with-ansi light_red_bold)]
            }

            $"(ansi light_yellow_bold)($left_char)($prefix | each { make_prefix } | str join '━')━(ansi reset)"
        }
        let suffix = do {
            mut suffix = []

            # NIX SHELL
            if ($env.IN_NIX_SHELL? | is-not-empty) {
            $suffix ++= [ $"(ansi light_blue_bold)nix" ]
            }

            $suffix | each { $'(ansi light_yellow_bold)•(ansi reset) ($in)(ansi reset)' } | str join " "
        }
        ([ $prefix, $body, $suffix ] | str join " ") + (char newline)
    }

    # char -u '2517'
    $env.PROMPT_INDICATOR = $"(ansi light_yellow_bold)┗(ansi reset) "
    $env.PROMPT_INDICATOR_VI_NORMAL = $env.PROMPT_INDICATOR
    $env.PROMPT_INDICATOR_VI_INSERT = $env.PROMPT_INDICATOR
    $env.PROMPT_MULTILINE_INDICATOR = $env.PROMPT_INDICATOR
    $env.PROMPT_COMMAND = {||
      prompt-header --left-char "┏"
    }
    $env.TRANSIENT_PROMPT_INDICATOR = "  "
    $env.TRANSIENT_PROMPT_INDICATOR_VI_INSERT = $env.TRANSIENT_PROMPT_INDICATOR
    $env.TRANSIENT_PROMPT_INDICATOR_VI_NORMAL = $env.TRANSIENT_PROMPT_INDICATOR
    $env.TRANSIENT_PROMPT_MULTILINE_INDICATOR = $env.TRANSIENT_PROMPT_INDICATOR
    $env.TRANSIENT_PROMPT_COMMAND = {||
      prompt-header --left-char "━"
    }
}


def nixswitch [] {
  ^sudo darwin-rebuild switch --flake ($env.NIX_CONFIG_DIR | path join $".#(hostname)")
}
def "nixswitch doom" [] {
  nixswitch
  doom sync
}

# SSH to a remote host, running `nu --login`
def nussh [host:string]: nothing -> any {
    ^ssh -t $host "nu --login"
}

# Run a `nu` command on a remote host
#
# Converts remote output to nuon then parses with `from nuon` locally to handle
# remote output like local output
def nu-remote [
    host:string            # remote host
    cmd:string             # nu cmd to run
]: nothing -> any {
    ^ssh -q -t $host $"nu --login --commands '$(cmd) | to nuon -r'" | from nuon
}

# Show all symlink steps until reaching a real file/directory
def follow-link-path []: string -> list<path> {
    let initial = $in
    generate {|p|
        if (($p | path type) == symlink) {
            { out: $p, next: (^readlink $p) }
        } else {
            { out: $p }
        }
    } $initial
}

# Open a Nix REPL preloaded with this flake's Home Manager context.
#
# Predefines these values in the REPL:
# - `cfg`: selected `darwinConfigurations."<host>"`
# - `pkgs`: package set for the selected host
# - `lib`: `pkgs.lib`
# - `hm`: `cfg.config.home-manager.users."<user>"`
# - `opts`: Home Manager user option schema (`home-manager.users` suboptions)
#
# Defaults:
# - `--flake`: current directory (`.`)
# - `--host`: current machine hostname
# - `--user`: `$env.USER`
#
# Examples:
# - `hm repl`
# - `hm repl -H "Kens-MBP"`
# - `hm repl -f ~/.config/nix-config -H "Kens-MBP" -u kjohnson`
def "hm repl" [
  --flake(-f): path
  --host(-H): string
  --user(-u): string
] {
  let flake_path = ($flake | default $env.NIX_CONFIG_DIR) | path expand
  let host = ($host | default (hostname))
  let user = ($user | default (whoami))
  let expr = $"
    let
      flake = builtins.getFlake \"($flake_path)\";
      cfg = flake.darwinConfigurations.\"($host)\";
    in {
      inherit cfg;
      pkgs = cfg.pkgs;
      lib = cfg.pkgs.lib;
      hm = cfg.config.home-manager.users.\"($user)\";
      opts = cfg.options.home-manager.users.type.getSubOptions [];
    }"

  ^nix repl --impure --expr $expr
}

source git.nu
source cmds.nu

use completions-jj.nu *
