{ config, lib, pkgs, host, ... }:

let
  zshConfDir = ".config/zsh";
  myFunctions = pkgs.stdenvNoCC.mkDerivation rec {
    name = "zsh-functions-${version}";
    version = "0.0.1";
    src = ./functions;
    phases = [ "installPhase" ];
    installPhase = ''
      mkdir $out
      cp $src/* $out/
    '';
  };
in {
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;
    history = {
      ignoreDups = true;
      ignoreAllDups = true;
      ignoreSpace = true;
      save = 1000000;
      size = 1000000;
      share = false;
    };
    shellAliases.ls = "ls --color=auto";
    shellAliases.ll = "ls -lahrts";
    shellAliases.nixswitch =
        "sudo darwin-rebuild switch --flake /etc/nix-darwin/.#${host.hostname}";
    shellAliases.nixpkgup = "(cd /etc/nix-darwin/ && sudo nix flake update nixpkgs)";

    oh-my-zsh = {
      enable = true;
      theme = "sunaku";
      plugins = [ "gitfast" "vi-mode" ];
    };
    plugins = [{
      name = "local-functions";
      src = myFunctions;
      file = "functions.zsh";
    }];
  };

}
