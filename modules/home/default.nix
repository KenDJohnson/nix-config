{...}: {
  imports = [
    ./agent-tools.nix
    ./agents.nix
    ./core.nix
    ./shells
    ./git.nix
    # ./gh.nix
    ./ssh.nix
    ./secrets.nix
    ./editors
    ./ghostty.nix
    ./desktop.nix
    ./ida.nix
    ./dev-tools.nix
    ./work.nix
    ./networking.nix
    ./llm.nix
    ./tern.nix
  ];
}
