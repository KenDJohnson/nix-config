{ config, lib, pkgs, ... }:
let
  in-home = path: "${config.home.homeDirectory}/${path}";
  ssh-host = { hostname, user ? "root", port ? 22, key ? (in-home ".ssh/id_rsa") }: {
    hostname = hostname;
    user = user;
    identityFile = key;
    compression = true;
    addKeysToAgent = "yes";
    forwardAgent = false;
    serverAliveInterval = 0;
    serverAliveCountMax = 3;
    userKnownHostsFile = in-home ".ssh/known_hosts";
    controlMaster = "no";
    controlPath = in-home ".ssh/master-%r@%n:%p";
    controlPersist = "no";
    port = port;
  };
in
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    includes = [
      "~/.ssh/config.d/secret-hosts"
    ];
    matchBlocks = {
      github = (ssh-host { hostname = "github.com"; user = "git"; key = (in-home ".ssh/id_ed25519"); });
               # // { extraOptions = { UseKeychain = "yes"; }; };
    } // lib.optionalAttrs config.sshPersonalHosts {
      udm = (ssh-host { hostname = "unifi"; });
      robit = (ssh-host { hostname = "robit"; });
      pve = (ssh-host { hostname = "pve"; });
      homeassistant = (ssh-host { hostname = "homeassistant.local"; });
      ha-root = (ssh-host { hostname = "homeassistant.local"; port = 22222; });
    };
  };
}
