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
    rev = "2f03e02501ace0696f117c3d1f5bfcd74a4f3962";
    sha256 = "sha256-0O0bQqTAtt9GwMoDucZ0upKTNIgpYl/GUvGWYQbnCAE=";
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
