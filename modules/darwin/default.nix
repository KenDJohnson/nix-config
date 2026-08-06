{ ... }: {
  imports = [
    ./core.nix
    ./defaults.nix
    ./build-env.nix
    ./nockchain-peer.nix
  ];
}
