{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  options.modules.openssh = {
    agent = {
      enable = lib.mkOption {
        description = "Whether to enable the OpenSSH agent.";
        default = false;
        type = lib.types.bool;
      };
    };
    listen = {
      enable = lib.mkOption {
        description = ''
          Where to listen for SSH connection requests at the given port.
        '';
        default = false;
        type = lib.types.bool;
      };
      port = lib.mkOption {
        description = ''
          The port which listens for the SSH connection requests.
        '';
        type = lib.types.uniq lib.types.int;
      };
      authorizedKeyFiles = lib.mkOption {
        description = ''
          For each user, a list of public SSH key files that are authorized to
          connect.
        '';
        type = lib.types.listOf lib.types.path |> lib.types.attrsOf;
      };
    };
  };

  config =
    let
      inherit (config.modules.openssh)
        agent
        listen
        ;
    in
    {
      programs.ssh = lib.mkIf agent.enable {
        startAgent = true;
        package = pkgs.openssh;
      };

      services.openssh = lib.mkIf listen.enable {
        enable = true;
        ports = [
          listen.port
        ];
        settings = {
          PasswordAuthentication = false;
        };
      };

      networking.firewall.allowedTCPPorts = lib.mkIf listen.enable [
        listen.port
      ];

      users.users = lib.mkIf listen.enable (
        listen.authorizedKeyFiles
        |> builtins.mapAttrs (
          user: files: {
            openssh.authorizedKeys.keyFiles = files;
          }
        )
      );

      services.sshguard = lib.mkIf listen.enable {
        enable = true;
      };
    };
}
