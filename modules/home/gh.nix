{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf config.devTools.enable {
    home.programs.gh = {
      enable = true;
      settings = {
        git_protocol = "ssh";
        color_labels = "enabled";
        spinner = "disabled";
        aliases = {
          pv = "pr view";
        };
      };
      extensions = [
        pkgs.gh-stack
        pkgs.gh-markdown-preview
        pkgs.gh-dash
      ];
    };
  };
}
