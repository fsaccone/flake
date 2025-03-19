{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{

  options.modules.agate = {
    enable = lib.mkOption {
      description = "Whether to enable Agate.";
      default = false;
      type = lib.types.bool;
    };
    directory = lib.mkOption {
      description = "The root directory to statically host.";
      default = "/var/gemini";
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

  config = lib.mkIf config.modules.agate.enable {
    users = {
      users = {
        agate = {
          hashedPassword = "!";
          isSystemUser = true;
          group = "agate";
          createHome = true;
          home = config.modules.agate.directory;
        };
      };
      groups = {
        agate = { };
      };
    };

    systemd = {
      services = {
        agate-setup = {
          enable = true;
          wantedBy = [ "multi-user.target" ];
          serviceConfig =
            let
              clean = pkgs.writeShellScriptBin "clean" ''
                ${pkgs.sbase}/bin/rm -rf \
                ${config.modules.agate.directory}/*

                ${pkgs.sbase}/bin/mkdir -p \
                ${config.modules.agate.directory}/.certificates
              '';
              symlinks =
                config.modules.agate.symlinks
                |> builtins.mapAttrs (
                  name: target: ''
                    ${pkgs.sbase}/bin/mkdir -p \
                    ${config.modules.agate.directory}/${builtins.dirOf name}

                    ${pkgs.sbase}/bin/ln -sf ${target} \
                    ${config.modules.agate.directory}/${name}
                  ''
                )
                |> builtins.attrValues
                |> builtins.concatStringsSep "\n"
                |> pkgs.writeShellScriptBin "symlinks";
              permissions = pkgs.writeShellScriptBin "permissions" ''
                ${pkgs.sbase}/bin/chmod -R g+rwx \
                ${config.modules.agate.directory}
              '';
            in
            {
              User = "root";
              Group = "root";
              Type = "oneshot";
              ExecStart = [
                "${clean}/bin/clean"
                "${symlinks}/bin/symlinks"
                "${permissions}/bin/permissions"
              ];
            };
        };
        agate =
          let
            inherit (config.modules.agate) preStart;
          in
          rec {
            enable = true;
            wantedBy = [ "multi-user.target" ];
            requires = [ "agate-setup.service" ];
            after = [ "network.target" ];
            path = preStart.packages;
            serviceConfig =
              let
                script = pkgs.writeShellScriptBin "script" ''
                  ${builtins.concatStringsSep "\n" preStart.scripts}

                  ${pkgs.agate}/bin/agate \
                    --content ${config.modules.agate.directory} \
                    --hostname ${config.networking.domain} \
                    --addr [::]:1965 \
                    --addr 0.0.0.0:1965
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
        agate = {
          enable = true;
          wantedBy = [ "multi-user.target" ];
          pathConfig = {
            PathModified = [
              config.modules.agate.directory
            ] ++ builtins.attrValues config.modules.agate.symlinks;
          };
        };
      };
    };

    networking.firewall.allowedTCPPorts = [ 1965 ];
  };
}
