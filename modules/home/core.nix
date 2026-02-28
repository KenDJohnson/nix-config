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

  home = {
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
        direnv
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
      ]);
    shell.enableShellIntegration = true;
    shell.enableNushellIntegration = true;
    sessionPath = [
      (in-home ".cargo/bin")
      "${config.xdg.configHome}/emacs/bin"
      (in-home ".local/bin")
      (in-home ".opencode/bin")
    ];
    sessionVariables = {
      PAGER = "less -RF";
      CLICOLOR = 1;
    };
    shellAliases = {
      l = "ls -l";
      cat = "bat";
      pat = "bat --plain";
      bathelp = "bat --plain --language=help";
    } // lib.optionalAttrs config.programs.emacs.enable {
      ec = "${lib.getExe' config.programs.emacs.finalPackage "emacsclient"} --tty";
    };
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
    fzf = {
      enable = true;
      enableZshIntegration = true;
    };
    jq.enable = true;
  };

  services.ssh-agent = {
    enable = true;
    enableNushellIntegration = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
  };
}
