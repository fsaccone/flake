let
  forEachSystem = import ./for-each-system.nix;
  getPkgs = import ./get-pkgs.nix;
in
{ nixpkgs, systems }:
f:
(
  { system }:
  f {
    inherit system;
    pkgs = getPkgs { inherit nixpkgs; } { inherit system; };
  }
)
|> forEachSystem {
  inherit nixpkgs systems;
}
