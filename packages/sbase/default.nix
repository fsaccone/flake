{
  lib,
  stdenv,
  fetchgit
}:
stdenv.mkDerivation {
  pname = "sbase";
  version = "0.1";

  src = fetchgit {
    url = "git://git.suckless.org/sbase";
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
    homepage = "https://git.suckless.org/sbase/file/README.html";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
