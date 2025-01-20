{
  description = ''
    Francesco Saccone's Nix flake.
  '';

  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixos-unstable";
    };
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    arkenfox-userjs = {
      url = "github:arkenfox/user.js";
      flake = false;
    };
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    let
      lib =
        let
          systems = [
            "aarch64-linux"
            "x86_64-linux"
          ];
        in
        {
          forEachSystem = import ./lib/forEachSystem.nix {
            inherit (inputs) nixpkgs;
            inherit systems;
          };
          forEachSystemPkgs = import ./lib/forEachSystemPkgs.nix {
            inherit (inputs) nixpkgs;
            inherit systems;
          };
          makeHost = import ./lib/makeHost.nix {
            inherit (inputs) nixpkgs;
            inherit inputs;
          };
          makeHomeModules = import ./lib/makeHomeModules.nix {
            inherit (inputs) home-manager;
            inherit inputs;
          };
          getPkgs = import ./lib/getPkgs.nix {
            inherit (inputs) nixpkgs;
          };
        };

      treefmtEval = lib.forEachSystemPkgs (
        { system, pkgs }: inputs.treefmt-nix.lib.evalModule pkgs ./treefmt.nix
      );
    in
    {
      formatter = lib.forEachSystem ({ system }: treefmtEval.${system}.config.build.wrapper);
      checks.formatting = lib.forEachSystem (
        { system }: treefmtEval.${system}.config.build.check inputs.self
      );

      nixosConfigurations = {
        "laptop" = lib.makeHost "laptop" {
          additionalModules = lib.makeHomeModules "francesco" ++ [
            inputs.nur.modules.nixos.default
          ];
        };
      };
    };
}
