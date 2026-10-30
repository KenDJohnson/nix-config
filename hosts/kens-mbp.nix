{inputs, pkgs, ...}: {
  machine.profiles.personal = true;
  machine.profiles.work = false;
  machine.roles.desktop = true;
  determinateNix.determinateNixd.builder.memoryBytes = 17179869184;
  devTools = {
    enable = true;
    languages = {
      cpp = true;
      node = true;
      python = true;
      nix = true;
      rust = true;
      zig = true;
    };
    latex = true;
  };
  networkingTools = true;
  agents = {
    enable = true;
    omp = {
      enableConfig = true;
      # The mini's HTTPS API is reachable only within the Tailscale network.
      hindsight.apiUrl = "https://kens-mac-mini.thrush-mimosa.ts.net:8443";
    };
  };

  services.nockchain-peer = {
    enable = false;

    p2pPort = 30000;

    peers = [
      "/ip4/203.0.113.10/udp/30000/quic-v1"
    ];

    rustLog = "info,nockchain::heartbeat=warn";

    metrics = {
      enable = true;
      prometheusListenAddress = "127.0.0.1:9273";
    };

    privateGrpc = {
      listenAddress = "127.0.0.1:5555";
    };
    publicGrpc = {
      enable = false;
      listenAddress = "127.0.0.1:50051";
    };
    stateDirectory = "/Users/kjohnson/Documents/nockchain-master/.data.nockchain";
    workingDirectory = "/Users/kjohnson/Documents/nockchain-master";
    logDirectory = "/Users/kjohnson/Documents/nockchain-master/.logs.nockchain";

    # Optional overrides:
    # user = "kjohnson";
    # group = "staff";
    # stateDirectory = "/var/db/nockchain";
    # logDirectory = "/var/log/nockchain";
    # package = pkgs.nockchain;
  };

  # The laptop end of agentd's restricted ssh key (docs/setup.md §3, D-44):
  # renders agentd-export's config and adds the forced-command line for the
  # mini's key. Delete the hand-written agentd line from
  # ~/.ssh/authorized_keys when switching; it would match first.
  imports = [inputs.agentd.darwinModules.agentd-export];
  programs.agentd-export = {
    enable = true;
    user = "kjohnson";
    authorizedKeys = [
      {
        key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICWekCxtN+FJfPbbJ8+iLo5ioshMWcFl1H9+Hb9ao1bH agentd@Kens-Mac-mini";
        # Tailscale's address ranges, the same in every tailnet: the key
        # works only over Tailscale. Its private half exists only on the mini.
        from = ["100.64.0.0/10" "fd7a:115c:a1e0::/48"];
      }
    ];
    sources = {
      wisprHistory.enable = true;
      codingSessions.enable = true;
      nushell = {
        live = "/Users/kjohnson/.config/nushell/history.sqlite3";
        archive = "/Users/kjohnson/Library/Application Support/nushell/history.sqlite3";
      };
      git.roots = ["/Users/kjohnson/git"];
    };
  };
}
