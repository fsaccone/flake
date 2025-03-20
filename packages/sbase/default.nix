{
  lib,
  stdenv,
  fetchgit,
}:
stdenv.mkDerivation {
  name = "sbase";

  src = fetchgit {
    url = "git://francescosaccone.com/sbase";
    rev = "0.1";
    sha256 = "sha256-v+73ERFDtpL7bP9gC9zXndLn4HDxTuryTTQboFERduk=";
  };

  makeFlags = [ "CC:=$(CC)" ];

  installFlags = [ "PREFIX=$(out)" ];

  meta = {
    description = ''
      Collection of UNIX tools that are inherently portable across UNIX and
      UNIX-like systems.
    '';
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
  };
}
