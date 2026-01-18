{ inputs }:

let
  inherit (inputs) nixpkgs nix-darwin home-manager agenix ragenix;
in
{
  # Create a nix-darwin system configuration
  mkDarwinHost = { hostConfig }:
    let
      hostModule = ../hosts/${hostConfig.hostDir}.nix;
    in
    nix-darwin.lib.darwinSystem {
      system = hostConfig.system;
      modules = [
        ../modules/darwin
        hostModule
        agenix.darwinModules.default
        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "backup";
          home-manager.users.${hostConfig.username} = {
            imports = [
              ../modules/home
              agenix.homeManagerModules.default
            ];
          };
          home-manager.extraSpecialArgs = {
            inherit inputs;
            host = hostConfig;
          };
        }
      ];
      specialArgs = {
        inherit inputs;
        host = hostConfig;
      };
    };

  # Create a standalone home-manager configuration (for Linux)
  mkHomeConfig = { hostConfig }:
    home-manager.lib.homeManagerConfiguration {
      pkgs = import nixpkgs {
        system = hostConfig.system;
      };
      modules = [
        ../modules/home
        agenix.homeManagerModules.default
      ];
      extraSpecialArgs = {
        inherit inputs;
        host = hostConfig;
      };
    };
}
