{
  lib,
  options,
  config,
  pkgs,
  inputs,
  ...
}:
{
  options.modules.vis = {
    enable = lib.mkOption {
      description = "Whether to enable Vis.";
      default = false;
      type = lib.types.bool;
    };
  };

  config = lib.mkIf config.modules.vis.enable {
    programs.bash.initExtra = ''
      export EDITOR=${pkgs.vis}/bin/vis
    '';

    home = {
      packages = [
        pkgs.vis
      ];
      file = {
        ".config/vis/visrc.lua".source = ./visrc.lua;
      };
    };
  };
}
