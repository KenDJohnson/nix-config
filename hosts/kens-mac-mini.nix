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
      host = "kens-mbp-agentd";
      device = "kens-mbp";
      transport = "export";
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
