{
  services.prometheus.exporters = {
    nginx.enable = true;
    systemd.enable = true;
    node.enable = true;
  };
}
