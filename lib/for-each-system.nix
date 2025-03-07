{
  nixpkgs,
  systems,
}:
f: (system: f { inherit system; }) |> nixpkgs.lib.genAttrs systems
