{
  config,
  pkgs,
  inputs,
  ...
}:
let
  rootDomain = import ../hades/domain.nix;
  domain = "mail.${rootDomain}";
in
{
  imports = [ ./disk-config.nix ];

  fs = {
    services = {
      dns = {
        enable = true;
        domain = rootDomain;
        isSecondary = true;
        primaryIp = (import ../hades/ip.nix).ipv6;
        records = import ../hades/dns.nix rootDomain;
      };
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
            sshKeys = [ ../hades/ssh/francescosaccone.pub ];
          };
          admin = {
            sshKeys = [ ../hades/ssh/francescosaccone.pub ];
          };
          francesco = {
            sshKeys = [ ../hades/ssh/francescosaccone.pub ];
          };
          postmaster = {
            sshKeys = [ ../hades/ssh/francescosaccone.pub ];
          };
        };
      };
      web = {
        enable = true;
        acme = {
          enable = true;
          email = "admin@${rootDomain}";
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
            (pkgs.writeShellScript "create-mta-sts-txt.sh" ''
              mkdir -p ${directory}/.well-known

              cp ${mtaStsTxt} ${directory}/.well-known/mta-sts.txt
            '')
          ];
      };
    };

    security.ssh.listen = {
      enable = true;
      authorizedKeyFiles = rec {
        root = [ ../hades/ssh/francescosaccone.pub ];
      };
    };
  };

  networking.domain = domain;
}
