{ pkgs, lib, config, inputs, ... }: {
  environment.shells = builtins.attrValues {
    inherit (pkgs) bash zsh nushell;
  };

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
