{ config, lib, pkgs, ... }: {
  programs = {
    git = {
      enable = true;
      ignores = [
        ".DS_Store"
        ".AppleDouble"
        ".LSOverride"
        "Icon?"
        "._*"
        ".Spotlight-V100"
        ".Trashes"
        "*~"
        "*#"
        ".#*"
      ];
      includes = [
        { path = "${config.xdg.configHome}/git/secrets"; }
      ];
      settings = {
        core.editor = "emacsclient";
        init.defaultBranch = "master";
        push.autoSetupRemote = true;
        rerere.enabled = true;
        diff.algorithm = "patience";
      };
    };
    difftastic.enable = true;
    jujutsu = {
      enable = true;
      settings = {
        ui.diff-editor = ":builtin";
        ui.diff-formatter = ["difft" "--color" "always" "$left" "$right"];
      };
    };
  };
}
