pkgs: {
  fs = {
    gmnigit = pkgs.callPackage ./gmnigit { };
    gmnhg = pkgs.callPackage ./gmnhg { };
    sbase = pkgs.callPackage ./sbase { };
  };
}
