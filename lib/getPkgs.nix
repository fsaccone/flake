{ nixpkgs }:
{
  system,
}:
import nixpkgs {
  inherit system;
  config = {
    allowBroken = false;
    allowUnfree = false;
  };
}
