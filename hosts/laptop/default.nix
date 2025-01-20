{
  lib,
  config,
  pkgs,
  ...
}:
{
  modules = {
    monero = {
      enable = true;
      mining = {
        enable = true;
        address =
          "44UAWDBRoxtXodXboy6LKEjokehoSiHwmNhgSYEvqzbiTmUnvMcNccFNsaAp7GCbDKhu62oeiEuj9HsPtwJi1p9V26ShoDh"
          |> lib.strings.trimWith {
            start = true;
            end = true;
          };
      };
    };
    networkmanager.enable = true;
    openssh = {
      enable = true;
      agent.enable = true;
    };
    pipewire.enable = true;
    searx = {
      enable = true;
      port = 8888;
      secretKey = builtins.getEnv "SEARX_SECRET_KEY";
    };
    sudo.enable = true;
    tor.enable = true;
    wayland.enable = true;
  };

  i18n.defaultLocale = "en_GB.UTF-8";
  time.timeZone = "Europe/Rome";

  boot.loader = {
    timeout = 1;
    systemd-boot = {
      enable = true;
      editor = false;
    };
  };

  security.pam.loginLimits = [
    {
      domain = "@realtime";
      type = "hard";
      item = "rtprio";
      value = 20;
    }
    {
      domain = "@realtime";
      type = "soft";
      item = "rtprio";
      value = 10;
    }
    {
      domain = "@audio";
      type = "-";
      item = "rtprio";
      value = 95;
    }
    {
      domain = "@audio";
      type = "-";
      item = "memlock";
      value = "unlimited";
    }
  ];
}
