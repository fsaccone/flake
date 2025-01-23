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
    };
  };
}
