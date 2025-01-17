{ nixpkgs, inputs }:
host:
{
  additionalModules ? [ ],
}:
nixpkgs.lib.nixosSystem {
  specialArgs = {
    inherit inputs;
    getSecretFile = secret: ../hosts + "/${host}/secrets/${secret}.asc";
  };
  modules = [
    (../hosts + "/${host}")
    ../hosts/common
    ../modules/nixos
  ] ++ additionalModules;
}
