{
  lib,
  stdenv,
  fetchgit,
  pass,
}:
stdenv.mkDerivation rec {
  name = "pass";

  src = fetchgit {
    url = "git://git.francescosaccone.com/pass";
    rev = "a4307edc2cfff354d448d4a7df538aee0c3e55d7";
    sha256 = "sha256-2AocSyHfjfinloder1hb254wS3bly6MNtHMzShxTenA=";
  };

  buildInputs = [
    (pass.withExtensions (exts: [ exts.pass-otp ]))
    xclip
  ];

  installPhase = ''
    mkdir -p $out/bin
    cp $src/pass.sh $out/bin/pass
    chmod +x $out/bin/pass
  '';

  meta = {
    description = "Francesco Saccone's password store.";
    platforms = lib.platforms.unix;
  };
}
