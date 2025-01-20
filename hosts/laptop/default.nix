{
  config,
  pkgs,
  ...
}:
{
  modules = {
    monero.enable = true;
    networkmanager.enable = true;
    openssh = {
      enable = true;
      agent.enable = true;
    };
    pipewire.enable = true;
    searx.enable = true;
    sudo.enable = true;
    sway.enable = true;
    tor.enable = true;
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
