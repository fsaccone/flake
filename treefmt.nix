{
  pkgs,
  ...
}:
{
  projectRootFile = "flake.nix";

  programs = {
    nixfmt.enable = true;
    prettier.enable = true;
  };

  settings = {
    global.excludes = [
      ".editorconfig"
      "README"
      "LICENSE"
      "*.asc"
      "*.pub"
      "*.txt"
    ];
  };
}
