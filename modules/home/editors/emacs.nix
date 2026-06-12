{
  config,
  lib,
  pkgs,
  ...
}: let
  homeDir = config.home.homeDirectory;
  doom-dir = "${homeDir}/.doom.d/";
  regular-emacs-dir = "${config.xdg.configHome}/emacs-regular";
  emacs-package = pkgs.emacs;
  emacs-packages = pkgs.emacsPackagesFor emacs-package;
  treesit-grammars = emacs-packages.treesit-grammars.with-grammars (grammars:
    with grammars; [
      tree-sitter-bash
      tree-sitter-c
      tree-sitter-cpp
      tree-sitter-css
      tree-sitter-dockerfile
      tree-sitter-elisp
      tree-sitter-graphql
      tree-sitter-hcl
      tree-sitter-html
      tree-sitter-javascript
      tree-sitter-jsdoc
      tree-sitter-json
      tree-sitter-jsonnet
      tree-sitter-markdown
      tree-sitter-markdown-inline
      tree-sitter-nix
      tree-sitter-nu
      tree-sitter-ocaml
      tree-sitter-ocaml-interface
      tree-sitter-python
      tree-sitter-ron
      tree-sitter-rust
      tree-sitter-toml
      tree-sitter-tsx
      tree-sitter-typescript
      tree-sitter-yaml
    ]);
  regular-emacs = emacs-packages.emacsWithPackages (epkgs:
    with epkgs; [
      apheleia
      consult
      corfu
      direnv
      doom-modeline
      doom-themes
      dune
      evil
      evil-collection
      gptel
      graphviz-dot-mode
      hcl-mode
      jq-mode
      json-mode
      jsonnet-mode
      key-chord
      lsp-mode
      lsp-ui
      llvm-mode
      magit
      marginalia
      markdown-mode
      mermaid-mode
      nerd-icons
      nerd-icons-corfu
      nix-mode
      nushell-mode
      orderless
      org-journal
      org-modern
      org-roam
      projectile
      racket-mode
      ron-mode
      rust-mode
      rustic
      smartparens
      terraform-mode
      treesit-auto
      tuareg
      typescript-mode
      vertico
      web-mode
      which-key
      yaml-mode
      yasnippet
    ]);
  emacs-regular = pkgs.writeShellScriptBin "emacs-regular" ''
    exec ${regular-emacs}/bin/emacs --init-directory ${lib.escapeShellArg regular-emacs-dir} "$@"
  '';
  emacs-regular-daemon = pkgs.writeShellScriptBin "emacs-regular-daemon" ''
    exec ${regular-emacs}/bin/emacs --init-directory ${lib.escapeShellArg regular-emacs-dir} --daemon=regular "$@"
  '';
  emacsclient-regular = pkgs.writeShellScriptBin "emacsclient-regular" ''
    exec ${regular-emacs}/bin/emacsclient --socket-name regular --alternate-editor=${lib.escapeShellArg "${emacs-regular}/bin/emacs-regular"} "$@"
  '';
in {
  config = lib.mkMerge [
    {programs.emacs.enable = lib.mkDefault true;}
    (lib.mkIf config.programs.emacs.enable {
      # Keep the existing Doom installation and default emacs command untouched.
      home = {
        packages = [
          pkgs.emacsclient-commands
          pkgs.terraform-ls
          emacs-regular
          emacs-regular-daemon
          emacsclient-regular
        ];
        file = {
          doom = {
            enable = true;
            recursive = true;
            source = ../doom.d;
            target = doom-dir;
          };
          doom-treesit-typescript-dylib = {
            enable = true;
            source = "${treesit-grammars}/lib/libtree-sitter-typescript.dylib";
            target = "${config.xdg.configHome}/emacs/.local/etc/tree-sitter/libtree-sitter-typescript.dylib";
          };
          doom-treesit-typescript-so = {
            enable = true;
            source = "${treesit-grammars}/lib/libtree-sitter-typescript.dylib";
            target = "${config.xdg.configHome}/emacs/.local/etc/tree-sitter/libtree-sitter-typescript.so";
          };
          doom-treesit-tsx-dylib = {
            enable = true;
            source = "${treesit-grammars}/lib/libtree-sitter-tsx.dylib";
            target = "${config.xdg.configHome}/emacs/.local/etc/tree-sitter/libtree-sitter-tsx.dylib";
          };
          doom-treesit-tsx-so = {
            enable = true;
            source = "${treesit-grammars}/lib/libtree-sitter-tsx.dylib";
            target = "${config.xdg.configHome}/emacs/.local/etc/tree-sitter/libtree-sitter-tsx.so";
          };
          emacs-regular-early-init = {
            enable = true;
            source = ./emacs-regular/early-init.el;
            target = "${regular-emacs-dir}/early-init.el";
          };
          emacs-regular-init = {
            enable = true;
            source = pkgs.replaceVars ./emacs-regular/init.el {
              treesitGrammars = "${treesit-grammars}/lib";
            };
            target = "${regular-emacs-dir}/init.el";
          };
        };
      };
    })
  ];
}
