# IDA user environment: IDAPython embeds a Nix Python, and the IDA venv
# ($IDAUSR/venv) holds plugin dependencies such as ida-nexus for the Hex-Rays
# IDA MCP. One-time imperative setup after switching (IDA user state):
#   idapyswitch --force-path ~/.local/share/ida/python3.14/lib/libpython3.14.dylib
#   uv venv --seed --python ~/.local/share/ida/python3.14/bin/python3.14 ~/.idapro/venv
{
  config,
  lib,
  pkgs,
  ...
}: let
  python = pkgs.python314;
  pythonVersion = python.pythonVersion;
  venv = "${config.home.homeDirectory}/.idapro/venv";
  venvPython = "${venv}/bin/python";

  # IDAPython sets PYTHONHOME from the libpython path registered with
  # idapyswitch, and the venv records its base interpreter path. Linking this
  # prefix at a fixed path keeps both valid across nixpkgs Python updates and
  # garbage collection.
  idaPython = pkgs.symlinkJoin {
    name = "ida-python${pythonVersion}";
    paths = [python];
    # Load the venv's packages even when IDA starts without
    # IDAPYTHON_VENV_EXECUTABLE, e.g. idat workers spawned by the omp IDA MCP
    # extension, which does not forward that variable. Only IDA reads this
    # .pth: it runs with PYTHONHOME set to this prefix, while the venv excludes
    # base site-packages.
    postBuild = ''
      echo "import site; site.addsitedir('${venv}/lib/python${pythonVersion}/site-packages')" \
        > "$out/lib/python${pythonVersion}/site-packages/ida-venv.pth"
    '';
  };
in {
  config = lib.mkIf (config.ida.enable && pkgs.stdenv.hostPlatform.isDarwin) {
    xdg.dataFile."ida/python${pythonVersion}".source = idaPython;

    home.sessionVariables.IDAPYTHON_VENV_EXECUTABLE = venvPython;

    # IDA started from Finder or the Dock does not inherit shell variables;
    # this is the LaunchAgent `hcli ida python create-environment` would write.
    launchd.agents.idapython-venv-executable = {
      enable = true;
      config = {
        ProgramArguments = ["/bin/launchctl" "setenv" "IDAPYTHON_VENV_EXECUTABLE" venvPython];
        RunAtLoad = true;
      };
    };
  };
}
