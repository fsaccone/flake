domain:
let
  ttl = 3600;
in
(
  {
    "@" = import ./ip.nix;
    www = import ./ip.nix;

    git = import ../git-server/ip.nix;
    "www.git" = import ../git-server/ip.nix;

    mail = import ../mail-server/ip.nix;

    ns1 = import ../main-server/ip.nix;
    ns2 = import ../git-server/ip.nix;
  }
  |> builtins.mapAttrs (
    name:
    { ipv4, ipv6 }:
    [
      {
        inherit name;
        inherit ttl;
        class = "IN";
        type = "A";
        data = ipv4;
      }
      {
        inherit name;
        inherit ttl;
        class = "IN";
        type = "AAAA";
        data = ipv6;
      }
    ]
  )
  |> builtins.attrValues
  |> builtins.concatLists
)
++ [
  {
    name = "@";
    inherit ttl;
    class = "IN";
    type = "SOA";
    data = ''
      ns1.${domain}. admin.${domain}. (
        2025061801
        7200
        1800
        1209600
        3600
      )
    '';
  }
  {
    name = "@";
    inherit ttl;
    class = "IN";
    type = "NS";
    data = "ns1.${domain}.";
  }
  {
    name = "@";
    inherit ttl;
    class = "IN";
    type = "NS";
    data = "ns2.${domain}.";
  }
  {
    name = "@";
    inherit ttl;
    class = "IN";
    type = "MX";
    data = "0 mail.${domain}.";
  }
  {
    name = "@";
    inherit ttl;
    class = "IN";
    type = "TXT";
    data = "\"v=spf1 mx -all\"";
  }
  {
    name = "default._domainkey";
    inherit ttl;
    class = "IN";
    type = "TXT";
    data = ''
      (
        "v=DKIM1;"
        "k=rsa;"
        "p="
        ${import ./dkim.nix}
        ";"
      )
    '';
  }
  {
    name = "_dmarc";
    inherit ttl;
    class = "IN";
    type = "TXT";
    data = ''
      (
        "v=DMARC1;"
        "p=reject;"
        "pct=100;"
        "rua=mailto:postmaster@${domain};"
      )
    '';
  }
  {
    name = "mta-sts";
    inherit ttl;
    class = "IN";
    type = "CNAME";
    data = "mail.${domain}.";
  }
  {
    name = "_mta-sts";
    inherit ttl;
    class = "IN";
    type = "TXT";
    data = "\"v=STSv1; id=2025062201;\"";
  }
]
