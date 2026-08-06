{
  stdenv,
  lib,
  rustPlatform,
  autoPatchelfHook,
  pkg-config,
  cmake,
  gitMinimal,
  protobuf,
  llvmPackages_latest,
  openssl,
  sqlite,
  zlib,
  src,
  revision,
}:

rustPlatform.buildRustPackage {
  pname = "nockchain";
  version = "0.1.0-${lib.substring 0 7 revision}";

  inherit src;

  cargoHash = "sha256-Iu+j01LiRzc7ZITn4G/bOIcBsbzb8vyKPAkazX7Z+E4=";
  preBuild = ''
    export HOME="$TMPDIR/home"
    mkdir -p "$HOME" assets

    cargo build --release --locked \
      --target ${stdenv.hostPlatform.rust.rustcTarget} \
      -p hoonc \
      --bin hoonc
    hoonc=target/${stdenv.hostPlatform.rust.rustcTarget}/release/hoonc

    "$hoonc" \
      --data-dir "$TMPDIR/hoonc-dumb" \
      --output dumb.jam \
      hoon/apps/dumbnet/outer.hoon \
      hoon
    mv dumb.jam assets/dumb.jam

    "$hoonc" \
      --data-dir "$TMPDIR/hoonc-miner" \
      --output miner.jam \
      hoon/apps/dumbnet/miner.hoon \
      hoon
    mv miner.jam assets/miner.jam
  '';

  cargoBuildFlags = [
    "-p"
    "nockchain"
    "--bin"
    "nockchain"
  ];
  doCheck = false;

  nativeBuildInputs = [
    cmake
    gitMinimal
    llvmPackages_latest.clang
    llvmPackages_latest.lld
    llvmPackages_latest.llvm
    pkg-config
    protobuf
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [
    autoPatchelfHook
  ];

  buildInputs = [
    llvmPackages_latest.libclang
    openssl
    sqlite
    zlib
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [
    stdenv.cc.cc.lib
  ];
  strictDeps = true;

  LIBCLANG_PATH = "${llvmPackages_latest.libclang.lib}/lib";
  LD_LIBRARY_PATH = lib.optionalString stdenv.hostPlatform.isLinux (
    lib.makeLibraryPath [ stdenv.cc.cc.lib ]
  );
  GIT_SHA = revision;
  BUILD_EMBED_LABEL = revision;
  BUILD_HOST = "nix";
  BUILD_USER = "nix";
  BUILD_TIMESTAMP = "0";
  FORMATTED_DATE = "1970-01-01";

  meta = {
    description = "Nockchain non-mining peer node";
    homepage = "https://github.com/zorp-corp/nockchain";
    license = with lib.licenses; [
      asl20
      mit
    ];
    mainProgram = "nockchain";
    platforms = lib.platforms.unix;
  };
}
