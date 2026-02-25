{ pkgs, lib, config, ... }: {
  environment = {
    systemPackages = [
      pkgs.vim
      pkgs.libiconv
      pkgs.openssl
      pkgs.pkg-config
    ];
    variables = {
      LIBRARY_PATH = "${pkgs.libiconv.out}/lib";
      C_INCLUDE_PATH = "${pkgs.libiconv.out}/include";
      OPENSSL_DIR = "${pkgs.openssl.out}";
      OPENSSL_LIB_DIR = "${pkgs.openssl.out}/lib";
      OPENSSL_INCLUDE_DIR = "${pkgs.openssl.dev}/include";
      PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig";
      CONFIG_ATTRS = "${toString (builtins.attrNames config)}";
    };
  };
}
