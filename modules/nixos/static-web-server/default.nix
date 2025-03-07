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

  options.modules.staticWebServer = {
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
    symlinks = lib.mkOption {
      description = ''
        For each symlink name, which will be created in the root directory, its
        target.
      '';
      default = { };
      type = lib.types.attrsOf lib.types.path;
    };
  };

  config = lib.mkIf config.modules.staticWebServer.enable {
    users = {
      users = {
        static-web-server = {
          hashedPassword = "!";
          isSystemUser = true;
          group = "www";
          createHome = true;
          home = config.modules.staticWebServer.directory;
        };
      };
      groups = {
        www = { };
      };
    };

    systemd = {
      services = {
        static-web-server-setup = {
          enable = true;
          wantedBy = [ "multi-user.target" ];
          serviceConfig =
            let
              permissions = pkgs.writeShellScriptBin "permissions" ''
                ${pkgs.coreutils}/bin/chmod -R g+rwx \
                ${config.modules.staticWebServer.directory}
              '';
              clean = pkgs.writeShellScriptBin "clean" ''
                ${pkgs.coreutils}/bin/rm -rf \
                ${config.modules.staticWebServer.directory}/*
              '';
              symlinks =
                config.modules.staticWebServer.symlinks
                |> builtins.mapAttrs (
                  name: target:
                  let
                    inherit (config.modules.staticWebServer) directory;
                  in
                  ''
                    ${pkgs.coreutils}/bin/mkdir -p \
                    ${directory}/${builtins.dirOf name}

                    ${pkgs.coreutils}/bin/ln -sf ${target} \
                    ${directory}/${name}

                    ${pkgs.coreutils}/bin/chown -Rh static-web-server:www \
                    ${directory}/${name}
                  ''
                )
                |> builtins.attrValues
                |> builtins.concatStringsSep "\n"
                |> pkgs.writeShellScriptBin "symlinks";
            in
            {
              User = "root";
              Group = "root";
              Type = "oneshot";
              ExecStart = [
                "${permissions}/bin/permissions"
                "${clean}/bin/clean"
                "${symlinks}/bin/symlinks"
              ];
            };
        };
        static-web-server = rec {
          enable = true;
          wantedBy = [ "multi-user.target" ];
          requires = [
            "static-web-server-setup.service"
          ];
          after = [
            "static-web-server-setup.service"
            "network.target"
          ];
          serviceConfig =
            let
              inherit (config.modules.staticWebServer) tls;
              script = pkgs.writeShellScriptBin "script" ''
                ${pkgs.static-web-server}/bin/static-web-server \
                  --port 80 \
                  --http2 false \
                  --root ${config.modules.staticWebServer.directory} \
                  --index-files index.html \
                  --ignore-hidden-files false \
                  ${if tls.enable then "--https-redirect" else ";"}
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
        static-web-server = {
          enable = true;
          wantedBy = [ "multi-user.target" ];
          pathConfig = {
            PathModified = [
              config.modules.staticWebServer.directory
            ] ++ builtins.attrValues config.modules.staticWebServer.symlinks;
          };
        };
      };
    };

    networking.firewall.allowedTCPPorts = [ 80 ];
  };
}
