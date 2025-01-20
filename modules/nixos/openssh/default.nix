{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  options.modules.openssh = {
    enable = lib.mkEnableOption "Enables OpenSSH";
    agent.enable = lib.mkEnableOption "Enables OpenSSH agent";
    listen = {
      enable = lib.mkEnableOption "Listens for SSH connection requests at the given port.";
      port = lib.mkOption {
        type = lib.types.uniq lib.types.int;
        description = "The port which listens for the SSH connection requests.";
      };
      authorizedKeyFiles = lib.mkOption {
        type = lib.types.listOf lib.types.path |> lib.types.attrsOf;
        description = "For each user, a list of public SSH key files that are authorized to connect.";
      };
    };
  };

  config = lib.mkIf config.modules.openssh.enable {
    services.openssh =
      if config.modules.openssh.listen.enable then
        {
          enable = true;
          ports = [
            config.modules.openssh.listen.port
          ];
          settings = {
            PasswordAuthentication = false;
            PermitRootLogin = "no";
          };
        }
      else
        {
          enable = true;
        };

    networking.firewall.allowedTCPPorts =
      if config.modules.openssh.listen.enable then
        [
          config.modules.openssh.listen.port
        ]
      else
        [ ];

    users.users =
      if config.modules.openssh.listen.enable then
        config.modules.openssh.listen.authorizedKeyFiles
        |> builtins.mapAttrs (
          user: files: {
            openssh.authorizedKeys.keyFiles = files;
          }
        )
      else
        { };

    programs.ssh =
      if config.modules.openssh.agent.enable then
        {
          startAgent = true;
          package = pkgs.openssh;
        }
      else
        { };
  };
}
