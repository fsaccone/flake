{
  config,
  pkgs,
  inputs,
  ...
}:
{
  modules = rec {
    aerc = {
      enable = true;
      email = {
        address = "francesco@francescosaccone.com";
        folders = {
          drafts = "Drafts";
          inbox = "INBOX";
          sent = "Sent";
          trash = "Trash";
        };
        imapHost = "glacier.mxrouting.net";
        imapTlsPort = 993;
        passwordCommand = ''
          ${pkgs.pass}/bin/pass show email/francesco/password
        '';
        realName = "Francesco Saccone";
        smtpHost = "glacier.mxrouting.net";
        smtpTlsPort = 465;
        username = "francesco%40francescosaccone.com";
      };
    };
    git = {
      enable = true;
      name = "Francesco Saccone";
      email = "francesco@francescosaccone.com";
    };
    gpg = {
      enable = true;
      primaryKey = {
        fingerprint = "2BE025D27B449E55B320C44209F39C4E70CB2C24";
        file = ./openpgp.asc;
      };
    };
    pass = {
      enable = true;
      passwordStoreDirectory = inputs.password-store;
    };
    newsraft = {
      enable = true;
      feeds = {
        "Italy" = [
          {
            name = "ANSA";
            url = "https://www.ansa.it/sito/ansait_rss.xml";
          }
          {
            name = "Fanpage";
            url = "https://www.fanpage.it/feed";
          }
          {
            name = "Libero Quotidiano";
            url = "https://www.liberoquotidiano.it/rss.xml";
          }
          {
            name = "Repubblica.it";
            url = "https://www.repubblica.it/rss/homepage/rss2.0.xml";
          }
        ];
        "Technology" = [
          {
            name = "Dark Reading";
            url = "https://www.darkreading.com/rss.xml";
          }
          {
            name = "The Hacker News";
            url = "https://feeds.feedburner.com/TheHackersNews";
          }
        ];
        "World" = [
          {
            name = "CNN International";
            url = "http://rss.cnn.com/rss/edition.rss";
          }
          {
            name = "The Washington Post World";
            url = "https://feeds.washingtonpost.com/rss/world";
          }
        ];
        "YouTube" =
          [
            {
              name = "Mental Outlaw";
              id = "UC7YOGHUfC1Tb6E4pudI9STA";
            }
            {
              name = "Linus Tech Tips";
              id = "UCXuqSBlHAE6Xw-yeJA0Tunw";
            }
            {
              name = "The Game Theorists";
              id = "UCo_IB5145EVNcf8hw1Kku7w";
            }
            {
              name = "Veritasium";
              id = "UCHnyfMqiRRG1u-2MsSQLbXA";
            }
          ]
          |> builtins.map (
            { name, id }:
            {
              inherit name;
              url = "https://youtube.com/feeds/videos.xml?channel_id=${id}";
            }
          );
      };
    };
    sway = {
      enable = true;
      bar = {
        enable = true;
      };
      fonts = {
        monospace = "IBM Plex Mono";
      };
    };
    vis = {
      enable = true;
    };
  };

  home.packages = with pkgs; [
    ardour
    dig
    helvum
    imv
    libreoffice
    librewolf
    mpv
    mupdf
    musescore
    nmap
    noice
    qjackctl
    tor-browser
  ];
}
