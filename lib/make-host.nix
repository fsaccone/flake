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
    ../modules/nixos
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
