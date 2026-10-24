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
  # helper) and Wispr Flow on the MBP into one event log. Setup steps (FDA
  # grant, SSH key): docs/setup.md in github.com/KenDJohnson/adhd-agent.
  services.agentd = {
    enable = true;
    user = config.system.primaryUser;
    settings.inlets.wispr_flow = {
      enabled = true;
      host = "kens-mbp";
      device = "kens-mbp";
    };
  };
}
