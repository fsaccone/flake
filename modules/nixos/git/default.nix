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
    ./stagit
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
              script =
                config.modules.git.repositories
                |> builtins.mapAttrs (
                  name:
                  {
                    description,
                    owner,
                    baseUrl,
                  }:
                  ''
                    ${pkgs.git}/bin/git init -q --bare -b master \
                    ${config.modules.git.directory}/${name}

                    ${pkgs.coreutils}/bin/echo "${description}" > \
                    ${config.modules.git.directory}/${name}/description

                    ${pkgs.coreutils}/bin/echo "${owner}" > \
                    ${config.modules.git.directory}/${name}/owner

                    ${pkgs.coreutils}/bin/echo "git://${baseUrl}/${name}" > \
                    ${config.modules.git.directory}/${name}/url
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
