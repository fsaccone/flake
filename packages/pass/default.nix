{
  lib,
  stdenv,
  fetchgit,
  pass,
  xclip,
}:
let
  extendedPass = pass.withExtensions (exts: [ exts.pass-otp ]);
in
stdenv.mkDerivation rec {
  name = "pass";

  src = fetchgit {
    url = "git://git.francescosaccone.com/pass";
    rev = "8794cdfd264ae844c1c944bec0b031c7bf97c64c";
    sha256 = "sha256-rkoz+DYC5fWKJ6iLftdFD520IUniPWvNd8BlINJZ2uY=";
  };

  buildInputs = [
    extendedPass
    xclip
  ];

  installPhase = ''
    mkdir -p $out/{bin,share/store}

    {
      echo "#!/bin/sh"
      echo "export PASS_PROGRAM=${extendedPass}/bin/pass"
      echo "export SOURCE_DIRECTORY=$out/share/store"
      cat $src/pass.sh
    } > $out/bin/pass

    cp -r $src/store/* $out/share/store/
    chmod +x $out/bin/pass
  '';

  meta = {
    description = "Francesco Saccone's password store.";
    platforms = lib.platforms.unix;
  };
}
