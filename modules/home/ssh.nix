{ config, lib, pkgs, ... }:
let
  in-home = path: "${config.home.homeDirectory}/${path}";
  ssh-host = { HostName, ... }@args: {
    HostName = HostName;
    User = "root";
    IdentityFile = (in-home ".ssh/id_rsa");
    Compression = true;
    AddKeysToAgent = "yes";
    ForwardAgent = false;
    ServerAliveInterval = 0;
    ServerAliveCountMax = 3;
    UserKnownHostsFile = in-home ".ssh/known_hosts";
    ControlMaster = "no";
    ControlPath = in-home ".ssh/master-%r@%n:%p";
    ControlPersist = "no";
    Port = 22;
  } // args;
in
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    includes = [
      "~/.ssh/config.d/secret-hosts"
    ];
    settings = {
      github = (ssh-host {
        HostName = "github.com";
        User = "git";
        IdentityFile = (in-home ".ssh/id_ed25519");
        ServerAliveInterval = 30;
        ServerAliveCountMax = 20;
      });
               # // { UseKeychain = "yes"; };
    } // lib.optionalAttrs config.sshPersonalHosts {
      udm = (ssh-host { HostName = "unifi"; });
      robit = (ssh-host { HostName = "robit"; });
      pve = (ssh-host { HostName = "pve"; });
      homeassistant = (ssh-host { HostName = "homeassistant.local"; });
      ha-root = (ssh-host { HostName = "homeassistant.local"; Port = 22222; });
    };
  };
}
