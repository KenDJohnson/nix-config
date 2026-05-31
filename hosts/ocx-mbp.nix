{...}: {
  machineType = "work";
  machineRole = "desktop";
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
  networkingTools = false;
  tmux.enable = true;
}
