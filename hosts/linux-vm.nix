{...}: {
  machine.profiles.personal = true;
  machine.roles.server = true;
  devTools = {
    enable = true;
    languages = {
      nix = true;
      rust = true;
    };
  };
}
