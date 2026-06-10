{
  config,
  lib,
  ...
}: let
  inherit (lib) mkDefault mkEnableOption mkOption types;
  has = attrs: name: attrs.${name} or false;
in {
  options = {
    machine = {
      profiles = mkOption {
        type = types.attrsOf types.bool;
        default = {};
        description = "Named configuration profiles to apply to this machine.";
      };
      roles = mkOption {
        type = types.attrsOf types.bool;
        default = {};
        description = "Named roles this machine serves.";
      };
    };

    devTools = {
      enable = mkEnableOption "development toolchains" // {default = true;};
      languages = {
        cpp = mkEnableOption "C/C++ (gnumake, llvm, clang)";
        node = mkEnableOption "Node.js + pnpm";
        python = mkEnableOption "Python (uv, grip)";
        nix = mkEnableOption "Nix tools (nil, alejandra, statix, manix, devenv)";
        rust = mkEnableOption "Rust-adjacent (capnproto, protobuf)";
        zig = mkEnableOption "zig toolchain";
      };
      latex = mkEnableOption "LaTeX (texlive + ghostscript)";
    };
    networkingTools = mkEnableOption "Network tools (wireshark, nmap, ffmpeg)";
    codex.enable = mkEnableOption "OpenAI Codex CLI";
    tmux.enable = mkEnableOption "tmux";
    zed.enable = mkEnableOption "Zed editor";
    sshPersonalHosts = mkEnableOption "Personal/homelab SSH hosts";
  };

  config.sshPersonalHosts = mkDefault (has config.machine.profiles "personal");
}
