{
  inputs,
  pkgs,
  lib,
  config,
  ...
}: let
  homeDir = config.home.homeDirectory;
  in-home = path: "${homeDir}/${path}";
in {
  manual = {
    json.enable = false;
    manpages.enable = false;
  };

  fonts.fontconfig = {
    enable = true;
    defaultFonts.monospace = [
      "FiraCode Nerd Font Mono"
    ];
  };

  targets.darwin = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    # Home Manager's copied app bundles can invalidate Ghostty's launch
    # constraints on macOS 26. Keep apps symlinked to their Nix store bundles.
    copyApps.enable = false;
    linkApps.enable = true;
  };

  home = {
    file = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
      "Applications/Home Manager Apps".force = true;
    };
    packages =
      [
        inputs.ragenix.packages.${pkgs.stdenv.hostPlatform.system}.default
        inputs.gws.packages.${pkgs.stdenv.hostPlatform.system}.default
      ]
      ++ (with pkgs; [
        curl
        fd
        jq
        less
        ripgrep
        tree-sitter
        wget
        jc
        coreutils
        btop
        tokei
        zstd
        gh
        zola
        nu_scripts
        fontconfig
        nerd-fonts.fira-code
        nerd-fonts.symbols-only
        noto-fonts
        fira-sans
        _1password-cli
        gnupg
        yubikey-manager
        difftastic
        dix
        zellij
        gitleaks
        python314
      ]);
    stateVersion = "25.11";
  };

  programs = {
    home-manager.enable = true;
    bat = {
      enable = true;
      config = {
        theme = "OneHalfDark";
        pager = "less -FR";
      };
      syntaxes = {
        nu = {
          src = pkgs.fetchurl {
            url = "https://gist.githubusercontent.com/melMass/294c21a113d0bd329ae935a79879fe04/raw/93ed98bf1a02c4c0016eb49148cf111572235e41/nushell.sublime-syntax";
            hash = "sha256-QSjnGrv3o9qZ74b6Hk6pXJ6fx2Dq8U0cu9fyd51zokw=";
          };
        };
      };
    };
    man = {
      enable = true;
      generateCaches = true;
    };
    nh =
      {
        enable = true;
      }
      // lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
        darwinFlake = "/etc/nix-darwin";
      };
    fzf = {
      enable = true;
      enableZshIntegration = true;
    };
    direnv = {
      enable = true;
      enableNushellIntegration = true;
      config = {
        global.hide_env_diff = true;
        whitelist.prefix = ["~/work"];
      };
    };
    jq.enable = true;
  };

  services.ssh-agent = {
    enable = true;
  };
  xdg = {
    enable = true;
  };
}
