{
  config,
  inputs,
  ...
}: let
  user = config.system.primaryUser;
  homeDirectory = config.users.users.${user}.home;
in {
  imports = [inputs.agentd.darwinModules.default];

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
  agents = {
    enable = true;
    omp = {
      enableConfig = true;
      hindsight.apiUrl = "https://kens-mac-mini.thrush-mimosa.ts.net:8443";
    };
  };
  ida.enable = true;

  # Shared memory backend for the personal Macs. After restoring its database:
  # CODEX_HOME="$HOME/.local/share/hindsight/codex" codex login
  services.hindsight = {
    enable = true;
    llmProvider = "openai-codex";
    llmModel = "gpt-6-luna";
  };

  # Share only the API over the encrypted tailnet, not the LAN or public net.
  # Foreground Serve is removed when launchd unloads this job.
  # The sandboxed macOS Tailscale app requires the user's GUI bootstrap domain.
  # HTTPS on 8443 starts at graphical login; API/PostgreSQL remain boot daemons.
  # Restart: launchctl kickstart -k "gui/$(id -u)/org.nixos.hindsight-tailnet"
  launchd.user.agents.hindsight-tailnet.serviceConfig = {
    ProgramArguments = [
      "/bin/sh"
      "-c"
      # Do not exec: the app's CLI also needs a shell parent under launchd.
      ''"$@"; result=$?; exit "$result"''
      "hindsight-tailnet"
      "/Applications/Tailscale.app/Contents/MacOS/tailscale"
      "serve"
      "--bg=false"
      "--https=8443"
      "http://127.0.0.1:${toString config.services.hindsight.apiPort}"
    ];
    LimitLoadToSessionType = "Aqua";
    WorkingDirectory = homeDirectory;
    EnvironmentVariables = {
      HOME = homeDirectory;
      # Explicit CLI mode instead of relying on terminal environment heuristics.
      TAILSCALE_BE_CLI = "true";
    };
    RunAtLoad = true;
    KeepAlive = true;
    ThrottleInterval = 30;
    Umask = 63;
    StandardOutPath = "${config.services.hindsight.logDirectory}/tailnet.log";
    StandardErrorPath = "${config.services.hindsight.logDirectory}/tailnet.error.log";
  };

  # Mac Mini: server-like behavior - prevent sleep but allow display off
  power = {
    restartAfterFreeze = true;
    restartAfterPowerFailure = true;
    sleep = {
      computer = "never";
      display = "never";
      harddisk = "never";
    };
  };
  system.defaults.CustomUserPreferences."com.apple.screensaver" = {
    idleTime = 0;
  };

  # T3 Code's user service is managed outside Nix with `t3 service install`.

  # Capture daemon: polls Apple Notes (via the agentd-snap Full Disk Access
  # helper), Wispr Flow, coding-agent sessions, Nushell history and git
  # reflogs on both Macs into one event log. Setup steps: docs/setup.md in
  # github.com/KenDJohnson/adhd-agent.
  services.agentd = {
    enable = true;
    user = config.system.primaryUser;
    # The MacBook: agentd runs ssh with these settings itself and reaches
    # agentd-export there (programs.agentd-export in hosts/kens-mbp.nix;
    # docs/setup.md §3, §21).
    hosts.mbp = {
      hostname = "Kens-MBP";
      user = "kjohnson";
      identityFile = "/Users/kjohnson/.ssh/agentd_ed25519";
    };
    # One instance per machine for each kind (D-43); modes off/shadow/on
    # (D-34). Source ids are <kind>_<instance>, so the history recorded
    # before instances continues.
    inlets = {
      wispr_scratchpad.mode = "on";
      wispr_meetings.mode = "on";
      chat_import.mode = "on";
      wispr_flow.mbp = {
        mode = "on";
        type = "ssh";
        host = "mbp";
        source = "wispr_flow"; # the id used before instances
      };
      # Never keep the old employer onboarding transcripts (enablement plan,
      # "Needs Ken" 1). max_bytes_per_day: 1 GiB instead of the 256 MiB
      # default (X.15, D-41), so a backfill lands in one day.
      coding_sessions = {
        mini = {
          mode = "on";
          type = "local";
          exclude.repos = ["~/work"];
          max_bytes_per_day = 1073741824;
        };
        mbp = {
          mode = "on";
          type = "ssh";
          host = "mbp";
          exclude = {
            paths = ["~/.claude/projects/-Users-kjohnson-work*"];
            repos = ["~/work"];
          };
          max_bytes_per_day = 1073741824;
        };
      };
      nushell = {
        mini = {
          mode = "on";
          type = "local";
        };
        archive_mini = {
          mode = "on";
          type = "local";
          db = "/Users/kjohnson/Library/Application Support/nushell/history.sqlite3";
        };
        mbp = {
          mode = "on";
          type = "ssh";
          host = "mbp";
        };
        archive_mbp = {
          mode = "on";
          type = "ssh";
          host = "mbp";
          history = "archive";
        };
      };
      git = {
        mini = {
          mode = "on";
          type = "local";
          roots = ["/Users/kjohnson/git"];
        };
        mbp = {
          mode = "on";
          type = "ssh";
          host = "mbp";
        };
      };
    };
  };
}
