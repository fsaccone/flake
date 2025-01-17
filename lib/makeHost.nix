{ nixpkgs, inputs }:
host:
{
  additionalModules ? [ ],
}:
nixpkgs.lib.nixosSystem {
  specialArgs = {
    inherit inputs;
    getSecretFile = import ./getSecretFile.nix;
  };
  modules = [
    (../hosts + "/${host}")
    ../hosts/common
    ../modules/nixos
  ] ++ additionalModules;
}
