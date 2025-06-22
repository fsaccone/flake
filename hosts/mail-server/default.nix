{
  config,
  pkgs,
  inputs,
  ...
}:
let
  rootDomain = import ../main-server/domain.nix;
  domain = "mail.${rootDomain}";
in
{
  imports = [ ./disk-config.nix ];

  fs = {
    services = {
      email = {
        enable = true;
        host = {
          inherit domain;
          inherit (import ./ip.nix) ipv4 ipv6;
        };
        domain = rootDomain;
        tls =
          let
            inherit (config.fs.services.web.acme) directory;
          in
          {
            certificate = "${directory}/${domain}/fullchain.pem";
            key = "${directory}/${domain}/privkey.pem";
          };
        users = {
          abuse = {
            sshKeys = [ ../main-server/ssh/francescosaccone.pub ];
          };
          admin = {
            sshKeys = [ ../main-server/ssh/francescosaccone.pub ];
          };
          francesco = {
            sshKeys = [ ../main-server/ssh/francescosaccone.pub ];
          };
          postmaster = {
            sshKeys = [ ../main-server/ssh/francescosaccone.pub ];
          };
        };
      };
      web = {
        enable = true;
        acme = {
          enable = true;
          email = "francesco@${rootDomain}";
          inherit domain;
          extraDomains = [ "mta-sts.${rootDomain}" ];
        };
        tls = {
          enable = true;
          pemFiles =
            let
              inherit (config.fs.services.web.acme) directory;
            in
            [
              "${directory}/${domain}/fullchain.pem"
              "${directory}/${domain}/privkey.pem"
            ];
        };
        preStart.scripts =
          let
            inherit (config.fs.services.web) directory;
            mtaStsTxt = builtins.toFile "mta-sts.txt" ''
              version: STSv1
              mode: enforce
              max_age: 604800
              mx: ${domain}
            '';
          in
          [
            (pkgs.writeShellScript "create-mta-sts-txt" ''
              mkdir -p ${directory}/.well-known

              cp ${mtaStsTxt} ${directory}/.well-known/mta-sts.txt
            '')
          ];
      };
    };

    security.openssh.listen = {
      enable = true;
      authorizedKeyFiles = rec {
        root = [ ../main-server/ssh/francescosaccone.pub ];
      };
    };
  };

  networking.domain = domain;
}
