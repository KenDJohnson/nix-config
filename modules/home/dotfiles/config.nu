def mk_env_conv [ sep: string ] {
    {
        from_string: { |s| $s | split row $sep | path expand --no-symlink }
        to_string: { |v| $v | path expand --no-symlink | str join $sep }
    }
}

$env.ENV_CONVERSIONS = $env.ENV_CONVERSIONS | merge {
    "XDG_DATA_DIRS": (mk_env_conv (char esep)),
    "XDG_CONFIG_DIRS": (mk_env_conv (char esep)),
    "TERMINFO_DIRS": (mk_env_conv (char esep)),
    "MANPATH": (mk_env_conv (char esep)),
    "NIX_PROFILES": (mk_env_conv " ")
}

$env.config.show_banner = false
$env.config.buffer_editor = ["emacsclient", "--tty"]
$env.config.use_kitty_protocol = true

$env.EDITOR = $env.config.buffer_editor | str join " "

# report prompt location info

$env.config.shell_integration.osc2 = true
$env.config.shell_integration.osc7 = true
$env.config.shell_integration.osc8 = true
$env.config.shell_integration.osc133 = true


$env.config.history.max_size = 10_000_000
$env.config.history.file_format = "sqlite"
$env.config.history.isolation = true

$env.config.completions.partial = true
$env.config.completions.sort = "smart"
$env.config.completions.quick = true
$env.config.completions.algorithm = "substring"
$env.config.completions.case_sensitive = false
$env.config.completions.use_ls_colors = true


$env.config.hooks.pre_prompt = []

$env.config.hooks.pre_execution = [
  # {||
  #   commandline
  #   | str trim
  #   | if ($in | is-not-empty) { print $"(ansi title)($in) — nu(char bel)" }
  # }
]

$env.config.hooks.env_change = {}

$env.config.hooks.display_output = {||
  tee { table --expand | print }
  # SQLiteDatabase doesn't support equality comparisions
  | try { if $in != null { $env.last = $in } }
}

$env.config.hooks.command_not_found = []




$env.config.display_errors.exit_code = false
$env.config.display_errors.termination_signal = false

#$env.NU_LIB_DIRS
#$env.NU_PLUGIN_DIRS

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
    $full | split column '.' | get 0 | get column1
  } else {
    $full
  }
}

def nixswitch [] {
  ^sudo darwin-rebuild switch --flake ($env.NIX_CONFIG_DIR | path join $".#(hostname)")
}
def "nixswitch doom" [] {
  nixswitch
  doom sync
}

source git.nu
source cmds.nu

use completions-jj.nu *
