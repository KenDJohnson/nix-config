{...}: {
  machine.profiles.personal = true;
  machine.profiles.work = true;
  machine.roles.desktop = true;
  determinateNix.determinateNixd.builder.memoryBytes = 17179869184;
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
