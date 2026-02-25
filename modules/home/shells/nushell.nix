{ config, lib, pkgs, ... }:
let
  nu_scripts_file = path: "${lib.getLib pkgs.nu_scripts}/share/nu_scripts/${path}";
in {
  programs.nushell = {
    enable = true;
    configFile.source = ./config.nu;
    environmentVariables.SHELL = "${lib.getExe pkgs.nushell}";
    environmentVariables.NIX_CONFIG_DIR = "/etc/nix-darwin/";
    shellAliases.ll = "ls -la";
    plugins = [
      pkgs.nushellPlugins.polars
      pkgs.nushellPlugins.query
      pkgs.nushellPlugins.gstat
      pkgs.nushellPlugins.formats
    ];
    extraConfig = ''
      const NU_LIB_DIRS = [
        ($nu.default-config-dir | path join 'scripts')
        ($nu.default-config-dir | path join 'modules')
        ($nu.default-config-dir | path join 'completions')
        ${lib.getLib pkgs.nu_scripts}/share/nu_scripts/modules/
      ];
      source '${nu_scripts_file "sourced/typeof.nu"}'
      use gitv2 gs
      use jc
    '';
  };
}
