{ inputs, pkgs, lib, config, ... }:
let
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

  targets.darwin = lib.mkIf pkgs.stdenv.isDarwin {
    # Home Manager's copied app bundles can invalidate Ghostty's launch
    # constraints on macOS 26. Keep apps symlinked to their Nix store bundles.
    copyApps.enable = false;
    linkApps.enable = true;
  };

  home = {
    file = lib.mkIf pkgs.stdenv.isDarwin {
      "Applications/Home Manager Apps".force = true;
    };
    packages =
      [
        inputs.ragenix.packages.${pkgs.stdenv.hostPlatform.system}.default
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
        fira-sans
        _1password-cli
        gnupg
        yubikey-manager
        difftastic
        dix
        zellij
        gitleaks
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
    };
    man = {
      enable = true;
      generateCaches = true;
    };
    nh = {
      enable = true;
    } // lib.optionalAttrs pkgs.stdenv.isDarwin {
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
      };
    };
    jq.enable = true;
  };

  services.ssh-agent = {
    enable = true;
    enableNushellIntegration = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
  };
  xdg = {
    enable = true;
  };
}
