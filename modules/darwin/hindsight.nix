{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.hindsight;
  homeDirectory = config.users.users.${cfg.user}.home;
  databaseURL = "postgresql://${lib.escapeURL cfg.user}@/hindsight?host=${lib.escapeURL cfg.databaseDirectory}";
  llmEnvironment = lib.filterAttrs (_: value: value != null) {
    HINDSIGHT_API_LLM_PROVIDER = cfg.llmProvider;
    HINDSIGHT_API_LLM_MODEL = cfg.llmModel;
  };

  postgresqlStart = pkgs.writeShellApplication {
    name = "hindsight-postgresql";
    runtimeInputs = [cfg.databasePackage pkgs.coreutils];
    text = ''
      umask 077
      data=$1
      socket="$data/.bootstrap"
      export PGUSER=${lib.escapeShellArg cfg.user}

      if [ ! -f "$data/PG_VERSION" ]; then
        initdb -D "$data" --username "$PGUSER" \
          --auth-local=peer --auth-host=scram-sha-256 --encoding=UTF8 --no-locale
      fi

      # Bootstrap on a separate private socket: the API cannot connect until
      # its database and extensions exist and the final server is running.
      mkdir -p "$socket"
      pg_ctl -D "$data" -l "$data/bootstrap.log" -w \
        -o "-h ''' -k ''${socket@Q}" start
      trap 'pg_ctl -D "$data" -m fast -w stop' EXIT
      trap 'exit 0' INT TERM
      export PGHOST="$socket"
      database_exists=$(psql -d postgres -At \
        --command "SELECT 1 FROM pg_database WHERE datname = 'hindsight'")
      if [ "$database_exists" != 1 ]; then
        createdb hindsight
      fi
      psql -d hindsight --set ON_ERROR_STOP=1 \
        --command 'CREATE EXTENSION IF NOT EXISTS vector; CREATE EXTENSION IF NOT EXISTS pg_trgm;'
      pg_ctl -D "$data" -m fast -w stop
      trap - EXIT

      # launchd sends SIGTERM; PostgreSQL needs SIGINT for fast shutdown,
      # otherwise its smart shutdown waits indefinitely for API connections.
      postgres -D "$data" -h "" -k "$data" &
      postgres_pid=$!
      trap 'kill -INT "$postgres_pid"; wait "$postgres_pid"; exit 0' INT TERM
      wait "$postgres_pid"
    '';
  };

  loadEnvironment = ''
    umask 077
    hindsight_env=${lib.escapeShellArg cfg.environmentFile}
    hindsight_env="''${HINDSIGHT_ENV_FILE:-$hindsight_env}"
    if [ -f "$hindsight_env" ]; then
      set -a
      . "$hindsight_env"
      set +a
    fi
    unset hindsight_env
  '';

  loadApiEnvironment =
    loadEnvironment
    + lib.concatStrings (lib.mapAttrsToList
      (name: value: "export ${name}=${lib.escapeShellArg value}\n")
      llmEnvironment);

  package = pkgs.symlinkJoin {
    name = "hindsight-configured-${cfg.package.version}";
    paths = [cfg.package cfg.controlPlanePackage];
    nativeBuildInputs = [pkgs.makeWrapper];
    postBuild = ''
      for command in hindsight-api hindsight-admin hindsight-local-mcp hindsight-worker; do
        wrapProgram "$out/bin/$command" \
          --run ${lib.escapeShellArg loadApiEnvironment} \
          --set-default HINDSIGHT_API_HOST 127.0.0.1 \
          --set-default HINDSIGHT_API_PORT ${toString cfg.apiPort} \
          --set-default HINDSIGHT_API_DATABASE_URL ${lib.escapeShellArg databaseURL} \
          --set-default HINDSIGHT_API_LLM_CODEX_HOME ${lib.escapeShellArg cfg.codexHome}
      done
      wrapProgram "$out/bin/hindsight-control-plane" \
        --run ${lib.escapeShellArg loadEnvironment} \
        --set-default PORT ${toString cfg.controlPlanePort} \
        --set-default HINDSIGHT_CP_DATAPLANE_API_URL http://127.0.0.1:${toString cfg.apiPort} \
        --add-flags '--hostname 127.0.0.1'
    '';
    meta.mainProgram = "hindsight-api";
  };

  # launchd loads these jobs before Determinate mounts /nix. Use the same
  # native-shell boot guard as nix-darwin's activate-system daemon.
  waitForNixStore = arguments:
    [
      "/bin/sh"
      "-c"
      ''/bin/wait4path /nix/store && exec "$@"''
      "hindsight"
    ]
    ++ arguments;

  serviceConfig = {
    UserName = cfg.user;
    GroupName = "staff";
    WorkingDirectory = homeDirectory;
    EnvironmentVariables =
      {
        HOME = homeDirectory;
        HINDSIGHT_API_DATABASE_URL = databaseURL;
        HINDSIGHT_API_LLM_CODEX_HOME = cfg.codexHome;
      }
      // llmEnvironment;
    RunAtLoad = true;
    KeepAlive = true;
    ThrottleInterval = 30;
    ExitTimeOut = 120;
    Umask = 63; # 077: runtime files are owner-only, including refreshed OAuth tokens.
  };
in {
  options.services.hindsight = {
    enable = lib.mkEnableOption "the native Hindsight API and control plane launchd services";

    llmProvider = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "openai-codex";
      description = ''
        Non-secret LLM provider name. When set, this Nix value takes precedence
        over the runtime environment file and inherited environment variables.
        Null leaves the upstream/runtime provider selection unchanged.
      '';
    };

    llmModel = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "gpt-5.4-mini";
      description = ''
        Non-secret LLM model name. When set, this Nix value takes precedence
        over the runtime environment file and inherited environment variables.
        Null leaves the upstream/runtime model selection unchanged.
      '';
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = config.system.primaryUser;
      defaultText = lib.literalExpression "config.system.primaryUser";
      description = "Existing macOS user that runs Hindsight and owns its data and OAuth credentials.";
    };

    apiPort = lib.mkOption {
      type = lib.types.port;
      default = 8888;
      description = "Loopback port for the Hindsight API.";
    };

    controlPlanePort = lib.mkOption {
      type = lib.types.port;
      default = 9999;
      description = "Loopback port for the Hindsight web UI.";
    };

    codexHome = lib.mkOption {
      type = lib.types.str;
      default = "${homeDirectory}/.local/share/hindsight/codex";
      description = ''
        Dedicated writable Codex OAuth home for Hindsight. Authenticate once as
        the service user with CODEX_HOME pointing here when running codex login.
        Hindsight reads and atomically refreshes auth.json in this directory.
        Do not share or copy rotating refresh tokens from an interactive Codex
        session. No credential contents are included in the Nix store.
      '';
    };

    logDirectory = lib.mkOption {
      type = lib.types.str;
      default = "${homeDirectory}/Library/Logs/hindsight";
      description = "Owner-only directory containing API and control-plane launchd logs.";
    };

    databasePackage = lib.mkOption {
      type = lib.types.package;
      default = pkgs.postgresql_18.withPackages (ps: [ps.pgvector]);
      defaultText = lib.literalExpression "pkgs.postgresql_18.withPackages (ps: [ps.pgvector])";
      description = "Native PostgreSQL package with pgvector; major-version upgrades require a database migration.";
    };

    databaseDirectory = lib.mkOption {
      type = lib.types.str;
      default = "${homeDirectory}/.local/share/hindsight/postgresql-${cfg.databasePackage.psqlSchema}";
      description = "Owner-only persistent PostgreSQL cluster and Unix socket directory. PostgreSQL does not listen on TCP.";
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.hindsight;
      defaultText = lib.literalExpression "pkgs.hindsight";
      description = "Pinned full Hindsight API package, including local embeddings and reranking.";
    };

    controlPlanePackage = lib.mkOption {
      type = lib.types.package;
      default = pkgs.hindsight-control-plane;
      defaultText = lib.literalExpression "pkgs.hindsight-control-plane";
      description = "Pinned standalone Hindsight web UI package.";
    };

    environmentFile = lib.mkOption {
      type = lib.types.str;
      default = "${homeDirectory}/.config/hindsight/environment";
      defaultText = "The service user's ~/.config/hindsight/environment";
      description = ''
        Optional runtime file containing secrets or additional shell assignments,
        loaded by the Hindsight commands.
        This is a string path, not a Nix file input: its contents never
        enter the Nix store. Override it per invocation with HINDSIGHT_ENV_FILE.
        Keep the file owner-readable only; use ragenix for any credentials stored
        in this repository.

        Configure the non-secret provider and model through llmProvider and
        llmModel. Explicit Nix values override this file. For a ChatGPT
        subscription, openai-codex is supported without an API key, so no runtime
        environment file is needed. Complete a fresh codex login in
        services.hindsight.codexHome before starting the service; launchd supplies
        the dedicated credentials path and the service user's HOME.

        The API, UI, and PostgreSQL run as org.nixos.hindsight-api,
        org.nixos.hindsight-control-plane, and org.nixos.hindsight-postgresql
        launchd daemons. The API and UI bind only to loopback; the database uses
        a private Unix socket with peer authentication. Configure API/UI ports
        through services.hindsight. After changing this
        file, restart the jobs with sudo launchctl kickstart -k system/<label>.
        The installed hindsight-api and hindsight-control-plane commands can
        also run manually; stop the daemons first to avoid port conflicts.

        At boot, each daemon starts through macOS /bin/sh and waits for
        /nix/store, avoiding a race with the Nix volume mount. The native
        launcher remains runnable before Nix is mounted.

        PostgreSQL data persists in services.hindsight.databaseDirectory; local
        models download from Hugging Face on first use. The pg0 database bundled
        upstream is not used: its Darwin binaries depend on Homebrew libraries.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.apiPort != cfg.controlPlanePort;
        message = "services.hindsight API and control-plane ports must be distinct";
      }
    ];

    environment.systemPackages = [package];

    system.activationScripts.hindsight.text = ''
      ${pkgs.coreutils}/bin/install -d -m 0700 -o ${lib.escapeShellArg cfg.user} -g staff ${lib.escapeShellArg "${homeDirectory}/.config/hindsight"}
      ${pkgs.coreutils}/bin/install -d -m 0700 -o ${lib.escapeShellArg cfg.user} -g staff ${lib.escapeShellArg cfg.codexHome}
      ${pkgs.coreutils}/bin/install -d -m 0700 -o ${lib.escapeShellArg cfg.user} -g staff ${lib.escapeShellArg cfg.logDirectory}
      ${pkgs.coreutils}/bin/install -d -m 0700 -o ${lib.escapeShellArg cfg.user} -g staff ${lib.escapeShellArg cfg.databaseDirectory}
    '';

    launchd.daemons.hindsight-postgresql.serviceConfig =
      serviceConfig
      // {
        EnvironmentVariables = {HOME = homeDirectory;};
        ProgramArguments = waitForNixStore [(lib.getExe postgresqlStart) cfg.databaseDirectory];
        StandardOutPath = "${cfg.logDirectory}/postgresql.log";
        StandardErrorPath = "${cfg.logDirectory}/postgresql.error.log";
      };

    launchd.daemons.hindsight-api.serviceConfig =
      serviceConfig
      // {
        ProgramArguments = waitForNixStore [
          "${package}/bin/hindsight-api"
          "--host"
          "127.0.0.1"
          "--port"
          (toString cfg.apiPort)
        ];
        StandardOutPath = "${cfg.logDirectory}/api.log";
        StandardErrorPath = "${cfg.logDirectory}/api.error.log";
      };

    launchd.daemons.hindsight-control-plane.serviceConfig =
      serviceConfig
      // {
        ProgramArguments = waitForNixStore [
          "${package}/bin/hindsight-control-plane"
          "--port"
          (toString cfg.controlPlanePort)
          "--api-url"
          "http://127.0.0.1:${toString cfg.apiPort}"
        ];
        StandardOutPath = "${cfg.logDirectory}/control-plane.log";
        StandardErrorPath = "${cfg.logDirectory}/control-plane.error.log";
      };
  };
}
