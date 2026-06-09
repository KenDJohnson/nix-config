{lib}: let
  enabled = attrs: name: attrs.${name} or false;
in {
  forConfig = config: let
    hasProfile = enabled config.machine.profiles;
    hasRole = enabled config.machine.roles;
    applyProfile = name: lib.mkIf (hasProfile name);
    applyRole = name: lib.mkIf (hasRole name);
  in {
    inherit hasProfile hasRole applyProfile applyRole;

    applyPersonal = applyProfile "personal";
    applyWork = applyProfile "work";
    applyDesktop = applyRole "desktop";
  };
}
