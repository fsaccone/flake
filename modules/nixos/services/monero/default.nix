{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  options.fs.services.monero = {
    enable = lib.mkOption {
      description = "Whether to enable Monero daemon.";
      default = false;
      type = lib.types.bool;
    };
    mining = {
      enable = lib.mkOption {
        description = "Whether to mine monero.";
        default = false;
        type = lib.types.bool;
      };
      address = lib.mkOption {
        description = "The address where rewards are sent.";
        type = lib.types.uniq lib.types.str;
      };
    };
  };

  config = lib.mkIf config.fs.services.monero.enable {
    users = {
      users = {
        monero = {
          hashedPassword = "!";
          isSystemUser = true;
          group = "monero";
          createHome = true;
          home = "/var/lib/monero";
        };
      };
      groups = {
        monero = { };
      };
    };

    environment.systemPackages = [ pkgs.monero-cli ];

    systemd.services.monero = {
      enable = true;
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      serviceConfig = {
        User = "monero";
        Group = "monero";
        Type = "simple";
        Restart = "on-failure";
        ExecStart =
          let
            inherit (config.fs.services.monero) mining;

            miningOptions = builtins.concatStringsSep " " [
              "--start-mining '${config.fs.services.monero.mining.address}'"
              "--mining-threads 0"
              "--bg-mining-enable"
            ];
          in
          pkgs.writeShellScript "monero" ''
            ${pkgs.monero-cli}/bin/monerod \
              --non-interactive \
              --log-file /dev/stdout \
              --data-dir /var/lib/monero \
              --rcp-bind-port 18081 \
              ${if mining.enable then miningOptions else ""}
          '';
      };
    };

    networking.firewall.allowedTCPPorts = [ 18081 ];
  };
}
