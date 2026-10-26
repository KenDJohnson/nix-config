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
    # Inlet modes (off/shadow/on, D-34). Scopes approved from dry runs on
    # 2026-10-26 (docs/setup.md §14); chat_import stays off.
    inlets = {
      wispr_flow = "on";
      wispr_scratchpad = "on";
      wispr_meetings = "on";
      coding_sessions_mini = "on";
      coding_sessions_mbp = "on";
      nushell_mini = "on";
      nushell_archive_mini = "on";
      nushell_mbp = "on";
      nushell_archive_mbp = "on";
      git_mini = "on";
      git_mbp = "on";
    };
    settings.inlets = {
      wispr_flow = {
        host = "kens-mbp-agentd";
        device = "kens-mbp";
        transport = "export";
      };
      # Never keep the old employer onboarding transcripts (enablement plan,
      # "Needs Ken" 1), even before they are deleted at the source.
      # max_bytes_per_day: 1 GiB instead of the 256 MiB default (X.15, D-41),
      # so the initial backfill lands in one day. Remove to go back.
      coding_sessions_mini = {
        exclude.repos = ["~/work"];
        max_bytes_per_day = 1073741824;
      };
      coding_sessions_mbp = {
        host = "kens-mbp-agentd";
        exclude = {
          paths = ["~/.claude/projects/-Users-kjohnson-work*"];
          repos = ["~/work"];
        };
        max_bytes_per_day = 1073741824;
      };
      git_mini.roots = ["/Users/kjohnson/Documents"];
    };
  };
  home-manager.users.kjohnson.programs.ssh.settings.kens-mbp-agentd = {
    HostName = "Kens-MBP";
    User = "kjohnson";
    IdentityFile = "~/.ssh/agentd_ed25519";
    IdentitiesOnly = "yes";
    IdentityAgent = "none";
  };
}
