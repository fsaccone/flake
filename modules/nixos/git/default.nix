{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  imports = [
    ./daemon
  ];

  options.modules.git = {
    enable = lib.mkOption {
      description = "Whether to set up a Git server.";
      default = false;
      type = lib.types.bool;
    };
    directory = lib.mkOption {
      description = ''
        The directory where specified bare repositories are created.
      '';
      default = "/srv/git";
      readOnly = true;
      type = lib.types.uniq lib.types.path;
    };
    repositories = lib.mkOption {
      description = "For each bare repository name, its configuration.";
      default = { };
      type =
        lib.types.submodule {
          options = {
            description = lib.mkOption {
              description = "The description.";
              type = lib.types.uniq lib.types.str;
            };
            owner = lib.mkOption {
              description = "The owner.";
              type = lib.types.uniq lib.types.str;
            };
            baseUrl = lib.mkOption {
              description = ''
                The base URL used to clone the repository through the Git
                protocol.
              '';
              type = lib.types.uniq lib.types.str;
            };
            hooks = {
              preReceive = lib.mkOption {
                description = "The pre-receive hook script.";
                default = "${pkgs.writeShellScriptBin "script" ""}/bin/script";
                type = lib.types.uniq lib.types.path;
              };
              update = lib.mkOption {
                description = "The update hook script.";
                default = "${pkgs.writeShellScriptBin "script" ""}/bin/script";
                type = lib.types.uniq lib.types.path;
              };
              postReceive = lib.mkOption {
                description = "The post-receive hook script.";
                default = "${pkgs.writeShellScriptBin "script" ""}/bin/script";
                type = lib.types.uniq lib.types.path;
              };
            };
          };
        }
        |> lib.types.attrsOf;
    };
  };

  config = lib.mkIf config.modules.git.enable {
    users = {
      users = {
        git = {
          hashedPassword = "!";
          isSystemUser = true;
          group = "git";
          createHome = true;
          home = config.modules.git.directory;
          shell = "${pkgs.git}/bin/git-shell";
        };
      };
      groups = {
        git = { };
      };
    };

    programs.git = {
      enable = true;
      package = pkgs.git;
    };

    systemd = {
      services = {
        git-repositories = {
          enable = true;
          wantedBy = [ "multi-user.target" ];
          serviceConfig =
            let
              inherit (config.modules.git) repositories directory;
              script =
                repositories
                |> builtins.mapAttrs (
                  name:
                  {
                    description,
                    owner,
                    baseUrl,
                    hooks,
                  }:
                  ''
                    ${pkgs.git}/bin/git init -q --bare -b master \
                    ${directory}/${name}

                    ${pkgs.sbase}/bin/echo "${description}" > \
                    ${directory}/${name}/description

                    ${pkgs.sbase}/bin/echo "${owner}" > \
                    ${directory}/${name}/owner

                    ${pkgs.sbase}/bin/echo "git://${baseUrl}/${name}" > \
                    ${directory}/${name}/url

                    ${pkgs.sbase}/bin/mkdir -p ${directory}/${name}/hooks

                    ${pkgs.sbase}/bin/ln -sf ${hooks.preReceive} \
                    ${directory}/${name}/hooks/pre-receive

                    ${pkgs.sbase}/bin/ln -sf ${hooks.update} \
                    ${directory}/${name}/hooks/update

                    ${pkgs.sbase}/bin/ln -sf ${hooks.postReceive} \
                    ${directory}/${name}/hooks/post-receive
                  ''
                )
                |> builtins.attrValues
                |> builtins.concatStringsSep "\n"
                |> pkgs.writeShellScriptBin "script";
            in
            {
              User = "git";
              Group = "git";
              Type = "oneshot";
              ExecStart = "${script}/bin/script";
            };
        };
      };
    };
  };
}
