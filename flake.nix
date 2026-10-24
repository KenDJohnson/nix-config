{
  description = "Ken nix-darwin system flake";

  # nixConfig = {
  #   experimental-features = [
  #     "nix-command"
  #     "flakes"
  #     "pipe-operators"
  #   ];
  # };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    # Locked Python wheels for the native Hindsight API.
    pyproject-nix.url = "github:pyproject-nix/pyproject.nix";
    pyproject-nix.inputs.nixpkgs.follows = "nixpkgs";
    uv2nix.url = "github:pyproject-nix/uv2nix";
    uv2nix.inputs.nixpkgs.follows = "nixpkgs";
    uv2nix.inputs.pyproject-nix.follows = "pyproject-nix";
    pyproject-build-systems.url = "github:pyproject-nix/build-system-pkgs";
    pyproject-build-systems.inputs.nixpkgs.follows = "nixpkgs";
    pyproject-build-systems.inputs.pyproject-nix.follows = "pyproject-nix";
    pyproject-build-systems.inputs.uv2nix.follows = "uv2nix";
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/3";

    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Ragenix disables nixpkgs aliases, but its old overlay uses stdenv.isLinux.
    # Manage the overlay here so --update refreshes it alongside nixpkgs.
    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";

    nockchain-src = {
      url = "github:zorp-corp/nockchain/86a4a5bbd9b7dd27fecd1fa1c9c94b85277d6123";
      flake = false;
    };

    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";

    ragenix.url = "github:yaxitech/ragenix";
    ragenix.inputs.nixpkgs.follows = "nixpkgs";
    ragenix.inputs.rust-overlay.follows = "rust-overlay";

    gws.url = "github:googleworkspace/cli";
    gws.inputs.nixpkgs.follows = "nixpkgs";

    omp.url = "github:can1357/oh-my-pi/main";
    omp.inputs.nixpkgs.follows = "nixpkgs";
    omp.inputs.rust-overlay.follows = "rust-overlay";

    herdr.url = "github:herdrdev/herdr/v0.8.2";

    # agentd: personal capture and recall daemon (private repo, fetched with
    # the GitHub SSH key). No nixpkgs follows on purpose: agentd-snap's Full
    # Disk Access grant is tied to its exact bytes, so it should only change
    # when agentd itself changes. See docs/decisions.md D-22 in that repo.
    agentd.url = "git+ssh://git@github.com/KenDJohnson/adhd-agent.git";
  };

  outputs = inputs @ {
    self,
    nix-darwin,
    nixpkgs,
    home-manager,
    agenix,
    ragenix,
    gws,
    ...
  }: let
    lib = import ./lib/mkSystem.nix {inherit inputs;};

    hosts = {
      "Kens-Mac-mini" = {
        hostDir = "kens-mac-mini";
        system = "aarch64-darwin";
        platform = "darwin";
        username = "kjohnson";
        homeDirectory = "/Users/kjohnson";
      };
      "Kens-MBP" = {
        hostDir = "kens-mbp";
        system = "aarch64-darwin";
        platform = "darwin";
        username = "kjohnson";
        homeDirectory = "/Users/kjohnson";
      };
      # OCX laptop
      "Kens-MacBook-Pro" = {
        hostDir = "ocx-mbp";
        system = "aarch64-darwin";
        platform = "darwin";
        username = "ken";
        homeDirectory = "/Users/ken";
      };
    };

    darwinHosts =
      nixpkgs.lib.filterAttrs
      (name: cfg: cfg.platform == "darwin")
      hosts;
  in {
    darwinConfigurations =
      builtins.mapAttrs
      (name: hostConfig: lib.mkDarwinHost {inherit hostConfig;})
      darwinHosts;

    # Standalone home-manager configurations for Linux
    homeConfigurations = {
      # Uncomment and configure when ready:
      # "dev-vm" = lib.mkHomeConfig {
      #   hostConfig = {
      #     hostDir = "linux-vm";
      #     system = "x86_64-linux";
      #     platform = "linux";
      #     username = "kjohnson";
      #     homeDirectory = "/home/kjohnson";
      #   };
      # };
    };
  };
}
