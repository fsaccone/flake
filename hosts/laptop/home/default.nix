{
  config,
  pkgs,
  inputs,
  ...
}:
let
  emailDomain = import ../../root/domain.nix;
in
{
  fs.programs = rec {
    aerc = {
      enable = true;
      accounts =
        builtins.map
          (
            { username, realName }:
            {
              inherit username realName;
              address = "${username}@${emailDomain}";
              smtpHost = "mail.${emailDomain}";
            }
          )
          [
            ({
              realName = "Abuse Report";
              username = "abuse";
            })
            ({
              realName = "Admin";
              username = "admin";
            })
            ({
              realName = "Francesco Saccone";
              username = "francesco";
            })
            ({
              realName = "Postmaster";
              username = "postmaster";
            })
          ];
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
        file = inputs.openpgp-key;
      };
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
      sizeMultiplier = 1.38;
      bar = {
        enable = true;
      };
      fonts = {
        monospace = "IBM Plex Mono";
      };
      preferDarkTheme = true;
      backgroundImage = ./background.png;
      cursor = {
        name = "graphite-dark-nord";
        package = pkgs.graphite-cursors;
      };
      colors =
        let
          colors = import ./colors.nix;
        in
        {
          inherit (colors)
            background
            foreground
            darkRed
            green
            red
            ;
        };
    };
    vis = {
      enable = true;
    };
  };

  home = {
    file.".mkshrc".text = ''
      PS1="${"$"}{USER}@$(hostname):\${"$"}{PWD} $ "
    '';
    packages = [
      pkgs.alsa-utils
      pkgs.ffmpeg
      pkgs.dig
      pkgs.exiftool
      pkgs.gimp
      pkgs.helvum
      pkgs.imv
      pkgs.keepassxc
      pkgs.kmon
      pkgs.libressl
      pkgs.librewolf
      pkgs.lilypond
      pkgs.man-pages-posix
      pkgs.md2pdf
      pkgs.mpv
      pkgs.nixos-anywhere
      pkgs.nmap
      pkgs.nnn
      pkgs.qrcode
      pkgs.sent
      pkgs.shotcut
      pkgs.timidity
      pkgs.unzip
      pkgs.zathura
    ];
  };
}
