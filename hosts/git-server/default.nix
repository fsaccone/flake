{
  config,
  ...
}:
let
  mainServer = ../main-server;

  rootDomain = import "${mainServer}/domain.nix";
  gitDomain = "git.${rootDomain}";
in
{
  imports = [
    ./disk-config.nix
  ];

  modules = {
    bind = {
      enable = true;
      domain = rootDomain;
      records = import "${mainServer}/dns.nix" rootDomain;
    };
    darkhttpd = {
      enable = true;
      acme = {
        enable = true;
        email = "admin@${rootDomain}";
        domain = gitDomain;
      };
      tls = {
        enable = true;
        pemFiles =
          let
            inherit (config.modules.darkhttpd.acme) directory;
          in
          [
            "${directory}/${gitDomain}/fullchain.pem"
            "${directory}/${gitDomain}/privkey.pem"
          ];
      };
    };
    openssh.listen = {
      enable = true;
      port = 22;
      authorizedKeyFiles = rec {
        root = [
          "${mainServer}/ssh/francescosaccone.pub"
        ];
      };
    };
  };

  networking.domain = gitDomain;

  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
  };
}
