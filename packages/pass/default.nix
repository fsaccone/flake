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
    rev = "f3f84ac8e15819b5248fdde98d20cb210cd273f7";
    sha256 = "sha256-su/z/c3TJxRc5hCHiu47U8LZ9IqUeFZxfvxX+qlaFvA=";
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
