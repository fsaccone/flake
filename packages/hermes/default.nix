{
  lib,
  stdenv,
  fetchgit,
}:
stdenv.mkDerivation {
  name = "hermes";

  src = fetchgit {
    url = "git://git.francescosaccone.com/hermes";
    rev = "0.1.1";
    sha256 = "sha256-nR1z9iWdl2vt6ytSHM3aGxJE8WxfOQJBQe/CP7CnjTY=";
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
