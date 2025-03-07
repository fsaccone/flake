{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  options.modules.newsraft = {
    enable = lib.mkOption {
      description = "Whether to enable Newsraft.";
      default = false;
      type = lib.types.bool;
    };
    feeds = lib.mkOption {
      description = "For each section name, its list of feeds.";
      default = { };
      type =
        lib.types.submodule {
          options = {
            name = lib.mkOption {
              description = "The name of the feed.";
              type = lib.types.uniq lib.types.str;
            };
            url = lib.mkOption {
              description = "The URL of the feed.";
              type = lib.types.uniq lib.types.str;
            };
          };
        }
        |> lib.types.listOf
        |> lib.types.attrsOf;
    };
  };

  config = lib.mkIf config.modules.newsraft.enable {
    home = {
      packages = [ pkgs.newsraft ];
      file = {
        ".config/newsraft/config".text = ''
          # Empty configuration as of now.
        '';
        ".config/newsraft/feeds".text =
          config.modules.newsraft.feeds
          |> builtins.mapAttrs (
            section: feeds: ''
              @ ${section}
              ${
                (
                  feeds
                  |> builtins.map (
                    { name, url }:
                    ''
                      ${url} "${name}"
                    ''
                  )
                  |> builtins.concatStringsSep "\n"
                )
              }
            ''
          )
          |> builtins.attrValues
          |> builtins.concatStringsSep "\n";
      };
    };
  };
}
