{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  imports = [
    ./acme
    ./tls
  ];

  options.fs.services.quark = {
    enable = lib.mkOption {
      description = "Whether to enable Quark web server.";
      default = false;
      type = lib.types.bool;
    };
    directory = lib.mkOption {
      description = "The root directory to statically host.";
      default = "/var/www";
      type = lib.types.uniq lib.types.path;
    };
    user = lib.mkOption {
      description = "The user to drop privileges to.";
      default = "quark";
      type = lib.types.uniq lib.types.str;
    };
    preStart = {
      scripts = lib.mkOption {
        description = ''
          The list of scripts to run before starting the server.
        '';
        default = [ ];
        type = lib.types.listOf lib.types.path;
      };
      packages = lib.mkOption {
        description = "The list of packages required by the scripts.";
        default = [ ];
        type = lib.types.listOf lib.types.package;
      };
    };
  };

  config = lib.mkIf config.fs.services.quark.enable {
    users = {
      users = {
        quark = {
          hashedPassword = "!";
          isSystemUser = true;
          group = "quark";
          createHome = true;
          home = "/var/www";
        };
      };
      groups = {
        quark = { };
      };
    };

    systemd = {
      services = {
        quark =
          let
            inherit (config.fs.services.quark) preStart;
          in
          rec {
            enable = true;
            wantedBy = [ "multi-user.target" ];
            after = [ "network.target" ];
            path = preStart.packages;
            serviceConfig =
              let
                script = pkgs.writeShellScriptBin "script" ''
                  ${builtins.concatStringsSep "\n" preStart.scripts}

                  ${pkgs.quark}/bin/quark \
                    -p 80 \
                    -d ${config.fs.services.quark.directory} \
                    -u ${config.fs.services.quark.user} \
                    -g quark \
                    -i index.html
                '';
              in
              {
                User = "root";
                Group = "root";
                Restart = "on-failure";
                Type = "simple";
                ExecStart = "${script}/bin/script";
              };
          };
      };
      paths = {
        quark = {
          enable = true;
          wantedBy = [ "multi-user.target" ];
          pathConfig = {
            PathModified = [ config.fs.services.quark.directory ];
          };
        };
      };
    };

    networking.firewall.allowedTCPPorts = [ 80 ];
  };
}
