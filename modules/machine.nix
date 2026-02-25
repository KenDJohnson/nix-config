{ config, lib, ... }:
let
  inherit (lib) mkOption mkEnableOption types;
in
{
  options = {
    machineType = mkOption {
      type = types.enum [ "personal" "work" ];
      default = "personal";
    };
    machineRole = mkOption {
      type = types.enum [ "desktop" "server" ];
      default = "desktop";
    };

    devTools = {
      enable = mkEnableOption "development toolchains" // { default = true; };
      languages = {
        cpp = mkEnableOption "C/C++ (gnumake, llvm, clang)";
        node = mkEnableOption "Node.js + pnpm";
        python = mkEnableOption "Python (uv, grip)";
        nix = mkEnableOption "Nix tools (nil, alejandra, statix, manix, devenv)";
        rust = mkEnableOption "Rust-adjacent (capnproto, protobuf)";
      };
      latex = mkEnableOption "LaTeX (texlive + ghostscript)";
    };
    networkingTools = mkEnableOption "Network tools (wireshark, nmap, ffmpeg)";
    sshPersonalHosts = mkEnableOption "Personal/homelab SSH hosts" // {
      default = config.machineType == "personal";
    };
  };
}
