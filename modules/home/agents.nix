{
  config,
  lib,
  inputs,
  ...
}: {
  imports = [inputs.omp.homeManagerModules.default];

  config = lib.mkIf config.agents.enable {
    programs.omp = {
      enable = config.agents.omp.enable;
      settings = {
      };
    };
  };
}
