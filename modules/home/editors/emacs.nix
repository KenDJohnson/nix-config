{ config, lib, pkgs, ... }:
let
  homeDir = config.home.homeDirectory;
  doom-dir = "${homeDir}/.doom.d/";
in {
  config = lib.mkMerge [
    { programs.emacs.enable = lib.mkDefault config.programs.emacs.enable; }
    (lib.mkIf config.programs.emacs.enable {
      programs.emacs.extraPackages = epkgs: [epkgs.doom];
      home = {
        packages = [ pkgs.emacsclient-commands ];
        file.doom = {
          enable = true;
          recursive = true;
          source = ../doom.d;
          target = doom-dir;
        };
      };
    })
  ];
}
