{
  pkgs,
  ...
}:
{
  projectRootFile = "flake.nix";

  programs = {
    nixfmt.enable = true;
    prettier.enable = true;
    statix.enable = true;
  };

  settings = {
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
