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

  # Mac Mini: server-like behavior - prevent sleep but allow display off
  power.sleep = {
    computer = "never";
    display = 15;
    harddisk = "never";
  };
}
