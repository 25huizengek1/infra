{
  services.fail2ban = {
    enable = true;
    ignoreIP = [ "10.0.0.0/24" ];
  };

  services.prometheus.exporters.fail2ban = {
    enable = true;
    exitOnError = true;
  };
}
