{
  config,
  lib,
  pkgs,
  ...
}: let
  nu_scripts_file = path: "${lib.getLib pkgs.nu_scripts}/share/nu_scripts/${path}";
  nu_completion = name: (nu_scripts_file "custom-completions/${name}/${name}-completions.nu");
  mkCompletions = cmds: let stmts = map (c: "use ${nu_completion c} *") cmds; in lib.join "\n" stmts;
  nu_dir = path: "${config.programs.nushell.configDir}/${path}";
in {
  programs.nushell = {
    enable = true;
    configFile.source = ./nushell/config.nu;
    environmentVariables.SHELL = "${lib.getExe pkgs.nushell}";
    environmentVariables.NIX_CONFIG_DIR = "/etc/nix-darwin/";
    shellAliases.ll = "ls -la";
    extraEnv =
      ''
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
