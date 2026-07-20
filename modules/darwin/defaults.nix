{
  pkgs,
  lib,
  config,
  machineLib,
  ...
}: let
  machine = machineLib.forConfig config;
  homeDir = config.users.users.${config.system.primaryUser}.home;
in {
  system = {
    defaults = {
      controlcenter = {
        BatteryShowPercentage = true;
      };
      dock = {
        tilesize = 24;
        mru-spaces = false;
        wvous-bl-corner = 1;
        wvous-br-corner = 1;
        wvous-tl-corner = 1;
        wvous-tr-corner = 1;
        persistent-apps =
          [
            "/Applications/Google Chrome.app"
            "${homeDir}/Applications/Home Manager Apps/Emacs.app"
            "${homeDir}/Applications/Home Manager Apps/Ghostty.app"
            "/Applications/ChatGPT.app"
            "/Applications/1Password.app"
          ]
          ++ lib.optionals (machine.hasProfile "work") [
            "/Applications/Slack.app"
            "/Applications/Tailscale.app"
          ]
          ++ [
            "${homeDir}/Applications/Home Manager Apps/imhex.app"
          ]
          ++ lib.optionals (machine.hasProfile "work") [
            "/Applications/zoom.us.app"
          ]
          ++ lib.optionals (machine.hasProfile "personal") [
            "${homeDir}/Applications/Home Manager Apps/UTM.app"
            "/System/Applications/Messages.app"
          ];
      };
      NSGlobalDomain = {
        "com.apple.swipescrolldirection" = false;
        AppleInterfaceStyle = "Dark";
        AppleShowAllExtensions = true;
        NSAutomaticQuoteSubstitutionEnabled = false;
      };
      finder = {
        AppleShowAllExtensions = true;
        AppleShowAllFiles = true;
        ShowExternalHardDrivesOnDesktop = false;
        ShowHardDrivesOnDesktop = false;
        ShowMountedServersOnDesktop = false;
        ShowPathbar = true;
        ShowRemovableMediaOnDesktop = false;
        ShowStatusBar = true;
      };
      screencapture = {
        include-date = true;
        location = "${homeDir}/Desktop/screenshots";
        target = "file";
      };
      trackpad = {
        TrackpadCornerSecondaryClick = 2;
        TrackpadPinch = true;
        TrackpadRightClick = true;
      };
    };
    keyboard = {
      enableKeyMapping = true;
      remapCapsLockToControl = true;
    };
  };
}
