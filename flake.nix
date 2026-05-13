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
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/3";

    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    agenix.inputs.darwin.follows = "nix-darwin";
    agenix.inputs.home-manager.follows = "home-manager";

    ragenix.url = "github:yaxitech/ragenix";
    ragenix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, home-manager, agenix, ragenix, ... }:
  let
    lib = import ./lib/mkSystem.nix { inherit inputs; };

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

    darwinHosts = nixpkgs.lib.filterAttrs
      (name: cfg: cfg.platform == "darwin")
      hosts;
  in {
    darwinConfigurations = builtins.mapAttrs
      (name: hostConfig: lib.mkDarwinHost { inherit hostConfig; })
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
