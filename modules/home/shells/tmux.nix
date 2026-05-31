{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf config.tmux.enable {
    programs.tmux = {
      enable = true;
      mouse = config.machineRole == "desktop";
      prefix = "C-Space";
      shell = lib.getExe pkgs.nushell;
      plugins = with pkgs; [
        tmuxPlugins.better-mouse-mode
        # tmuxPlugins.onedark-theme
        tmuxPlugins.tmux-powerline
        # tmuxPlugins.tmux-thumbs
        # tmuxPlugins.tmux-toggle-popup
        # tmuxPlugins.tmux-which-key
        tmuxPlugins.extrakto
        tmuxPlugins.tmux-fzf
      ];
      keyMode = "vi";
      aggressiveResize = true;
      focusEvents = true;
      terminal = "tmux-256color";
      extraConfig = ''
        set -g default-command "${lib.getExe pkgs.nushell} --login"

        set -g status-position top
        set -g status-interval 1

        # Sets time in milliseconds during which a key press is considered a repeat
        set-option -g repeat-time 300

        # Override default screen clearing, let's not wipe history
        bind -n C-l send-keys C-l


        # set -g default-terminal "tmux-256color"
        set -as terminal-features ',xterm-ghostty:sixel'
        set -g allow-passthrough on
      '';
    };
  };
}
