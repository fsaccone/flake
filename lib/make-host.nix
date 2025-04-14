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
    (../hardware + "/${host}")
    ../hosts/common
    inputs.self.outputs.nixosModules.default
    (
      {
        config,
        ...
      }:
      {
        networking.hostName = "fs-${host}";
        nixpkgs.overlays = [
          inputs.self.outputs.overlays.default
        ];
      }
    )
  ] ++ additionalModules;
}
