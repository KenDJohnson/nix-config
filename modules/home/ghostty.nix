{ config, lib, pkgs, ... }: {
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
          command = "${lib.getExe pkgs.zsh} -c \"${lib.getExe pkgs.nushell} --login\"";
          quick-terminal-position = "top";
          quick-terminal-screen = "main";
          quick-terminal-autohide = false;
          keybind = [
            "global:ctrl+shift+\\=toggle_quick_terminal"
          ];
          theme = "One Half Dark";
        };
      };
    })
  ];
}
