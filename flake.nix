{
  description = "Francesco Saccone's Nix flake.";

  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs/release-24.11";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    openpgp-key = {
      url = "https://francescosaccone.com/public/francescosaccone.asc";
      flake = false;
    };
    password-store = {
      url = "git://git.francescosaccone.com/password-store";
      flake = false;
    };
    site = {
      url = "git://git.francescosaccone.com/site";
      flake = false;
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
          forEachSystem = import ./lib/for-each-system.nix {
            inherit (inputs) nixpkgs;
            inherit systems;
          };
          forEachSystemPkgs = import ./lib/for-each-system-pkgs.nix {
            inherit (inputs) nixpkgs;
            inherit systems inputs;
          };
          makeHost = import ./lib/make-host.nix {
            inherit (inputs) nixpkgs;
            inherit inputs;
          };
          getPkgs = import ./lib/get-pkgs.nix {
            inherit (inputs) nixpkgs;
            inherit inputs;
          };
        };

      treefmtEval = lib.forEachSystemPkgs (
        { system, pkgs }: inputs.treefmt-nix.lib.evalModule pkgs ./treefmt.nix
      );
    in
    {
      checks = lib.forEachSystem (
        { system }:
        {
          formatting = treefmtEval.${system}.config.build.check inputs.self;
        }
      );

      formatter = lib.forEachSystem (
        {
          system,
        }:
        treefmtEval.${system}.config.build.wrapper
      );

      packages = lib.forEachSystem (
        {
          system,
        }:
        import ./packages inputs.nixpkgs.legacyPackages.${system}
      );

      overlays.default = final: prev: import ./packages final.pkgs;

      homeManagerModules.default = import ./modules/home-manager;

      nixosModules.default = import ./modules/nixos;

      nixosConfigurations = {
        "laptop" = lib.makeHost "laptop" {
          additionalModules = [
            inputs.home-manager.nixosModules.home-manager
          ];
        };
        "git-server" = lib.makeHost "git-server" {
          additionalModules = [
            inputs.disko.nixosModules.disko
          ];
        };
        "main-server" = lib.makeHost "main-server" {
          additionalModules = [
            inputs.disko.nixosModules.disko
          ];
        };
      };
    };
}
