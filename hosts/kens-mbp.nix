{...}: {
  machine.profiles.personal = true;
  machine.profiles.work = true;
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

  services.nockchain-peer = {
    enable = true;

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
}
