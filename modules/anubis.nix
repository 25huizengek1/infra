{ const, ... }:

let
  redisSocket = "/run/redis-anubis/redis.sock";
in
{
  systemd.services.nginx.serviceConfig.SupplementaryGroups = [ "anubis" ];
  services.anubis.defaultOptions.settings = {
    DIFFICULTY = 4;
    SERVE_ROBOTS_TXT = true;
    WEBMASTER_EMAIL = "anubis@${const.domain}";
  };

  services.anubis.defaultOptions.botPolicy = {
    store = {
      backend = "valkey";
      parameters.url = "redis://unix://${redisSocket}";
    };
  };

  services.redis.servers.anubis = {
    enable = true;
    user = "anubis";
    unixSocket = redisSocket;
    unixSocketPerm = 770;
  };
}
