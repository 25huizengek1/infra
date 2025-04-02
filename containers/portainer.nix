{ ... }: {
  virtualisation.oci-containers.containers.portainer = {
    image = "portainer/portainer-ce";
    volumes = [
      "portainer_data:/data"
      "/run/podman/podman.sock:/var/run/docker.sock"
    ];
    ports = [ "8000:8000" "9443:9443" ];
    autoStart = true;
    privileged = true;
  };
}