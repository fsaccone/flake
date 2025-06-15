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

  config = lib.mkIf config.fs.services.smtp.enable {
    environment.etc."mail/smtpd.conf".text =
      let
        inherit (config.fs.services.smtp) tls;
      in
      ''
        pki tls cert "${tls.certificate}"
        pki tls key "${tls.key}"

        listen on all smtps verify pki tls
        listen on all tls pki tls
      '';

    systemd = {
      services = {
        smtp = {
          enable = true;
          wantedBy = [ "multi-user.target" ];
          after = [ "network.target" ];
          serviceConfig = {
            User = "root";
            Group = "root";
            Restart = "on-failure";
            Type = "simple";
            ExecStart = pkgs.writeShellScript "smtp" ''
              ${pkgs.opensmtpd}/bin/smtpd -d
            '';
          };
        };
      };
    };

    networking.firewall.allowedTCPPorts = [
      25
      465
    ];
  };
}
