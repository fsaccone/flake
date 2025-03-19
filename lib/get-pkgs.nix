{ nixpkgs, inputs }:
{
  system,
}:
import nixpkgs {
  inherit system;
  overlays = [
    inputs.self.outputs.overlays.default
  ];
  config = {
    allowBroken = false;
    allowUnfree = false;
  };
}
