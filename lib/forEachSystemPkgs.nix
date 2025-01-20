let
  forEachSystem = import ./forEachSystem.nix;
  getPkgs = import ./getPkgs.nix;
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
