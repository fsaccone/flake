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

  options.modules.darkhttpd = {
    enable = lib.mkOption {
      description = "Whether to enable Darkhttpd.";
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
    customHeaderScripts = lib.mkOption {
      description = ''
        For each custom HTTP header name, the shell script to get its value.
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

  config = lib.mkIf config.modules.darkhttpd.enable {
    users = {
      users = {
        darkhttpd = {
          hashedPassword = "!";
          isSystemUser = true;
          group = "darkhttpd";
          createHome = true;
          home = config.modules.darkhttpd.directory;
        };
      };
      groups = {
        darkhttpd = { };
      };
    };

    systemd = {
      services = {
        darkhttpd-setup = {
          enable = true;
          wantedBy = [ "multi-user.target" ];
          serviceConfig =
            let
              permissions = pkgs.writeShellScriptBin "permissions" ''
                ${pkgs.coreutils}/bin/chmod -R g+rwx \
                ${config.modules.darkhttpd.directory}
              '';
              clean = pkgs.writeShellScriptBin "clean" ''
                ${pkgs.coreutils}/bin/rm -rf \
                ${config.modules.darkhttpd.directory}/*
              '';
              symlinks =
                config.modules.darkhttpd.symlinks
                |> builtins.mapAttrs (
                  name: target:
                  let
                    inherit (config.modules.darkhttpd) directory;
                  in
                  ''
                    ${pkgs.coreutils}/bin/mkdir -p \
                    ${directory}/${builtins.dirOf name}

                    ${pkgs.coreutils}/bin/ln -sf ${target} \
                    ${directory}/${name}

                    ${pkgs.coreutils}/bin/chown -Rh darkhttpd:darkhttpd \
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
        darkhttpd =
          let
            inherit (config.modules.darkhttpd) preStart;
          in
          rec {
            enable = true;
            wantedBy = [ "multi-user.target" ];
            requires = [ "darkhttpd-setup.service" ];
            after = [ "network.target" ];
            path = preStart.packages;
            serviceConfig =
              let
                inherit (config.modules.darkhttpd) customHeaderScripts tls;
                customHeaderFlags =
                  customHeaderScripts
                  |> builtins.mapAttrs (name: script: "${name}: $(${script})")
                  |> builtins.attrValues
                  |> builtins.map (arg: "--header \"${arg}\"")
                  |> builtins.concatStringsSep " ";

                script = pkgs.writeShellScriptBin "script" ''
                  ${preStart.script}

                  ${pkgs.darkhttpd}/bin/darkhttpd \
                    ${config.modules.darkhttpd.directory} \
                    --port 80 \
                    --index index.html \
                    --no-listing \
                    --uid darkhttpd \
                    --gid darkhttpd \
                    --no-server-id \
                    --ipv6 ${if tls.enable then "--forward-https" else ""} \
                    ${customHeaderFlags}
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
            PathModified = [
              config.modules.darkhttpd.directory
            ] ++ builtins.attrValues config.modules.darkhttpd.symlinks;
          };
        };
      };
    };

    networking.firewall.allowedTCPPorts = [ 80 ];
  };
}
