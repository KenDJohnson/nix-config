{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  config = lib.mkIf config.agentTools.enable {
    home.packages = [inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default];
    home.file.herdr = {
      enable = false;
      source = ./herdr/config.toml;
      target = "${config.xdg.configHome}/herdr/config.toml";
    };
  };
}
