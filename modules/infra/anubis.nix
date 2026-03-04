let
  redisSocket = "/run/redis-anubis/redis.sock";
in
{
  systemd.services.nginx.serviceConfig.SupplementaryGroups = [ "anubis" ];
  services.anubis.defaultOptions = {
    settings = {
      DIFFICULTY = 4;
      SERVE_ROBOTS_TXT = true;
      WEBMASTER_EMAIL = "anubis@bartoostveen.nl";
    };
    policy = {
      settings.store = {
        backend = "valkey";
        parameters.url = "unix://${redisSocket}";
      };
      extraBots = [
        {
          name = "telegram";
          user_agent_regex = "TelegramBot \\(like TwitterBot\\)";
          action = "ALLOW";
        }
        {
          name = "wireguard";
          remote_addresses = [ "10.0.0.0/24" ];
          action = "ALLOW";
        }
      ];
    };
  };

  services.redis.servers.anubis = {
    enable = true;
    user = "anubis";
    unixSocket = redisSocket;
    unixSocketPerm = 770;
  };
}
