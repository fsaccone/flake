{ pkgs, ... }:
{
  projectRootFile = "flake.nix";

  programs = {
    deadnix.enable = true;
    nixfmt.enable = true;
    prettier.enable = true;
    statix.enable = true;
  };

  settings = {
    formatter = {
      deadnix.options = [
        "--no-lambda-arg"
        "--no-lambda-pattern-names"
      ];
      nixfmt.options = [
        "--width=80"
        "--verify"
        "--strict"
      ];
    };
    global.excludes = [
      ".editorconfig"
      "README"
      "LICENSE"
      "*.asc"
      "*.gpg"
      "*.lua"
      "*.pub"
      "*.pem"
      "*.png"
      "*.txt"
    ];
  };
}
