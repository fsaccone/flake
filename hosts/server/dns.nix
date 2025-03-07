domain:
let
  ttl = 3600;
in
(
  rec {
    "@" = www;
    ns1 = www;
    www = {
      ipv4 = "193.108.52.52";
      ipv6 = "2001:1600:13:101::16e3";
    };
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
    type = "MX";
    data = "10 glacier.mxrouting.net.";
  }
  {
    name = "@";
    inherit ttl;
    class = "IN";
    type = "MX";
    data = "20 glacier-relay.mxrouting.net.";
  }
  {
    name = "@";
    inherit ttl;
    class = "IN";
    type = "TXT";
    data = "\"v=spf1 include:mxroute.com -all\"";
  }
  {
    name = "x._domainkey";
    inherit ttl;
    class = "IN";
    type = "TXT";
    data =
      let
        key =
          [
            "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEArLEUDzMAOlQaKm7Ov5hJ"
            "4vgETJN7vMbwb2qr4mUI5nU6zpfH/609NV63mZfxTlqOKAan0zee9Yizrc1UgnGE"
            "8Y8Hh34vwPo2D2rMA0xuhyDiOVoLvw7AQIp38WeT7Gj7idm3lPy0iDgYIxIZaoQQ"
            "9u4GW3XnZmhbHUGURilSDp0kDW6m1i+fPxD0XEyrYLzwYr85KKeWKZJEn6qRk5og"
            "d9n7p7xJa24gvNpMSZTZHvSG9C0EMnorLqlHw5i3HMA99IO6RjZK3Ntoo5YktTbu"
            "q9NP+ecpDt3xHC7HOWAGetL8tPC7HZbOF+SCcFXp4LGZpruAEBnzbAbimz0B1va5"
            "LQIDAQAB"
          ]
          |> builtins.map (s: "\"${s}\"")
          |> builtins.concatStringsSep "\n";
      in
      ''
        (
          "v=DKIM1;"
          "k=rsa;"
          "p="
          ${key}
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
        "rua=mailto:francesco@${domain};";
      )
    '';
  }
]
