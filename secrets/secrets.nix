let
  rootRules = import ../secrets.nix;
  prefix = "secrets/";
  prefixLength = builtins.stringLength prefix;
  hasPrefix = value: builtins.substring 0 prefixLength value == prefix;
  stripPrefix = value: builtins.substring prefixLength (builtins.stringLength value - prefixLength) value;
  names = builtins.filter hasPrefix (builtins.attrNames rootRules);
in
  builtins.listToAttrs (map (name: {
      name = stripPrefix name;
      value = rootRules.${name};
    })
    names)
