{
  config,
  lib,
  pkgs,
  machineLib,
  ...
}: let
  machine = machineLib.forConfig config;
  nu = config.programs.nushell;
  nuExe = lib.getExe nu.package;
  nuPaneConfig =
    pkgs.writers.writeText "tern-nu-pane.nu"
    ''
      source ($nu.default-config-dir | path join "config.nu")
      $env.config.hooks.pre_execution = (
        $env.config.hooks.pre_execution? | default [] | append [
          {||
            try {
              let line = commandline
              let sq = "\u{27}"
              let escape = $sq + "\u{5c}" + $sq + $sq
              let quoted = $sq + ($line | str replace --all $sq $escape) + $sq
              print --no-newline $"\u{1b}]133;C;cmdline=($quoted)\u{7}"

            } catch { }
          }
        ]
      )
    '';
  paneShell = pkgs.writeShellScriptBin "tern-nu-pane" ''
    # export XDG_CONFIG_HOME=${lib.escapeShellArg config.xdg.configHome}
    # export XDG_DATA_HOME=${lib.escapeShellArg config.xdg.dataHome}
    exec ${nuExe} \
      --login \
      --env-config ${lib.escapeShellArg "${nu.configDir}/env.nu"} \
      --config ${lib.escapeShellArg "${nu.configDir}/config.nu"} \
      "$@"
  '';
  paneShell =
    pkgs.writeShellScript "tern-nu-pane" # bash
    
    ''
      exec ${nuExe} \
        --login \
        --env-config ${lib.escapeShellArg "${nu.configDir}/env.nu"} \
        --config ${nuPaneConfig} \
        "$@"
    '';
in {
  config =
    lib.mkIf (pkgs.stdenv.hostPlatform.isDarwin && machine.hasRole "desktop")
    {
      home.packages = [paneShell];
    };
}
