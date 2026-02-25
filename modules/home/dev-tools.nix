{ config, lib, pkgs, ... }: {
  config = lib.mkIf config.devTools.enable {
    home.packages = with pkgs;
      [ shfmt shellcheck bash-language-server ]
      ++ lib.optionals config.devTools.languages.nix [ alejandra nil manix statix nix-search devenv ]
      ++ lib.optionals config.devTools.languages.cpp [ gnumake llvm clang libiconv ]
      ++ lib.optionals config.devTools.languages.rust [ capnproto capnproto-rust protobuf ]
      ++ lib.optionals config.devTools.languages.node [ nodejs_24 pnpm ]
      ++ lib.optionals config.devTools.languages.python [ uv python312Packages.grip ]
      ++ lib.optionals config.devTools.latex [
        (texliveFull.withPackages (
          ps:
            with ps; [
              tidyres
              paracol
            ]
        ))
        ghostscript
      ];
  };
}
