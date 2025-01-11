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
    treefmt = {
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
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "i686-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

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

      treefmtEval = forEachSystemPkgs (
        { system, pkgs }: inputs.treefmt.lib.evalModule pkgs ./treefmt.nix
      );
    in
    {
      formatter = forEachSystemPkgs ({ system, pkgs }: treefmtEval.${system}.config.build.wrapper);
      checks = forEachSystemPkgs (
        { system, pkgs }:
        {
          formatting = treefmtEval.${system}.config.build.check inputs.self;
        }
      );

      nixosConfigurations = {
        "laptop" = makeHost "laptop" {
          additionalModules = makeHomeModules "francesco" ++ [
            inputs.nur.modules.nixos.default
          ];
        };
      };
    };
}
