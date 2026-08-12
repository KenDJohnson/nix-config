{ config, lib, pkgs, ... }: {
  config = lib.mkMerge [
    { programs.zed-editor.enable = lib.mkDefault false; }
    (lib.mkIf config.programs.zed-editor.enable {
      programs.zed-editor = {
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
          buffer_font_family = "FiraCode Nerd Font Mono";
          vim_mode = true;
          which_key.enabled = true;
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
          languages = {
            Nix = {
              formatter.external = {
                command = lib.getExe pkgs.alejandra;
                arguments = ["--queit" "--"];
              };
              language_servers = ["nil" "!nixd"];
            };
            Rust = {
              semantic_tokens = "full";
            };
          };
          load_direnv = "direct";
          lsp = {
            nil = {
              formatting.command = [(lib.getExe pkgs.alejandra) "--quiet" "--"];
              flake = {
                autoArchive = true;
                autoEvalInputs = true;
              };
            };
          };
          preview_tabs = {
            enabled = true;
            enable_preview_from_project_panel = true;
            enable_preview_from_file_finder = false;
            enable_preview_from_multibuffer = false;
            #enable_preview_multibuffer_from_code_navigation = true; # nondefault
            enable_preview_file_from_code_navigation = true;
            enable_keep_preview_on_code_navigation = true; # nondefault
          };
          search = {
            regex = true;
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
    })
  ];
}
