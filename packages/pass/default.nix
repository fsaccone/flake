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
    rev = "c6afc30899ea2f4ff4e07d9bd7d06e24a497ed62";
    sha256 = "sha256-aqlGvXTIIqwsuRQ9UEEM70Kf/3TAAg8h+etzocgZRHw=";
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
