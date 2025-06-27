{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  options.fs.security.ssh = {
    agent = {
      enable = lib.mkOption {
        description = "Whether to enable the SSH agent with OpenSSH.";
        default = false;
        type = lib.types.bool;
      };
    };
    listen = {
      enable = lib.mkOption {
        description = "Where to enable the SSH server with OpenSSH.";
        default = false;
        type = lib.types.bool;
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
      inherit (config.fs.security.ssh) agent listen;
    in
    {
      programs.ssh = lib.mkIf agent.enable {
        startAgent = true;
        package = pkgs.openssh;
      };

      services.openssh = lib.mkIf listen.enable {
        enable = true;
        ports = [ 22 ];
        settings = {
          PasswordAuthentication = false;
        };
      };

      networking.firewall.allowedTCPPorts = lib.mkIf listen.enable [ 22 ];

      users.users = lib.mkIf listen.enable (
        listen.authorizedKeyFiles
        |> builtins.mapAttrs (user: files: { openssh.authorizedKeys.keyFiles = files; })
      );

      services.sshguard = lib.mkIf listen.enable { enable = true; };
    };
}
