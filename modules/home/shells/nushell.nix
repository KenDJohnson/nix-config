{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}: let
  inherit (lib) attrNames attrValues concatLines filterAttrs flatten listToAttrs mapAttrs mapAttrsToList replaceStrings;
  toNu = lib.hm.nushell.toNushell {};

  baseNushellEnv = {
    SHELL = lib.getExe pkgs.nushell;
  };
  variableValues = config.home.sessionVariables // baseNushellEnv // {
    HOME = config.home.homeDirectory;
    USER = config.home.username;
  };
  variablesMap = listToAttrs (flatten (mapAttrsToList (name: value: [ { name = "\$${name}"; value = toString value; } { name = "\${${name}}"; value = toString value; } ]) variableValues));
  expandVariables = value: replaceStrings (attrNames variablesMap) (attrValues variablesMap) (toString value);
  scalarEnv = filterAttrs (name: _: name != "TERM") (mapAttrs (_: expandVariables) (osConfig.environment.variables // config.home.sessionVariables // baseNushellEnv));
  prependSearchVariable = name: values: ''
    mut current_${name} = ($env.${name}? | default [])
    if (($current_${name} | describe) == "string") {
       $current_${name} = ($current_${name} | split row (char esep))
    }
    $env.${name} = ${toNu (map expandVariables values)} ++ ($current_${name} | where $it != "")
  '';
  sessionSearchEnv = concatLines (mapAttrsToList prependSearchVariable config.home.sessionSearchVariables);
  ghosttyIntegration = lib.getOutput "shell_integration" pkgs.ghostty-bin;
  # sessionPath = config.home.sessionPath

  systemPath = osConfig.environment.systemPath |> expandVariables |> lib.splitString ":" |> toNu;

  nu_scripts_file = path: "${lib.getLib pkgs.nu_scripts}/share/nu_scripts/${path}";
  nu_completion = name: (nu_scripts_file "custom-completions/${name}/${name}-completions.nu");
  mkCompletions = cmds: let stmts = map (c: "use ${nu_completion c} *") cmds; in lib.join "\n" stmts;
  nu_dir = path: "${config.programs.nushell.configDir}/${path}";
in {
  programs.nushell = {
    enable = true;
    configFile.source = ./nushell/config.nu;
    shellAliases.ll = "ls -la";
    extraEnv =
      ''
        load-env ${toNu scalarEnv}

        def mk_env_conv [ sep: string ] {
            {
                from_string: { |s| $s | split row $sep | path expand --no-symlink }
                to_string: { |v| $v | path expand --no-symlink | str join $sep }
            }
        }
        $env.ENV_CONVERSIONS = $env.ENV_CONVERSIONS | merge {
            "XDG_DATA_DIRS": (mk_env_conv (char esep)),
            "XDG_CONFIG_DIRS": (mk_env_conv (char esep)),
            "TERMINFO_DIRS": (mk_env_conv (char esep)),
            "MANPATH": (mk_env_conv (char esep)),
            "NIX_PROFILES": (mk_env_conv " ")
        }


        # $env.XDG_DATA_DIRS ++= [ "${ghosttyIntegration.outPath}" ]
        $env.PATH = ${systemPath} ++ $env.PATH;

        ${sessionSearchEnv}

        const codex_mcp_tokens_env = "${config.xdg.configHome}/nushell/mcp-tokens.nu"
        source-env (if ($codex_mcp_tokens_env | path exists) { $codex_mcp_tokens_env } else { null })
      ''
      + lib.optionalString (config.machineType == "work") ''
        const work_identity_env = "${config.xdg.configHome}/nushell/work-identity.nu"
        source-env (if ($work_identity_env | path exists) { $work_identity_env } else { null })
      '';
    plugins = [
      pkgs.nushellPlugins.polars
      pkgs.nushellPlugins.query
      pkgs.nushellPlugins.gstat
      pkgs.nushellPlugins.formats
    ];
    extraConfig =
      ''
        const NU_LIB_DIRS = [
          ($nu.default-config-dir | path join 'scripts')
          ($nu.default-config-dir | path join 'modules')
          ($nu.default-config-dir | path join 'completions')
          ${lib.getLib pkgs.nu_scripts}/share/nu_scripts/modules/
          ${ghosttyIntegration.outPath}/nushell/vendor/autoload
        ];
        source '${nu_scripts_file "sourced/typeof.nu"}'
        use gitv2 gs
        use jc

        source cmds.nu
      ''
      + (mkCompletions [
        "bat"
        "cargo"
        "gh"
        # "git"
        "jj"
        "less"
        "make"
        "man"
        "nix"
        "op"
        "pre-commit"
        "rg"
        "ssh"
        "tar"
        "uv"
        # "zellij"
      ]);
  };
  home.file.nuScripts = {
    enable = true;
    source = ./nushell/scripts;
    target = nu_dir "scripts/";
  };
}
