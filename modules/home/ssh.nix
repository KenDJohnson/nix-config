{ config, lib, pkgs, ... }:
let
  in-home = path: "${config.home.homeDirectory}/${path}";
  ssh-host = { hostname, user ? "root", port ? 22, key ? (in-home ".ssh/id_rsa") }: {
    HostName = hostname;
    User = user;
    IdentityFile = key;
    Compression = true;
    AddKeysToAgent = "yes";
    ForwardAgent = false;
    ServerAliveInterval = 0;
    ServerAliveCountMax = 3;
    UserKnownHostsFile = in-home ".ssh/known_hosts";
    ControlMaster = "no";
    ControlPath = in-home ".ssh/master-%r@%n:%p";
    ControlPersist = "no";
    Port = port;
  };
in
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    includes = [
      "~/.ssh/config.d/secret-hosts"
    ];
    settings = {
      github = (ssh-host { hostname = "github.com"; user = "git"; key = (in-home ".ssh/id_ed25519"); });
               # // { UseKeychain = "yes"; };
    } // lib.optionalAttrs config.sshPersonalHosts {
      udm = (ssh-host { hostname = "unifi"; });
      robit = (ssh-host { hostname = "robit"; });
      pve = (ssh-host { hostname = "pve"; });
      homeassistant = (ssh-host { hostname = "homeassistant.local"; });
      ha-root = (ssh-host { hostname = "homeassistant.local"; port = 22222; });
    };
  };
}
