{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  options.fs.services.smtp = {
    enable = lib.mkOption {
      description = "Whether to enable the SMTP server.";
      default = false;
      type = lib.types.bool;
    };
  };

  config = lib.mkIf config.fs.services.smtp.enable { };
}
