{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.nockchain-peer;

  arguments =
    [
      "--data-dir=${cfg.stateDirectory}/data"
      "--identity-path=${cfg.stateDirectory}/identity"
      "--bind=/ip4/0.0.0.0/udp/${toString cfg.p2pPort}/quic-v1"
      "--color=never"
    ]
    ++ lib.optionals cfg.publicGrpc.enable [
      "--bind-public-grpc-addr=${cfg.publicGrpc.listenAddress}"
    ]
    ++ lib.concatMap (peer: [
      "--peer"
      peer
    ])
    cfg.peers;

  environment =
    {
      HOME = cfg.stateDirectory;
      RUST_BACKTRACE = "1";
      RUST_LOG = cfg.rustLog;
      DD_ENV = "production";
      DD_SERVICE = "nockchain-peer";
      DD_VERSION = cfg.package.version;
    }
    // lib.optionalAttrs cfg.metrics.enable {
      STATSD_HOST = "127.0.0.1";
      STATSD_PORT = "8125";
    };

  telegrafConfig = (pkgs.formats.toml {}).generate "nockchain-telegraf.conf" {
    global_tags.service = "nockchain-peer";
    agent = {
      interval = "10s";
      flush_interval = "10s";
      omit_hostname = false;
    };
    inputs.statsd = [
      {
        service_address = "udp://127.0.0.1:8125";
        datadog_extensions = true;
        delete_counters = true;
        delete_gauges = false;
        delete_sets = true;
        delete_timings = true;
      }
    ];
    outputs.prometheus_client = [
      {
        listen = cfg.metrics.prometheusListenAddress;
        path = "/metrics";
        metric_version = 2;
      }
    ];
  };
in {
  options.services.nockchain-peer = {
    enable = lib.mkEnableOption "the Nockchain non-mining mainnet peer";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.nockchain;
      defaultText = lib.literalExpression "pkgs.nockchain";
      description = "Pinned Nockchain package to execute.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = config.system.primaryUser;
      defaultText = lib.literalExpression "config.system.primaryUser";
      description = "Existing macOS user that runs the peer.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "staff";
      description = "Existing macOS group that runs the peer.";
    };

    stateDirectory = lib.mkOption {
      type = lib.types.str;
      default = "/var/db/nockchain";
      description = "Persistent state directory for peer data and identity.";
    };

    logDirectory = lib.mkOption {
      type = lib.types.str;
      default = "/var/log/nockchain";
      description = "Directory for launchd-managed peer logs.";
    };

    p2pPort = lib.mkOption {
      type = lib.types.port;
      default = 30000;
      description = "Public UDP port used for libp2p QUIC traffic.";
    };

    peers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Additional initial peer multiaddresses. Default mainnet peers remain enabled.";
    };

    rustLog = lib.mkOption {
      type = lib.types.str;
      default = "info,nockchain::heartbeat=warn";
      description = "RUST_LOG filter for the peer process.";
    };

    metrics = {
      enable =
        lib.mkEnableOption "the local DogStatsD receiver and Prometheus exporter"
        // {
          default = true;
        };

      prometheusListenAddress = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1:9273";
        description = "Loopback address on which Telegraf exports translated metrics.";
      };
    };

    privageGrpc = {
      listenAddress = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1:5555";
        description = "Private gRPC listen address. Keep this on loopback unless a trusted control plane protects it.";
      };
    };

    publicGrpc = {
      enable = lib.mkEnableOption "the unauthenticated public gRPC API on loopback";

      listenAddress = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1:50051";
        description = "gRPC listen address. Keep this on loopback unless a trusted control plane protects it.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !cfg.publicGrpc.enable || lib.hasPrefix "127.0.0.1:" cfg.publicGrpc.listenAddress;
        message = "services.nockchain-peer.publicGrpc.listenAddress must remain on loopback";
      }
      {
        assertion = !cfg.metrics.enable || lib.hasPrefix "127.0.0.1:" cfg.metrics.prometheusListenAddress;
        message = "services.nockchain-peer.metrics.prometheusListenAddress must remain on loopback";
      }
    ];

    environment.systemPackages = [
      cfg.package
      pkgs.grpcurl
    ];
    system.activationScripts.users.text = lib.mkAfter ''
      ${pkgs.coreutils}/bin/install -d -m 0700 -o ${lib.escapeShellArg cfg.user} -g ${lib.escapeShellArg cfg.group} ${lib.escapeShellArg cfg.stateDirectory}
      ${pkgs.coreutils}/bin/install -d -m 0750 -o ${lib.escapeShellArg cfg.user} -g ${lib.escapeShellArg cfg.group} ${lib.escapeShellArg cfg.logDirectory}
    '';

    launchd.daemons.nockchain = {
      serviceConfig = {
        ProgramArguments = [(lib.getExe cfg.package)] ++ arguments;
        UserName = cfg.user;
        GroupName = cfg.group;
        WorkingDirectory = cfg.stateDirectory;
        EnvironmentVariables = environment;
        RunAtLoad = true;
        KeepAlive.SuccessfulExit = false;
        ThrottleInterval = 10;
        ExitTimeOut = 600;
        Umask = 23; # umask 027 = rw-r-----
        SoftResourceLimits.NumberOfFiles = 65536;
        HardResourceLimits.NumberOfFiles = 65536;
        StandardOutPath = "${cfg.logDirectory}/nockchain.log";
        StandardErrorPath = "${cfg.logDirectory}/nockchain.error.log";
      };
    };

    launchd.daemons.nockchain-telegraf = lib.mkIf cfg.metrics.enable {
      serviceConfig = {
        ProgramArguments = [
          (lib.getExe pkgs.telegraf)
          "--config"
          "${telegrafConfig}"
        ];
        UserName = cfg.user;
        GroupName = cfg.group;
        WorkingDirectory = cfg.stateDirectory;
        RunAtLoad = true;
        KeepAlive.SuccessfulExit = false;
        ThrottleInterval = 10;
        Umask = 63;
        StandardOutPath = "${cfg.logDirectory}/telegraf.log";
        StandardErrorPath = "${cfg.logDirectory}/telegraf.error.log";
      };
    };
  };
}
