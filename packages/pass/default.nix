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
    rev = "ef570ec804cf0fa45d96088680e4af174e021bbc";
    sha256 = "sha256-o97cAGDZUUz0vtXmTjtZF4yO5qn+6buupZbmBK9ZiqU=";
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
