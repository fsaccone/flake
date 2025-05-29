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

  options.fs.services.darkhttpd = {
    enable = lib.mkOption {
      description = "Whether to enable Darkhttpd web server.";
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
      default = "darkhttpd";
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

  config = lib.mkIf config.fs.services.darkhttpd.enable {
    users = {
      users = {
        darkhttpd = {
          hashedPassword = "!";
          isSystemUser = true;
          group = "darkhttpd";
          createHome = true;
          home = "/var/www";
        };
      };
      groups = {
        darkhttpd = { };
      };
    };

    systemd = {
      services = {
        darkhttpd =
          let
            inherit (config.fs.services.darkhttpd) user preStart tls;
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

                  ${pkgs.darkhttpd}/bin/darkhttpd \
                    ${config.fs.services.darkhttpd.directory} \
                    --port 80 \
                    --index index.html \
                    --no-listing \
                    --uid ${user} \
                    --gid darkhttpd \
                    --no-server-id \
                    --ipv6 ${if tls.enable then "--forward-https" else ""}
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
        darkhttpd = {
          enable = true;
          wantedBy = [ "multi-user.target" ];
          pathConfig = {
            PathModified = [ config.fs.services.darkhttpd.directory ];
          };
        };
      };
    };

    networking.firewall.allowedTCPPorts = [ 80 ];
  };
}
