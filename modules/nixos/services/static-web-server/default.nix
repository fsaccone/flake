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

  options.fs.services.static-web-server = {
    enable = lib.mkOption {
      description = "Whether to enable Static Web Server.";
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
      default = "static-web-server";
      type = lib.types.uniq lib.types.str;
    };
    group = lib.mkOption {
      description = "The group who owns the directory.";
      default = "static-web-server";
      type = lib.types.uniq lib.types.str;
    };
    redirectWwwToNonWww = {
      enable = lib.mkOption {
        description = ''
          Whether to redirect requests to the canonical non-www domain.
        '';
        default = false;
        type = lib.types.bool;
      };
      domain = lib.mkOption {
        description = "The canonical domain.";
        type = lib.types.uniq lib.types.str;
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

  config = lib.mkIf config.fs.services.static-web-server.enable {
    users = {
      users = {
        static-web-server = {
          hashedPassword = "!";
          isNormalUser = true;
          group = "static-web-server";
          createHome = false;
        };
      };
      groups = {
        static-web-server = { };
      };
    };

    systemd = {
      services = {
        static-web-server =
          let
            inherit (config.fs.services.static-web-server) preStart;
          in
          rec {
            enable = true;
            wantedBy = [ "multi-user.target" ];
            after = [ "network.target" ];
            path = preStart.packages;
            serviceConfig =
              let
                inherit (config.fs.services.static-web-server)
                  directory
                  group
                  redirectWwwToNonWww
                  tls
                  user
                  ;

                preStartScriptsCall =
                  preStart.scripts
                  |> builtins.map (s: "${pkgs.su}/bin/su -m -c ${s} ${user}")
                  |> builtins.concatStringsSep "\n";

                redirectConfig =
                  let
                    inherit (redirectWwwToNonWww) domain;
                    protocol = if tls.enable then "https" else "http";
                  in
                  ''
                    [advanced]
                    [[advanced.redirects]]
                    host = "www.${domain}"
                    source = "{/[!.]*,/}"
                    destination = "${protocol}://${domain}$1"
                    kind = 301
                  '';

                configuration = builtins.toFile "static-web-server.toml" ''
                  [general]
                  port = 80
                  root = "${directory}"

                  cache-control-headers = true

                  compression = true
                  compression-level = "default"
                  compression-static = true

                  security-headers = true

                  directory-listing = false

                  redirect-trailing-slash = true

                  health = false

                  index-files = "index.html"

                  ${if redirectWwwToNonWww.enable then redirectConfig else ""}
                '';

                script = pkgs.writeShellScriptBin "static-web-server" ''
                  mkdir -p ${directory}

                  chown -R ${user}:${group} ${directory}
                  chmod -R 744 ${directory}

                  ${preStartScriptsCall}

                  chmod -R u+rwx ${directory}
                  chmod -R a+r ${directory}

                  ${pkgs.static-web-server}/bin/static-web-server \
                    --config-file ${configuration}
                '';
              in
              {
                User = "root";
                Group = "root";
                Restart = "on-failure";
                Type = "simple";
                ExecStart = "${script}/bin/static-web-server";
              };
          };
      };
      paths = {
        static-web-server = {
          enable = true;
          wantedBy = [ "multi-user.target" ];
          pathConfig = {
            PathModified = [ config.fs.services.static-web-server.directory ];
          };
        };
      };
    };

    networking.firewall.allowedTCPPorts = [ 80 ];
  };
}
