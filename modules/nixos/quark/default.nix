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

  options.modules.quark = {
    enable = lib.mkOption {
      description = "Whether to enable Quark web server.";
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

  config = lib.mkIf config.modules.quark.enable {
    users = {
      users = {
        quark = {
          hashedPassword = "!";
          isSystemUser = true;
          group = "quark";
          createHome = true;
          home = config.modules.quark.directory;
        };
      };
      groups = {
        quark = { };
      };
    };

    systemd = {
      services = {
        quark-setup = {
          enable = true;
          wantedBy = [ "multi-user.target" ];
          serviceConfig =
            let
              permissions = pkgs.writeShellScriptBin "permissions" ''
                ${pkgs.sbase}/bin/chmod -R g+rwx \
                ${config.modules.quark.directory}
              '';
              clean = pkgs.writeShellScriptBin "clean" ''
                ${pkgs.sbase}/bin/rm -rf \
                ${config.modules.quark.directory}/*
              '';
              symlinks =
                config.modules.quark.symlinks
                |> builtins.mapAttrs (
                  name: target:
                  let
                    inherit (config.modules.quark) directory;
                  in
                  ''
                    ${pkgs.sbase}/bin/mkdir -p \
                    ${directory}/${builtins.dirOf name}

                    ${pkgs.sbase}/bin/ln -sf ${target} \
                    ${directory}/${name}

                    ${pkgs.sbase}/bin/chown -Rh darkhttpd:darkhttpd \
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
        quark =
          let
            inherit (config.modules.quark) preStart;
          in
          rec {
            enable = true;
            wantedBy = [ "multi-user.target" ];
            requires = [ "quark-setup.service" ];
            after = [ "network.target" ];
            path = preStart.packages;
            serviceConfig =
              let
                inherit (config.modules.quark) customHeaderScripts tls;
                script = pkgs.writeShellScriptBin "script" ''
                  ${builtins.concatStringsSep "\n" preStart.scripts}

                  ${pkgs.quark}/bin/quark \
                    -p 80 \
                    -d ${config.modules.quark.directory} \
                    -u quark \
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
            PathModified = [
              config.modules.quark.directory
            ] ++ builtins.attrValues config.modules.quark.symlinks;
          };
        };
      };
    };

    networking.firewall.allowedTCPPorts = [ 80 ];
  };
}
