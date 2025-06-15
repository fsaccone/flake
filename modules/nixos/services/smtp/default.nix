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
      description = "Whether to enable the SMTP server using OpenSMTPD.";
      default = false;
      type = lib.types.bool;
    };
    tls = {
      certificate = lib.mkOption {
        description = "The path to the TLS certificate file.";
        type = lib.types.uniq lib.types.path;
      };
      key = lib.mkOption {
        description = "The path to the TLS key file.";
        type = lib.types.uniq lib.types.path;
      };
    };
  };

  config = lib.mkIf config.fs.services.smtp.enable { };
}
