{
  lib,
  options,
  config,
  pkgs,
  inputs,
  ...
}:
{
  options.modules.firefox = {
    enable = lib.mkEnableOption "Enables Firefox";
  };

  config = lib.mkIf config.modules.firefox.enable {
    programs.firefox = {
      enable = true;
      package = pkgs.firefox;

      profiles = {
        default = {
          id = 0;
          name = "default";
          isDefault = true;
          extraConfig = builtins.readFile (inputs.arkenfox-userjs + "/user.js");
          settings = {
            "browser.bookmarks.addedImportButton" = "false";
            "browser.search.defaultenginename" = "Searx";
            "browser.search.order.1" = "Searx";
            "browser.startup.homepage" = "http://localhost:8888";
            "browser.toolbars.bookmarks.visibility" = "always";
          };
          search = {
            force = true;
            privateDefault = "Searx";
            default = "Searx";
            order = [ "Searx" ];
            engines = {
              "NixOS Packages" = {
                urls = [
                  {
                    template = "https://search.nixos.org/packages";
                    params = [
                      {
                        name = "channel";
                        value = "unstable";
                      }
                      {
                        name = "type";
                        value = "packages";
                      }
                      {
                        name = "query";
                        value = "{searchTerms}";
                      }
                    ];
                  }
                ];
                icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                definedAliases = [ "@np" ];
              };
              "Searx" = {
                urls = [
                  {
                    template = "http://localhost:8888";
                    params = [
                      {
                        name = "q";
                        value = "{searchTerms}";
                      }
                    ];
                  }
                ];
                definedAliases = [ "@searx" ];
              };
            };
          };
          bookmarks = [
            {
              name = "Self-hosted";
              toolbar = true;
              bookmarks = [
                {
                  name = "Syncthing";
                  url = "http://localhost:8384";
                }
              ];
            }
          ];
          extensions = with pkgs.nur.repos.rycee.firefox-addons; [
            ublock-origin
          ];
        };
      };
    };
  };
}
