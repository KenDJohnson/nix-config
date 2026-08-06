{...}: {
  imports = [
    ./core.nix
    ./shells
    ./git.nix
    # ./gh.nix
    ./ssh.nix
    ./secrets.nix
    ./editors
    ./ghostty.nix
    ./desktop.nix
    ./dev-tools.nix
    ./work.nix
    ./networking.nix
    ./llm.nix
  ];
}
