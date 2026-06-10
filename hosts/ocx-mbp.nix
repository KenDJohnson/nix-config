{...}: {
  machine.profiles.work = true;
  machine.roles.desktop = true;
  devTools = {
    enable = true;
    languages = {
      cpp = true;
      node = true;
      python = true;
      nix = true;
      rust = true;
      zig = true;
    };
    latex = false;
  };
  codex.enable = true;
  zed.enable = true;
  networkingTools = false;
  tmux.enable = true;
}
