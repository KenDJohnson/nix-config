{ ... }:

{
  machineType = "personal";
  machineRole = "desktop";
  devTools = {
    enable = true;
    languages = { cpp = true; node = true; python = true; nix = true; rust = true; };
    latex = true;
  };
  networkingTools = true;
}
