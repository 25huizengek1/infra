let
  redisSocket = "/run/redis-anubis/redis.sock";
  difficulty = 8;
in
{
  systemd.services.nginx.serviceConfig.SupplementaryGroups = [ "anubis" ];
  services.anubis.defaultOptions = {
    settings = {
      DIFFICULTY = difficulty;
      SERVE_ROBOTS_TXT = true;
      WEBMASTER_EMAIL = "anubis@bartoostveen.nl";
    };
    policy.settings = {
      store = {
        backend = "valkey";
        parameters.url = "unix://${redisSocket}";
      };
      action = "CHALLENGE";
      challenge = {
        inherit difficulty;
        algorithm = "fast";
      };
    };
  };

  services.redis.servers.anubis = {
    enable = true;
    user = "anubis";
    unixSocket = redisSocket;
    unixSocketPerm = 770;
  };
}
