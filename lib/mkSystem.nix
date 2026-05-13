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
        ../modules/machine.nix
        ../modules/darwin
        hostModule
        agenix.darwinModules.default
        inputs.determinate.darwinModules.default
        home-manager.darwinModules.home-manager
        ({ config, ... }: {
          determinateNix = {
            enable = true;
            customSettings = {
              # enable parallel evaluation
              eval-cores = 0;
              show-trace = true;
              warn-dirty = false;
              # TODO potentially enable
              # sandbox = true;
              # extra-sandbox-paths = [];
              trusted-users = [ "@admin" ];
              extra-experimental-features = [ "pipe-operators" ];
            };
            determinateNixd = {
              garbageCollector.strategy = "automatic";
              builder.state = "enabled";
            };
          };
          # Identity from hostConfig
          nixpkgs.hostPlatform = hostConfig.system;
          system.primaryUser = hostConfig.username;
          users.users.${hostConfig.username} = {
            name = hostConfig.username;
            home = hostConfig.homeDirectory;
          };
          networking.hostName = hostConfig.hostname or null;

          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "backup";
          home-manager.users.${hostConfig.username} = {
            imports = [
              ../modules/machine.nix
              ../modules/home
              agenix.homeManagerModules.default
            ];
            # Propagate machine.nix values from darwin → HM
            machineType = config.machineType;
            machineRole = config.machineRole;
            devTools = config.devTools;
            networkingTools = config.networkingTools;
            codex = config.codex;
            sshPersonalHosts = config.sshPersonalHosts;
            # Identity
            home.username = hostConfig.username;
            home.homeDirectory = hostConfig.homeDirectory;
          };
          home-manager.extraSpecialArgs = {
            inherit inputs;
          };
        })
      ];
      specialArgs = {
        inherit inputs;
      };
    };

  # Create a standalone home-manager configuration (for Linux)
  mkHomeConfig = { hostConfig }:
    home-manager.lib.homeManagerConfiguration {
      pkgs = import nixpkgs {
        system = hostConfig.system;
      };
      modules = [
        ../modules/machine.nix
        ../modules/home
        agenix.homeManagerModules.default
        {
          home.username = hostConfig.username;
          home.homeDirectory = hostConfig.homeDirectory;
        }
      ];
      extraSpecialArgs = {
        inherit inputs;
      };
    };
}
