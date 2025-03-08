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
      script = lib.mkOption {
        description = "The script file to be run before starting the server";
        default = "${pkgs.writeShellScriptBin "script" ""}/bin/script";
        type = lib.types.uniq lib.types.path;
      };
      packages = lib.mkOption {
        description = "The list of packages required by the script";
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
                ${pkgs.coreutils}/bin/rm -rf \
                ${config.modules.agate.directory}/*

                ${pkgs.coreutils}/bin/mkdir -p \
                ${config.modules.agate.directory}/.certificates
              '';
              symlinks =
                config.modules.agate.symlinks
                |> builtins.mapAttrs (
                  name: target: ''
                    ${pkgs.coreutils}/bin/mkdir -p \
                    ${config.modules.agate.directory}/${builtins.dirOf name}

                    ${pkgs.coreutils}/bin/ln -sf ${target} \
                    ${config.modules.agate.directory}/${name}
                  ''
                )
                |> builtins.attrValues
                |> builtins.concatStringsSep "\n"
                |> pkgs.writeShellScriptBin "symlinks";
              permissions = pkgs.writeShellScriptBin "permissions" ''
                ${pkgs.coreutils}/bin/chmod -R g+rwx \
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
                ExecStartPre = preStart.script;
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
