{
  config,
  lib,
  pkgs,
  ...
}: let
  zshConfDir = ".config/zsh";
  myFunctions = pkgs.stdenvNoCC.mkDerivation rec {
    name = "zsh-functions-${version}";
    version = "0.0.1";
    src = ./zsh-functions;
    phases = ["installPhase"];
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
    dotDir = "${config.xdg.configHome}/zsh";
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
    shellAliases.nixswitch = "sudo darwin-rebuild switch --flake /etc/nix-darwin/.#$(hostname -s)";
    shellAliases.nixpkgup = "(cd /etc/nix-darwin/ && sudo nix flake update nixpkgs)";

    oh-my-zsh = {
      enable = true;
      theme = "sunaku";
      plugins = ["gitfast" "vi-mode"];
    };
    initContent =
      ''
        if [ -r "${config.xdg.configHome}/codex/mcp-tokens.env" ]; then
          source "${config.xdg.configHome}/codex/mcp-tokens.env"
        fi
      ''
      + lib.optionalString (config.machineType == "work") ''
        if [ -r "${config.xdg.configHome}/work/env.sh" ]; then
          source "${config.xdg.configHome}/work/env.sh"
        fi
      '';
    plugins = [
      {
        name = "local-functions";
        src = myFunctions;
        file = "functions.zsh";
      }
    ];
  };
}
