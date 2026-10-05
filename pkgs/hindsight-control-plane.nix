{
  lib,
  stdenvNoCC,
  fetchurl,
  makeWrapper,
  nodejs_24,
}: let
  # The published standalone bundle contains Linux-only Sharp binaries. Use
  # the matching upstream native modules, preserving their relative dylib paths.
  sharpDarwin = fetchurl {
    url = "https://registry.npmjs.org/@img/sharp-darwin-arm64/-/sharp-darwin-arm64-0.35.4.tgz";
    hash = "sha512-Uhfl4V4lhP2nbUVF9+hyH1+luj86f1gUFeo8ALYxFoULoU+G87D43BfeMP8XHsk9boxAnCY/bf2EHwhA7MuGsA==";
  };
  libvipsDarwin = fetchurl {
    url = "https://registry.npmjs.org/@img/sharp-libvips-darwin-arm64/-/sharp-libvips-darwin-arm64-1.3.3.tgz";
    hash = "sha512-suTBPTDGrI9WodccaDdwZItTSaBYASlBk1NSfElSHrUfzu3szG6lvIF58+WiFvnfzuK8ZBFS5zE00PxqxnRiPg==";
  };
in
  stdenvNoCC.mkDerivation {
    pname = "hindsight-control-plane";
    version = "0.10.2";

    src = fetchurl {
      url = "https://registry.npmjs.org/@vectorize-io/hindsight-control-plane/-/hindsight-control-plane-0.10.2.tgz";
      hash = "sha512-eKKUoO51WRN0lAOUGs/doI3MfrraFKSw/gOCtuDJaVMS7FEGrD0rpX6DOUVptmb8vdvPBv6ssqmZixEMB5Hfrg==";
    };
    sourceRoot = "package";

    nativeBuildInputs = [makeWrapper];
    strictDeps = true;
    dontBuild = true;
    doCheck = false;
    # Keep the upstream Mach-O signatures and loader-relative library paths.
    dontStrip = true;

    postPatch = ''
      # Next's ISR and image caches otherwise write into the immutable .next
      # directory. Disable disk flushing, not rendering or image optimization.
      substituteInPlace standalone/server.js \
        --replace-fail '"isrFlushToDisk":true' '"isrFlushToDisk":false'
      substituteInPlace standalone/.next/required-server-files.json \
        --replace-fail '"isrFlushToDisk": true' '"isrFlushToDisk": false'
    '';

    installPhase = ''
      runHook preInstall

      app="$out/lib/hindsight-control-plane"
      mkdir -p "$app" "$out/bin"
      cp -R bin standalone package.json "$app/"

      modules="$app/standalone/node_modules"
      rm -rf \
        "$modules/@img/sharp-linux-x64" \
        "$modules/@img/sharp-linuxmusl-x64" \
        "$modules/@img/sharp-libvips-linux-x64" \
        "$modules/@img/sharp-libvips-linuxmusl-x64"
      mkdir -p "$modules/@img/sharp-darwin-arm64" "$modules/@img/sharp-libvips-darwin-arm64"
      tar -xzf ${sharpDarwin} --strip-components=1 -C "$modules/@img/sharp-darwin-arm64"
      tar -xzf ${libvipsDarwin} --strip-components=1 -C "$modules/@img/sharp-libvips-darwin-arm64"

      # The CLI starts a second node process by name; pin both processes to Node 24.
      makeWrapper ${nodejs_24}/bin/node "$out/bin/hindsight-control-plane" \
        --add-flags "$app/bin/cli.js" \
        --prefix PATH : ${lib.makeBinPath [nodejs_24]}

      runHook postInstall
    '';

    meta = {
      description = "Standalone web control plane for Hindsight";
      homepage = "https://github.com/vectorize-io/hindsight";
      license = with lib.licenses; [
        isc
        asl20
        lgpl3Plus
      ];
      mainProgram = "hindsight-control-plane";
      platforms = ["aarch64-darwin"];
    };
  }
