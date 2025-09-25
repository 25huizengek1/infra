{
  pkgs,
  config,
  inputs,
  lib,
  ...
}:

let
  unixSocket = "/run/copyparty/party.sock";
  group = "anubis";
  username = "adm";
  copypartySource = pkgs.fetchFromGitHub {
    owner = "9001";
    repo = "copyparty";
    tag = "v${inputs.copyparty.packages.${pkgs.stdenv.system}.copyparty.version}";
    hash = "sha256-EHGinxdL7mo4wJv15ErRd3cebWN4TRjTrTrpbo9x6Xk=";
  };
  access.A = username;
  diamonds = lib.genAttrs' (lib.range 0 3) (num: (lib.nameValuePair "/diamond/${toString num}") {
    inherit access;
    path = "/srv/copyparty/diamond${toString num}";
    flags.daw = true;
  });
in
{
  services.copyparty = {
    enable = true;
    package = pkgs.copyparty.override {
      withTFTP = true;
    };
    settings = {
      name = "omeduoparty";
      i = "unix:770:${unixSocket},127.1";
      # Monokai
      theme = 2;
      ah-alg = "argon2";
      e2dsa = true;
      e2ts = true;
      ftp = 3921;
      tftp = 3969;
      # Enable zeroconf on tailscale
      z = true;
      z-on = "tailscale0";
      stats = true;
      spinner = ",padding:0;border-radius:9em;border:.2em solid #444;border-top:.2em solid #fc0";
      shr = "/shares";
      no-tarcmp = true;
      rss = true;
      # Disable 'send to server log'
      urlform = "get";
      usernames = true;

      # reverse proxy
      # Trust that nginx is configured correctly (if we move away from Cloudflare in the future we don't have to change this)
      xff-hdr = "x-forwarded-for";
      rproxy = 1;
    };
    accounts.${username}.passwordFile = config.sops.secrets.copyparty-adm-password-enc.path;
    user = group;
    inherit group;

    volumes = {
      "/" = {
        inherit access;
        path = "/root/private/fs";
      };
      "/muziek" = {
        inherit access;
        path = "/root/private/fs/muziek";
        flags = {
          xau = "j,c1,${copypartySource}/bin/hooks/podcast-normalizer.py";
        };
      };
      "/share" = {
        access = access // {
          G = "*";
        };
        path = "/root/private/share";
        flags = {
          lifetime = 60 * 60 * 24 * 365;
        };
      };
      "/tom" = {
        inherit access;
        path = "/srv/copyparty/tom";
      };
      "/diamond" = {
        inherit access;
        path = "/root/private/fs/rommel/ut/diamonds";
      };
      "/drop" = {
        access = access // {
          wG = "*";
        };
        path = "/srv/copyparty/fs/drop/";
        flags = {
          hardlinkonly = true;
          # adds some extra random stuff so the file is a little more
          # "secret"
          fka = 8;
          # sort uploads by date
          # this one seems buggy
          # rotf = "%Y-%m-%d";
          # no thumbnails
          dthumb = true;
          # 4 weeks
          lifetime = 60 * 60 * 24 * 7 * 4;
          # no more than 4096 MB over 15 minutes
          maxb = "4096m,600";
          # you do not get to choose the filename
          rand = true;
          # max 512 MB uploads
          sz = "0-512m";
          # always leave a little space
          df = "20g";
          # no XSS please
          nohtml = true;
        };
      };
    } // diamonds;
  };

  services.nginx.virtualHosts =
    let
      host = {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://unix://${config.services.anubis.instances.copyparty.settings.BIND}";
          proxyWebsockets = true;
          extraConfig = ''
            client_max_body_size 0;
            proxy_buffering off;
            proxy_request_buffering off;
            proxy_buffers 32 8k;
            proxy_buffer_size 16k;
            proxy_busy_buffers_size 24k;
          '';
        };
      };
    in
    {
      "party.vitune.app" = host;
      "fs.omeduostuurcentenneef.nl" = host;
    };

  systemd.sockets.copyparty = {
    before = [ "nginx.service" ];
    wantedBy = [ "sockets.target" ];
    socketConfig = {
      ListenStream = unixSocket;
      SocketUser = group;
      SocketGroup = group;
      SocketMode = "770";
    };
  };

  systemd.services.copyparty.requires = [ "copyparty.socket" ];

  services.anubis.instances.copyparty =
    let
      botPolicy = {
        bots = [
          {
            name = "telegram";
            user_agent_regex = "TelegramBot (like TwitterBot)";
            action = "ALLOW";
          }
          {
            name = "tailscale";
            remote_addresses = [ "100.64.0.0/16" ];
            action = "ALLOW";
          }
        ];
      };
    in

    {
      settings = {
        TARGET = "unix://${unixSocket}";
        METRICS_BIND = "127.0.0.1:16108"; # Prometheus can't scrape Unix sockets
        METRICS_BIND_NETWORK = "tcp";
        POLICY_FNAME = "${pkgs.writers.writeJSON "anubis-copyparty-bot-policy" botPolicy}"; # Why is this broken?
      };
    };

  services.prometheus.scrapeConfigs = [
    {
      job_name = "copyparty";
      metrics_path = "/.cpr/metrics/";
      basic_auth = {
        inherit username;
        password_file = config.sops.secrets.copyparty-adm-password.path;
      };
      static_configs = [
        {
          targets = [ "127.0.0.1:3923" ];
        }
      ];
    }
    {
      job_name = "copyparty-anubis";
      static_configs = [
        {
          targets = [ config.services.anubis.instances.copyparty.settings.METRICS_BIND ];
        }
      ];
    }
  ];

  sops.secrets.copyparty-adm-password = {
    format = "binary";
    sopsFile = ../secrets/copyparty-password.secret;

    owner = "prometheus";
    group = "prometheus";
    mode = "0660";
    restartUnits = [ "prometheus.service" ];
  };

  sops.secrets.copyparty-adm-password-enc = {
    format = "binary";
    sopsFile = ../secrets/copyparty-password.enc.secret;

    owner = group;
    inherit group;
    mode = "0660";
    restartUnits = [ "copyparty.service" ];
  };

  environment.systemPackages = [ pkgs.copyparty ];
}
