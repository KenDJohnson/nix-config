{ pkgs, lib, config, inputs, host, ... }: {
  environment = {
    shells = builtins.attrValues {
      inherit (pkgs) bash zsh nushell;
    };
    systemPackages = [
      pkgs.vim
      pkgs.libiconv
      pkgs.openssl
      pkgs.pkg-config
    ];
    variables = {
      LIBRARY_PATH = "${pkgs.libiconv.out}/lib";
      C_INCLUDE_PATH = "${pkgs.libiconv.out}/include";
      OPENSSL_DIR = "${pkgs.openssl.out}";
      OPENSSL_LIB_DIR = "${pkgs.openssl.out}/lib";
      OPENSSL_INCLUDE_DIR = "${pkgs.openssl.dev}/include";
      PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig";
      CONFIG_ATTRS = "${toString (builtins.attrNames config)}";
    };
  };

  nix.enable = false;
  nixpkgs.hostPlatform = host.system;
  nixpkgs.config.allowUnfree = true;

  users.users.${host.username} = {
    name = host.username;
    home = host.homeDirectory;
  };

  security.pam.services.sudo_local = {
    enable = true;
    touchIdAuth = true;
    watchIdAuth = true;
  };

  system = {
    configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;
    # Used for backwards compatibility, please read the changelog before changing.
    # $ darwin-rebuild changelog
    stateVersion = 6;
    primaryUser = host.username;
    defaults = {
      dock = {
        tilesize = 24;
        mru-spaces = false;
        wvous-bl-corner = 1;
        wvous-br-corner = 1;
        wvous-tl-corner = 1;
        wvous-tr-corner = 1;
        persistent-apps = [
          "/Applications/Google Chrome.app"
          "${host.homeDirectory}/Applications/Home Manager Apps/Emacs.app"
          "${host.homeDirectory}/Applications/Home Manager Apps/Zed.app"
          "${host.homeDirectory}/Applications/Home Manager Apps/Ghostty.app"
        ] ++ lib.optionals (host.systemType == "work") [
          "/Applications/Slack.app"
        ] ++ [
          "${host.homeDirectory}/Applications/Home Manager Apps/imhex.app"
        ] ++ lib.optionals (host.systemType == "work") [
          "/Applications/zoom.us.app"
        ] ++ lib.optionals (host.systemType == "personal") [
          "${host.homeDirectory}/Applications/Home Manager Apps/UTM.app"
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
