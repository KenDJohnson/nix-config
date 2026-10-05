{
  lib,
  stdenv,
  python312,
  callPackage,
  cctools,
  darwin,
  inputs,
}: let
  workspace = inputs.uv2nix.lib.workspace.loadWorkspace {workspaceRoot = ./.;};

  # uv2nix selects Darwin wheels using stdenv.targetPlatform.darwinSdkVersion.
  # The full bundle includes macOS 14+ MLX, ONNX Runtime and PyTorch wheels;
  # select the macOS 15 variants where supplied, not source distributions.
  wheelStdenv = stdenv.override {
    targetPlatform = stdenv.targetPlatform // {darwinSdkVersion = "15.0";};
  };

  pythonBase = callPackage inputs.pyproject-nix.build.packages {
    python = python312;
    stdenv = wheelStdenv;
  };

  nativeWheelOverlay = final: prev: {
    # mlx and mlx-metal share a Python namespace, but Nix installs their
    # wheels in separate outputs. dyld resolves @loader_path against the
    # real extension path, not the merged virtualenv's symlink tree.
    mlx = prev.mlx.overrideAttrs (old: {
      nativeBuildInputs =
        (old.nativeBuildInputs or [])
        ++ [
          cctools
          darwin.autoSignDarwinBinariesHook
        ];
      postInstall =
        (old.postInstall or "")
        + ''
          install_name_tool -change @rpath/libmlx.dylib \
            ${final.mlx-metal}/${python312.sitePackages}/mlx/lib/libmlx.dylib \
            "$out"/${python312.sitePackages}/mlx/core.cpython-312-darwin.so
        '';
    });
  };

  pythonSet = pythonBase.overrideScope (lib.composeManyExtensions [
    inputs.pyproject-build-systems.overlays.wheel
    (workspace.mkPyprojectOverlay {sourcePreference = "wheel";})
    nativeWheelOverlay
  ]);

  venv = pythonSet.mkVirtualEnv "hindsight-api-0.10.2-env" {
    hindsight-api = [];
  };

  inherit (callPackage inputs.pyproject-nix.build.util {}) mkApplication;
in
  assert lib.assertMsg (stdenv.hostPlatform.system == "aarch64-darwin")
  "Hindsight's locked full API bundle currently targets aarch64-darwin only";
    (mkApplication {
      inherit venv;
      # The full hindsight-api distribution is a dependency metapackage;
      # hindsight-api-slim owns all four upstream console entry points.
      package = pythonSet.hindsight-api-slim;
    }).overrideAttrs (old: {
      pname = "hindsight-api";
      version = "0.10.2";
      name = "hindsight-api-0.10.2";
      passthru = (old.passthru or {}) // {inherit venv;};
      meta = {
        description = "Hindsight agent memory API with local ML and embedded PostgreSQL";
        homepage = "https://github.com/vectorize-io/hindsight";
        license = lib.licenses.mit;
        mainProgram = "hindsight-api";
        platforms = ["aarch64-darwin"];
      };
    })
