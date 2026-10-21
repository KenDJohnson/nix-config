{
  pkgs,
  lib,
  config,
  inputs,
  ...
}: let
  primaryUser = config.system.primaryUser;
  homeConfig = config.home-manager.users.${primaryUser};
  loginShell = homeConfig.home.sessionVariables.SHELL or (lib.getExe homeConfig.programs.nushell.package);
  userRecord = lib.escapeShellArg "/Users/${primaryUser}";
in {
  environment.shells =
    (builtins.attrValues {
      inherit (pkgs) bash zsh nushell;
    })
    ++ [loginShell];
  users.users.${primaryUser}.shell = loginShell;

  # nix-darwin only updates UserShell itself for users.knownUsers. Keep the
  # existing macOS admin account outside that list and manage just its shell.
  system.activationScripts.postActivation.text = lib.mkAfter ''
    if [ "$(/usr/bin/dscl . -read ${userRecord} UserShell)" != ${lib.escapeShellArg "UserShell: ${loginShell}"} ]; then
      echo "setting the login shell for ${primaryUser}..." >&2
      /usr/bin/dscl . -create ${userRecord} UserShell ${lib.escapeShellArg loginShell}
    fi
  '';

  nix.enable = false;
  nixpkgs.config.allowUnfree = true;

  security.pam.services.sudo_local = {
    enable = true;
    touchIdAuth = true;
    watchIdAuth = true;
  };

  system = {
    configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;
    stateVersion = 6;
  };
}
