{ ... }: {
  imports = [
    ./core.nix
    ./shells
    ./git.nix
    ./ssh.nix
    ./secrets.nix
    ./editors
    ./ghostty.nix
    ./desktop.nix
    ./dev-tools.nix
    ./networking.nix
  ];
}
