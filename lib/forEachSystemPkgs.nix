let
  forEachSystem = import ./forEachSystem.nix;
  getPkgs = import ./getPkgs.nix;
in
{ nixpkgs, systems }:
f:
forEachSystem
  {
    inherit nixpkgs systems;
  }
  (
    system:
    f {
      inherit system;
      pkgs = getPkgs { inherit nixpkgs system; } { };
    }
  )
