{ nixpkgs }:
{
  system,
  overlays ? [ ],
}:
import nixpkgs {
  inherit system;
  inherit overlays;
  config = {
    allowBroken = false;
    allowUnfree = false;
  };
}
