{...}: {
  machine.profiles.personal = true;
  machine.roles.desktop = true;
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

  users = {
    knownGroups = ["nock"];
    groups.nock = {
      gid = 499;
      description = "Nockchain service";
    };

    knownUsers = ["nock"];
    users.nock = {
      uid = 499;
      gid = 499;
      description = "Nockchain service";
      home = "/var/db/nockchain";
      createHome = false;
      isHidden = true;

      # nix-darwin defaults new managed users to /usr/bin/false.
      # No password or interactive login is configured.
    };
  };

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

    publicGrpc = {
      enable = false;
      listenAddress = "127.0.0.1:5555";
    };
    user = "nock";
    group = "nock";

    # Optional overrides:
    # user = "kjohnson";
    # group = "staff";
    # stateDirectory = "/var/db/nockchain";
    # logDirectory = "/var/log/nockchain";
    # package = pkgs.nockchain;
  };

  # Mac Mini: server-like behavior - prevent sleep but allow display off
  power = {
    restartAfterFreeze = true;
    restartAfterPowerFailure = true;
    sleep = {
      computer = "never";
      display = 15;
      harddisk = "never";
    };
  };
}
