{ config, lib, pkgs, ... }: {
  config = lib.mkIf config.networkingTools {
    home.packages = with pkgs; [
      wireshark
      nmap
      ffmpeg
    ];
  };
}
