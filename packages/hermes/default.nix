{
  lib,
  stdenv,
  fetchgit,
}:
stdenv.mkDerivation {
  name = "hermes";

  src = fetchgit {
    url = "git://git.francescosaccone.com/hermes";
    rev = "0.1.0";
    sha256 = "sha256-w7ywSKayEvjdUPC7G17mH5uQqjsn/JZqL3pfKm1pXro=";
  };

  makeFlags = [ "CC:=$(CC)" ];

  installFlags = [ "PREFIX=$(out)" ];

  meta = {
    description = ''
      A minimalist GET/HEAD-only HTTP server for hosting static content.
    '';
    license = lib.licenses.isc;
    platforms = lib.platforms.unix;
  };
}
