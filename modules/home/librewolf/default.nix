{
  lib,
  options,
  config,
  pkgs,
  inputs,
  ...
}:
{
  options.modules.librewolf = {
    enable = lib.mkEnableOption "Enables Librewolf";
    engine = {
      name = lib.mkOption {
        type = lib.types.uniq lib.types.str;
        description = "The name of the default search engine.";
      };
      url = lib.mkOption {
        type = lib.types.uniq lib.types.str;
        description = "The URL to the default search engine.";
      };
    };
  };

  config = lib.mkIf config.modules.librewolf.enable {
    programs.librewolf = {
      enable = true;
      package = pkgs.librewolf;

      settings = let
        inherit (config.modules.librewolf) engine;
      in
      {
        "privacy.resistFingerprinting.letterboxing" = true;
        "browser.sessionstore.resume_from_crash" = false;
        "middlemouse.paste" = false;
        "general.autoScroll" = true;
        "browser.toolbars.bookmarks.visibility" = "never";

        "browser.search.defaultenginename" = engine.name;
        "browser.search.order.1" = engine.name;
        "browser.startup.homepage" = engine.url;
      };

      profiles = {
        default = {
          id = 0;
          name = "default";
          isDefault = true;
          extraConfig = builtins.readFile (inputs.arkenfox-userjs + "/user.js");
          settings = {
            "browser.bookmarks.addedImportButton" = "false";
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
          extensions = with pkgs.nur.repos.rycee.firefox-addons; [
            ublock-origin
          ];
        };
      };
    };
  };
}
