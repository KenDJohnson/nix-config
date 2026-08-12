{
  config,
  lib,
  pkgs,
  machineLib,
  ...
}: let
  machine = machineLib.forConfig config;
in {
  config = machine.applyDesktop {
    home.packages = with pkgs;
      [imhex mermaid-cli]
      ++ lib.optionals (pkgs.stdenv.isDarwin) [raycast]
      ++ lib.optionals (pkgs.stdenv.isDarwin && machine.hasProfile "personal") [utm];
    # programs.obsidian.enable = lib.mkDefault true;
  };
}
