{ pkgs, lib, config, ... }:
let
  homeDir = config.home.homeDirectory;
  in-home = path: "${homeDir}/${path}";
in {
  imports = [
    ./zsh.nix
    ./nushell.nix
  ];
  home.shell.enableShellIntegration = true;
  home.shell.enableNushellIntegration = true;
  home.sessionPath = [
    "${config.home.homeDirectory}/.cargo/bin"
    "${config.xdg.configHome}/emacs/bin"
    "${config.home.homeDirectory}/.local/bin"
    "${config.home.homeDirectory}/.opencode/bin"
  ];
  home.sessionVariables = {
    PAGER = "less -RF";
    CLICOLOR = 1;
  };
  home.sessionSearchVariables = {
    MANPATH = [
      "/usr/share/man"
      "/usr/local/share/man"
      "${config.home.profileDirectory}/share/man"
    ];
  };
  home.shellAliases = {
    l = "ls -l";
    cat = "bat";
    pat = "bat --plain";
    bathelp = "bat --plain --language=help";
  } // lib.optionalAttrs config.programs.emacs.enable {
    ec = "${lib.getExe' config.programs.emacs.finalPackage "emacsclient"} --tty";
    em = "${lib.getExe' config.programs.emacs.finalPackage "emacsclient"} --no-wait";
  };
}
