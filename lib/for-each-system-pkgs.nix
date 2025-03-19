{
  nixpkgs,
  inputs,
  systems,
}:
let
  forEachSystem = import ./for-each-system.nix;
  getPkgs = import ./get-pkgs.nix { inherit nixpkgs inputs; };
in
f:
(
  { system }:
  f {
    inherit system;
    pkgs = getPkgs { inherit system; };
  }
)
|> forEachSystem {
  inherit nixpkgs systems;
}
