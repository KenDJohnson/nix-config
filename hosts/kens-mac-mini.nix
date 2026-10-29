{
  config,
  inputs,
  pkgs,
  ...
}: {
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
    omp.enableConfig = true;
  };
  ida.enable = true;

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
      chat_import.mode = "shadow";
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
