{ inputs, pkgs, lib, config, host, ... }:
let
  homeDir = host.homeDirectory;
  in-home = path: "${homeDir}/${path}";
  doom-dir = (in-home ".doom.d/");
in {
  imports = [
    (import ./zsh.nix {
      inherit pkgs lib config host;
    })
    (import ./ssh.nix {
      inherit pkgs lib config;
    })
    (import ./secrets.nix {
      inherit config lib pkgs host;
    })
  ];

  manual = {
    json.enable = true;
    manpages.enable = true;
  };

  fonts.fontconfig = {
    enable = true;
    defaultFonts.monospace = [
      "FiraCode Nerd Font Mono"
    ];
  };

  home = {
    username = host.username;
    homeDirectory = host.homeDirectory;
    packages = [
      inputs.ragenix.packages.${pkgs.system}.default
    ] ++ (with pkgs; [
      curl
      fd
      jq
      less
      ripgrep
      tree-sitter
      wget
      #rustup
      jc
      mermaid-cli
      zola
      #kicad
      _1password-cli
      fontconfig
      # ghostty-bin
      coreutils
      direnv
      alejandra

      imhex
      tokei

      # (fenix.complete.withComponents [
      #   "cargo"
      #   "clippy"
      #   "rust-src"
      #   "rustc"
      #   "rustfmt"
      # ])
      # rust-analyzer-nightly

      shfmt
      shellcheck
      bash-language-server
      ffmpeg
      gnupg
      yubikey-manager

      devenv
      manix
      statix
      nil
      nix-search

      (texliveFull.withPackages (
        ps: with ps; [
          tidyres
          paracol
        ]
      ))
      ghostscript

      capnproto
      capnproto-rust
      protobuf

      gnumake
      llvm
      # libllvm
      clang
      # libclang
      # clang-tools
      libiconv

      btop

      uv
      # poetry

      utm

      silicon

      nu_scripts
      # tracy-glfw
      # tracy

      # cmake
      # freetype
      # glfw
      # pkg-config
      fontconfig
      nerd-fonts.fira-code
      fira-sans


      jc
      nodejs_24
      pnpm
      python312Packages.grip
      emacsclient-commands

      wireshark
      nmap

      raycast
    ]);
    shell.enableShellIntegration = true;
    shell.enableNushellIntegration = true;
    sessionPath = [
      (in-home ".cargo/bin")
      "${config.xdg.configHome}/emacs/bin"
      (in-home ".local/bin")
    ];
    sessionVariables = {
      PAGER = "less -RF";
      CLICOLOR = 1;
      # LIBRARY_PATH = lib.mkIf config.isDarwin <| makeLibraryPath <| attrValues {
      #   inherit (pkgs)
      #     libiconv
      # };
    };
    shellAliases = {
      l = "ls -l";
      cat = "bat";
      pat = "bat --plain";
      bathelp = "bat --plain --language=help";
    };
    #sessionSearchVariables = {
    #  MANPATH = [
    #    "${config.home.profileDirectory}/share/man"
    #    "${config.xdg.configHome}/.local/share/man"
    #  ];
    #};
    file.doom = {
      enable = true;
      recursive = true;
      source = ./doom.d;
      target = doom-dir;
      # onChange = "${homeDir}/.config/emacs/bin/doom sync";
    };
  };
  programs = {
    home-manager.enable = true;
    git = {
      enable = true;
      ignores = [
        # macOS specific files
        ".DS_Store"
        ".AppleDouble"
        ".LSOverride"
        "Icon?"
        # Thumbnail cache files
        "._*"
        ".Spotlight-V100"
        ".Trashes"
        # emacs files
        "*~"
        "*#"
        ".#*"
      ];
      includes = [
        { path = "${config.xdg.configHome}/git/secrets"; }
      ];
      settings = {
        core = {
          fsmonitor = true;
          editor = "emacsclient";
        };
        init = {
          defaultBranch = "master";
        };
        push = {
          autoSetupRemote = true;
        };
        rerere = {
          enabled = true;
        };
        diff = {
          algorithm = "patience";
        };
      };
    };
    #doom-emacs = {
    #  enable = true;
    #  doomDir = ./doom.d;
    #};
    emacs = {
      enable = true;
      extraPackages = epkgs: [ epkgs.doom ];
    };
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
    nushell = let
      nu_scripts_file = path: "${lib.getLib pkgs.nu_scripts}/share/nu_scripts/${path}";
      nu-mod = name: (nu_scripts_file "modules/${name}");
    in {
      enable = true;
      configFile.source = ./dotfiles/config.nu;
      environmentVariables.SHELL = "${lib.getExe pkgs.nushell}";
      environmentVariables.NIX_CONFIG_DIR = "/etc/nix-darwin/";
      shellAliases.ll = "ls -la";
      plugins = [
        pkgs.nushellPlugins.polars
        pkgs.nushellPlugins.query
        # pkgs.nushellPlugins.highlight
        pkgs.nushellPlugins.gstat
        pkgs.nushellPlugins.formats
        # pkgs.nushellPlugins.units
      ];
      extraConfig = ''
      const NU_LIB_DIRS = [
        ($nu.default-config-dir | path join 'scripts')
        ($nu.default-config-dir | path join 'modules')
        ($nu.default-config-dir | path join 'completions')
        ${lib.getLib pkgs.nu_scripts}/share/nu_scripts/modules/
      ];
      source '${nu_scripts_file "sourced/typeof.nu"}'
      use gitv2 gs
      use jc
      '';
    };
    fzf = {
      enable = true;
      enableZshIntegration = true;
    };
    jq.enable = true;
    jujutsu = {
      enable = true;
      settings = {
        # User info is in conf.d/secrets.toml (managed by activation script)
      };
    };
    #eza
    ghostty = {
      enable = true;
      enableZshIntegration = true;
      enableBashIntegration = true;
      installBatSyntax = true;
      package = pkgs.ghostty-bin;
      settings = {
        font-family = "Fira Code";
        window-title-font-family = "Fira Code";
        command = "${lib.getExe pkgs.zsh} -c \"${lib.getExe pkgs.nushell} --login\"";
        #copy-on-select = false;
        quick-terminal-position = "top";
        quick-terminal-screen = "main";
        #quick-terminal-screen = "mouse";
        quick-terminal-autohide = false;
        keybind = [
          "global:ctrl+shift+\\=toggle_quick_terminal"
        ];
      };
    };
    zed-editor = {
      enable = true;
      extensions = [
        "toml"
        "nix"
        "nu"
        "jsonnet"
        "opencode"
      ];
      mutableUserDebug = true;
      mutableUserKeymaps = true;
      mutableUserSettings = true;
      mutableUserTasks = true;
      userSettings = {
        base_keymap = "Emacs";
        vim_mode = true;
        which_key = { enabled = true; };
        terminal = {
          font_family = "FiraCode Nerd Font Mono";
          shell = {
            with_arguments = {
              program = lib.getExe pkgs.nushell;
              args = ["--login"];
              title_override = null;
            };
          };
        };
        ui_font_size = 16;
        buffer_font_size = 16;
      };
      userKeymaps = [
        {
          context = "(vim_mode == normal || vim_mode == visual) && !menu";
          bindings = {
            "space w v" = "pane::SplitDown";
            "space w s" = "pane::SplitRight";
            "space w h" = "workspace::ActivatePaneLeft";
            "space w j" = "workspace::ActivatePaneDown";
            "space w k" = "workspace::ActivatePaneUp";
            "space w l" = "workspace::ActivatePaneRight";
            "space w q" = "pane::CloseActiveItem";
            "space w r" = "pane::SplitRight";
            "space w d" = "pane::SplitDown";
            "space f" = "file_finder::Toggle";
            "space k" = "editor::Hover";
            "space s" = "outline::Toggle";
            "space shift s" = "project_symbols::Toggle";
            "space d" = "editor::GoToDiagnostic";
            "space r" = "editor::Rename";
            "space a" = "editor::ToggleCodeActions";
            "space h" = "editor::SelectAllMatches";
            "space c" = "editor::ToggleComments";
            "space p" = "editor::Paste";
            "space y" = "editor::Copy";
            "space /" = "pane::DeploySearch";
          };
        }
      ];
    };
  };
  services = {
    ssh-agent = {
      enable = true;
      enableNushellIntegration = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
    };
  };
  # xdg.enable = true;
  home.stateVersion = "25.11";
}

