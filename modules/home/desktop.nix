{ config, lib, pkgs, ... }: {
  config = lib.mkIf (config.machineRole == "desktop") {
    home.packages = with pkgs;
      [ imhex mermaid-cli ]
      ++ lib.optionals (pkgs.stdenv.isDarwin) [ raycast ]
      ++ lib.optionals (pkgs.stdenv.isDarwin && config.machineType == "personal") [ utm ];
    programs.obsidian.enable = lib.mkDefault true;
  };
}
