{ pkgs, lib, config, ... }: {
  system = {
    defaults = {
      dock = let
        homeDir = config.users.users.${config.system.primaryUser}.home;
      in {
        tilesize = 24;
        mru-spaces = false;
        wvous-bl-corner = 1;
        wvous-br-corner = 1;
        wvous-tl-corner = 1;
        wvous-tr-corner = 1;
        persistent-apps = [
          "/Applications/Google Chrome.app"
          "${homeDir}/Applications/Home Manager Apps/Emacs.app"
          "${homeDir}/Applications/Home Manager Apps/Zed.app"
          "${homeDir}/Applications/Home Manager Apps/Ghostty.app"
        ] ++ lib.optionals (config.machineType == "work") [
          "/Applications/Slack.app"
        ] ++ [
          "${homeDir}/Applications/Home Manager Apps/imhex.app"
        ] ++ lib.optionals (config.machineType == "work") [
          "/Applications/zoom.us.app"
        ] ++ lib.optionals (config.machineType == "personal") [
          "${homeDir}/Applications/Home Manager Apps/UTM.app"
          "/System/Applications/Messages.app"
        ];
      };
      NSGlobalDomain = {
        "com.apple.swipescrolldirection" = false;
        AppleInterfaceStyle = "Dark";
        AppleShowAllExtensions = true;
      };
      finder = {
        AppleShowAllExtensions = true;
        ShowPathbar = true;
      };
      screencapture.location = "~/Desktop/screenshots";
    };
    keyboard = {
      enableKeyMapping = true;
      remapCapsLockToControl = true;
    };
  };
}
