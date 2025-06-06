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
    user = lib.mkOption {
      description = "The user who owns the directory.";
      default = "merecat";
      type = lib.types.uniq lib.types.str;
    };
    group = lib.mkOption {
      description = "The group who owns the directory.";
      default = "merecat";
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

  config = lib.mkIf config.fs.services.merecat.enable {
    users = {
      users = {
        merecat = {
          hashedPassword = "!";
          isNormalUser = true;
          group = "merecat";
          createHome = false;
        };
      };
      groups = {
        merecat = { };
      };
    };

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
                inherit (config.fs.services.merecat) directory user group;

                preStartScriptsCall =
                  preStart.scripts
                  |> builtins.map (s: "${pkgs.su}/bin/su -m -c ${s} ${user}")
                  |> builtins.concatStringsSep "\n";

                script = pkgs.writeShellScriptBin "merecat" ''
                  ${pkgs.sbase}/bin/mkdir -p ${directory}

                  ${pkgs.sbase}/bin/chown -R ${user}:${group} ${directory}
                  ${pkgs.sbase}/bin/chmod -R 744 ${directory}

                  ${preStartScriptsCall}

                  for file in $(${pkgs.sbase}/bin/find ${directory} \
                                -name '*.html' -o -name '*.css'); do
                    ${pkgs.gzip}/bin/gzip -c $file > $file.gz
                  done

                  ${pkgs.merecat}/bin/merecat \
                    -n \
                    -p 80 \
                    -r \
                    -u ${user} \
                    ${directory}
                '';
              in
              {
                User = "root";
                Group = "root";
                Restart = "on-failure";
                Type = "simple";
                ExecStart = "${script}/bin/merecat";
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
