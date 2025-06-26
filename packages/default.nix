pkgs: {
  fs = {
    gmnigit = pkgs.callPackage ./gmnigit { };
    gmnhg = pkgs.callPackage ./gmnhg { };
    pass = pkgs.callPackage ./pass { };
    sbase = pkgs.callPackage ./sbase { };
  };
}
