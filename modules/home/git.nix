{ config, lib, pkgs, ... }: {
  programs = {
    git = {
      enable = true;
      lfs.enable = true;
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
        alias = {
          dlog = "-c diff.external=${lib.getExe pkgs.difftastic} log --ext-diff";
          dl = "-c diff.external=${lib.getExe pkgs.difftastic} log --ext-diff";
          dshow = "-c diff.external=${lib.getExe pkgs.difftastic} show --ext-diff";
          ds = "-c diff.external=${lib.getExe pkgs.difftastic} show --ext-diff";
          ddiff = "-c diff.external=${lib.getExe pkgs.difftastic} diff";
          dft = "-c diff.external=${lib.getExe pkgs.difftastic} diff";
        };
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
