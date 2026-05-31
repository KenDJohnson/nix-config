{...}: {
  machineType = "personal";
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
    latex = true;
  };
  networkingTools = true;
}
