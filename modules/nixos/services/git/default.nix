{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  imports = [ ./daemon ];

  options.fs.services.git = {
    enable = lib.mkOption {
      description = "Whether to set up a Git server.";
      default = false;
      type = lib.types.bool;
    };
    user = lib.mkOption {
      description = ''
        The user owning the directory containing the bare repositories.
      '';
      default = "git";
      readOnly = true;
      type = lib.types.uniq lib.types.str;
    };
    group = lib.mkOption {
      description = ''
        The group owning the directory containing the bare repositories.
      '';
      default = "git";
      readOnly = true;
      type = lib.types.uniq lib.types.str;
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
            isPrivate = lib.mkOption {
              description = ''
                Whether the repository is private: if this is false, a
                git-daemon-export-ok file is created in its directory.
              '';
              type = lib.types.uniq lib.types.bool;
            };
            additionalFiles = lib.mkOption {
              description = ''
                For each additional file to add to the repository directory,
                its content.
              '';
              default = { };
              type = lib.types.attrsOf lib.types.str;
            };
            hooks = {
              preReceive = lib.mkOption {
                description = "The pre-receive hook script.";
                default = pkgs.writeShellScript "pre-receive.sh" "";
                type = lib.types.uniq lib.types.path;
              };
              update = lib.mkOption {
                description = "The update hook script.";
                default = pkgs.writeShellScript "update.sh" "";
                type = lib.types.uniq lib.types.path;
              };
              postReceive = lib.mkOption {
                description = "The post-receive hook script.";
                default = pkgs.writeShellScript "post-receive.sh" "";
                type = lib.types.uniq lib.types.path;
              };
            };
          };
        }
        |> lib.types.attrsOf;
    };
  };

  config = lib.mkIf config.fs.services.git.enable {
    users = {
      users = {
        ${config.fs.services.git.user} = {
          hashedPassword = "!";
          isSystemUser = true;
          inherit (config.fs.services.git) group;
          createHome = true;
          home = config.fs.services.git.directory;
          shell = "${pkgs.git}/bin/git-shell";
        };
      };
      groups = {
        ${config.fs.services.git.group} = { };
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
              inherit (config.fs.services.git) repositories directory;
            in
            {
              User = config.fs.services.git.user;
              Group = config.fs.services.git.group;
              Type = "oneshot";
              ExecStart =
                repositories
                |> builtins.mapAttrs (
                  name:
                  {
                    isPrivate,
                    additionalFiles,
                    hooks,
                  }:
                  ''
                    ${pkgs.git}/bin/git init -q --bare -b master \
                    ${directory}/${name}

                    ${
                      (
                        if !isPrivate then
                          ''
                            touch ${directory}/${name}/git-daemon-export-ok
                          ''
                        else
                          ""
                      )
                    }

                    ${
                      (
                        additionalFiles
                        |> builtins.mapAttrs (
                          fileName: content: ''
                            echo "${content}" > \
                            ${directory}/${name}/${fileName}
                          ''
                        )
                        |> builtins.attrValues
                        |> builtins.concatStringsSep "\n"
                      )
                    }

                    mkdir -p ${directory}/${name}/hooks

                    ln -sf ${hooks.preReceive} \
                    ${directory}/${name}/hooks/pre-receive

                    ln -sf ${hooks.update} \
                    ${directory}/${name}/hooks/update

                    ln -sf ${hooks.postReceive} \
                    ${directory}/${name}/hooks/post-receive
                  ''
                )
                |> builtins.attrValues
                |> builtins.concatStringsSep "\n"
                |> pkgs.writeShellScript "git.sh";
            };
        };
      };
    };
  };
}
