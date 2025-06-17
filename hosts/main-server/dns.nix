domain:
let
  ttl = 3600;
in
(
  let
    main = {
      ipv4 = "193.108.52.52";
      ipv6 = "2001:1600:13:101::16e3";
    };
    git = {
      ipv4 = "83.228.193.236";
      ipv6 = "2001:1600:13:101::1a12";
    };
  in
  {
    "@" = main;
    www = main;

    inherit git;
    "www.git" = git;

    mail = {
      ipv4 = "83.228.199.68";
      ipv6 = "2001:1600:13:101::aa0";
    };

    ns1 = main;
    ns2 = git;
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
      ns1.${domain}. francesco.${domain}. (
        2021090101
        900
        900
        2592000
        900
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
        "rua=mailto:francesco@${domain};"
      )
    '';
  }
]
