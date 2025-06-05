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

  options.fs.services.merecat = {
    enable = lib.mkOption {
      description = "Whether to enable Merecat web server.";
      default = false;
      type = lib.types.bool;
    };
    directory = lib.mkOption {
      description = "The root directory to statically host.";
      default = "/var/www";
      readOnly = true;
      type = lib.types.uniq lib.types.path;
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

  config = lib.mkIf config.fs.services.merecat.enable {
    systemd = {
      services = {
        merecat =
          let
            inherit (config.fs.services.merecat) preStart;
          in
          rec {
            enable = true;
            wantedBy = [ "multi-user.target" ];
            after = [ "network.target" ];
            path = preStart.packages;
            serviceConfig =
              let
                script = pkgs.writeShellScriptBin "script" ''
                  ${pkgs.sbase}/bin/mkdir -p \
                    ${config.fs.services.merecat.directory}

                  ${pkgs.sbase}/bin/chmod a+rw \
                    ${config.fs.services.merecat.directory}

                  ${builtins.concatStringsSep "\n" preStart.scripts}

                  ${pkgs.sbase}/bin/chmod -R a+rw \
                    ${config.fs.services.merecat.directory}

                  ${pkgs.sbase}/bin/chown nobody:nogroup \
                    ${config.fs.services.merecat.directory}

                  for file in $(${pkgs.sbase}/bin/find \
                                ${config.fs.services.merecat.directory} \
                                -name '*.html' -o -name '*.css'); do
                    ${pkgs.gzip}/bin/gzip -c $file > $file.gz
                  done

                  ${pkgs.merecat}/bin/merecat \
                    -n \
                    -p 80 \
                    -r \
                    ${config.fs.services.merecat.directory}
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
        merecat = {
          enable = true;
          wantedBy = [ "multi-user.target" ];
          pathConfig = {
            PathModified = [ config.fs.services.merecat.directory ];
          };
        };
      };
    };

    networking.firewall.allowedTCPPorts = [ 80 ];
  };
}
