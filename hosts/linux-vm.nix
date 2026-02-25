{ ... }:

{
  machineType = "personal";
  machineRole = "server";
  devTools = {
    enable = true;
    languages = { nix = true; rust = true; };
  };
}
