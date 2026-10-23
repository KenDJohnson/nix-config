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
    ida.enable = mkEnableOption "IDA user environment (Nix Python for IDAPython, IDA venv)";
    agentTools.enable = mkEnableOption "agent tools (e.g. herdr)" // {default = true;};
    agents = {
      enable = mkEnableOption "agents and harnesses" // {default = true;};
      omp = {
        enable = mkEnableOption "OMP agent harness" // {default = false;};
        enableConfig = mkEnableOption "Manage OMP agent config without managing omp install" // {default = false;};
      };
    };
  };

  config.sshPersonalHosts = mkDefault (has config.machine.profiles "personal");
}
