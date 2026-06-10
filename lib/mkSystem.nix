{inputs}: let
  inherit (inputs) nixpkgs nix-darwin home-manager agenix ragenix;
  machineLib = import ./machineLib.nix {lib = nixpkgs.lib;};
  overlays = [
    (final: prev: {
      # dix 2.0.0 fails package tests on Darwin under /private/tmp.
      # Drop this once nixpkgs-unstable includes NixOS/nixpkgs#528621.
      dix = prev.dix.overrideAttrs (old: let
        version = "2.0.1";
        src = final.fetchFromGitHub {
          owner = "manic-systems";
          repo = "dix";
          tag = "v${version}";
          hash = "sha256-KTlFgBEVKJIXymfN2UU8hvGM71PYRcNgJ1XWUmG2AI4=";
        };
      in {
        inherit version src;
        cargoDeps = final.rustPlatform.fetchCargoVendor {
          pname = "dix";
          inherit version src;
          hash = "sha256-pNkSdsxOpv0E/xXs7tMg2vtP0PBU7p8fh3H4IX/u5k4=";
        };
        env = builtins.removeAttrs (old.env or {}) ["TMPDIR"];
        checkFlags = [];
      });
    })
  ];
in {
  # Create a nix-darwin system configuration
  mkDarwinHost = {hostConfig}: let
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
        ({config, ...}: {
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
              trusted-users = ["@admin"];
              extra-experimental-features = ["pipe-operators"];
            };
            determinateNixd = {
              garbageCollector.strategy = "automatic";
              builder.state = "enabled";
            };
          };
          # Identity from hostConfig
          nixpkgs.hostPlatform = hostConfig.system;
          nixpkgs.overlays = overlays;
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
            machine = config.machine;
            devTools = config.devTools;
            networkingTools = config.networkingTools;
            codex = config.codex;
            tmux = config.tmux;
            zed = config.zed;
            sshPersonalHosts = config.sshPersonalHosts;
            # Identity
            home.username = hostConfig.username;
            home.homeDirectory = hostConfig.homeDirectory;
          };
          home-manager.extraSpecialArgs = {
            inherit inputs machineLib;
          };
        })
      ];
      specialArgs = {
        inherit inputs machineLib;
      };
    };

  # Create a standalone home-manager configuration (for Linux)
  mkHomeConfig = {hostConfig}: let
    hostModule = ../hosts/${hostConfig.hostDir}.nix;
  in
    home-manager.lib.homeManagerConfiguration {
      pkgs = import nixpkgs {
        system = hostConfig.system;
        inherit overlays;
      };
      modules = [
        ../modules/machine.nix
        hostModule
        ../modules/home
        agenix.homeManagerModules.default
        {
          home.username = hostConfig.username;
          home.homeDirectory = hostConfig.homeDirectory;
        }
      ];
      extraSpecialArgs = {
        inherit inputs machineLib;
      };
    };
}
