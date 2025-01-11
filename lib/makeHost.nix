{ nixpkgs, inputs }:
host:
{
  additionalModules ? [ ],
}:
nixpkgs.lib.nixosSystem {
  specialArgs = {
    inherit inputs;
  };
  modules = [
    (../hosts + "/${host}")
    ../hosts/common
    ../modules/nixos
  ] ++ additionalModules;
}
