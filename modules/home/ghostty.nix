{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}: let
  inherit (lib) attrNames attrValues concatLines filterAttrs flatten listToAttrs mapAttrs mapAttrsToList replaceStrings;

  ghosttyIntegration = lib.getOutput "shell_integration" pkgs.ghostty-bin;

  variableValues = config.home.sessionVariables // {
    HOME = config.home.homeDirectory;
    USER = config.home.username;
  };
  variablesMap = listToAttrs (flatten (mapAttrsToList (name: value: [ { name = "\$${name}"; value = toString value; } { name = "\${${name}}"; value = toString value; } ]) variableValues));
  expandVariables = value: replaceStrings (attrNames variablesMap) (attrValues variablesMap) (toString value);
  # expandedEnv = mapAttrs (_: expandVariables) (config.environment.variables // { PATH = config.environment.systemPath; });
  ghosttyEnv = (osConfig.environment.variables // { PATH = osConfig.environment.systemPath; })
    |> mapAttrs (n: v: if n == "XDG_DATA_DIRS" then (v + ":${ghosttyIntegration.outPath}") else v)
    |> mapAttrs (_: expandVariables)
    |> mapAttrsToList (name: value: "${name}=${value}");
in {
  config = lib.mkMerge [
    { programs.ghostty.enable = lib.mkDefault (config.machineRole == "desktop"); }
    (lib.mkIf config.programs.ghostty.enable {
      programs.ghostty = {
        enableZshIntegration = true;
        enableBashIntegration = true;
        installBatSyntax = true;
        package = pkgs.ghostty-bin;
        settings = {
          font-family = "Fira Code";
          window-title-font-family = "Fira Code";
          # command = "${lib.getExe pkgs.zsh} -c \"${lib.getExe pkgs.nushell} --login\"";
          command = "${lib.getExe pkgs.nushell} --login";
          quick-terminal-position = "top";
          quick-terminal-screen = "main";
          quick-terminal-autohide = false;
          shell-integration = "nushell";
          keybind = [
            "global:ctrl+shift+\\=toggle_quick_terminal"
          ];
          theme = "One Half Dark";
          env = ghosttyEnv ++ lib.optionals config.xdg.enable [
            "XDG_CONFIG_HOME=${config.xdg.configHome}"
            "XDG_DATA_HOME=${config.xdg.dataHome}"
          ];
        };
      };
    })
  ];
}
