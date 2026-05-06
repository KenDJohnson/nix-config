{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf (config.machineType == "work") {
    age.secrets.work-identity = {
      file = ./work-identity.age;
      path = "${config.home.homeDirectory}/.local/share/agenix/work-identity";
    };

    home.packages = with pkgs; [
      google-cloud-sdk
    ];

    home.activation.generateWorkIdentitySecrets = lib.hm.dag.entryAfter ["writeBoundary" "agenix"] ''
      mkdir -p "${config.xdg.configHome}/work" "${config.xdg.configHome}/nushell" "${config.xdg.configHome}/git"
      work_env="${config.xdg.configHome}/work/env.sh"
      work_nu_env="${config.xdg.configHome}/nushell/work-identity.nu"
      work_git_config="${config.xdg.configHome}/git/work-identity"

      : > "$work_env"
      : > "$work_nu_env"
      : > "$work_git_config"

      if [ -f "${config.age.secrets.work-identity.path}" ]; then
        "${lib.getExe pkgs.jq}" -r \
          '.env // {} | to_entries[] | "export \(.key)=\(.value | @sh)"' \
          "${config.age.secrets.work-identity.path}" > "$work_env"
        "${lib.getExe pkgs.jq}" -r \
          '.env // {} | to_entries[] | "$env.\(.key) = \(.value | @json)"' \
          "${config.age.secrets.work-identity.path}" > "$work_nu_env"
        "${lib.getExe pkgs.jq}" -r \
          '.git // empty | "[user]\n    name = \(.name)\n    email = \(.email)"' \
          "${config.age.secrets.work-identity.path}" > "$work_git_config"
      fi

      $DRY_RUN_CMD chmod 600 "$work_env" "$work_nu_env" "$work_git_config"
    '';

    programs.git.includes = lib.mkAfter [
      {path = "${config.xdg.configHome}/git/work-identity";}
    ];
  };
}
