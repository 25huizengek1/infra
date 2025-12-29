let
  port = 19443;
in
{
  virtualisation.oci-containers.containers.portainer = {
    image = "portainer/portainer-ce";
    volumes = [
      "portainer_data:/data"
      "/run/podman/podman.sock:/var/run/docker.sock"
    ];
    ports = [
      "127.0.0.1:${toString port}:9443"
    ];
    autoStart = true;
    privileged = true;
  };

  services.nginx.virtualHosts."portainer.vitune.app" = {
    forceSSL = true;
    enableACME = true;
    locations."/" = {
      proxyPass = "https://127.0.0.1:${toString port}";
    };
  };
}
