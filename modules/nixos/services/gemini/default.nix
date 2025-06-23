{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  options.fs.services.gemini = {
    enable = lib.mkOption {
      description = "Whether to enable the Gemini server with gmid.";
      default = false;
      type = lib.types.bool;
    };
    directory = lib.mkOption {
      description = "The root directory to statically host.";
      default = "/var/gemini";
      readOnly = true;
      type = lib.types.uniq lib.types.path;
    };
    user = lib.mkOption {
      description = "The user who owns the directory.";
      default = "gemini";
      type = lib.types.uniq lib.types.str;
    };
    group = lib.mkOption {
      description = "The group who owns the directory.";
      default = "gemini";
      type = lib.types.uniq lib.types.str;
    };
    tls = {
      certificate = lib.mkOption {
        description = "The TLS certificate.";
        type = lib.types.uniq lib.types.path;
      };
      key = lib.mkOption {
        description = "The TLS key.";
        type = lib.types.uniq lib.types.path;
      };
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

  config = lib.mkIf config.fs.services.gemini.enable {
    users = {
      users = {
        gemini = {
          hashedPassword = "!";
          isSystemUser = true;
          group = "gemini";
        };
      };
      groups = {
        gemini = { };
      };
    };

    systemd = {
      services = {
        gemini =
          let
            inherit (config.fs.services.gemini) preStart;
          in
          rec {
            enable = true;
            wantedBy = [ "multi-user.target" ];
            after = [ "network.target" ];
            path = preStart.packages;
            serviceConfig =
              let
                inherit (config.fs.services.gemini)
                  directory
                  errorPages
                  group
                  tls
                  user
                  ;

                preStartScriptsCall =
                  preStart.scripts
                  |> builtins.map (s: "${pkgs.su}/bin/su -m -c ${s} ${user}")
                  |> builtins.concatStringsSep "\n";

                configuration = builtins.toFile "gmid.conf" ''
                  chroot "${directory}"
                  user "${user}"

                  server "*" {
                    listen on * port 1965

                    cert "${tls.certificate}"
                    key "${tls.key}"

                    fastcgi off
                    log on

                    root "/"

                    location "${directory}" {
                      index "index.gmi"
                    }
                  }
                '';
              in
              {
                User = "root";
                Group = "root";
                Restart = "on-failure";
                Type = "simple";
                ExecStart = pkgs.writeShellScript "gemini.sh" ''
                  mkdir -p ${directory}

                  chown -R ${user}:${group} ${directory}
                  chmod -R 744 ${directory}

                  ${preStartScriptsCall}

                  chmod -R u+rwx ${directory}
                  chmod -R a+r ${directory}

                  ${pkgs.gmid}/bin/gmid -fc ${configuration}
                '';
              };
          };
      };
      paths = {
        gemini = {
          enable = true;
          wantedBy = [ "multi-user.target" ];
          pathConfig = {
            PathModified = [ config.fs.services.gemini.directory ];
          };
        };
      };
    };

    networking.firewall.allowedTCPPorts = [ 1965 ];
  };
}
