{ config, lib, ... }:

let
  domain = (import ../const.nix).domain;
  port = 8080;
  master = {
    jenkins-master = {
      image = "jenkins/jenkins:2.492.3-jdk17";
      hostname = "jenkins-master";
      volumes = [
        "jenkins-data:/var/jenkins_home"
        "jenkins-docker-certs:/certs/client:ro"
        "/run/podman/podman.sock:/var/run/docker.sock"
        "${config.sops.secrets.id_jenkins_agent.path}:/secrets/id_jenkins_agent"
      ];
      ports = [
        "127.0.0.1:${toString port}:8080"
        "127.0.0.1:50000:50000"
      ];
      environment = {
        "DOCKER_HOST" = "unix:///var/run/docker.sock";
        "DOCKER_CERT_PATH" = "/certs/client";
        "DOCKER_TLS_VERIFY" = "1";
      };
      autoStart = true;
    };
  };
  slaveConfig = hostname: {
    image = "jenkins/ssh-agent:alpine-jdk17";
    inherit hostname;
    environment = {
      "JENKINS_AGENT_SSH_PUBKEY" = lib.readFile ../secrets/jenkins_agent.secret.pub;
    };
    autoStart = true;
  };
  slaves = builtins.listToAttrs (
    builtins.genList (
      n:
      let
        name = "jenkins-slave${toString n}";
      in
      {
        inherit name;
        value = slaveConfig name;
      }
    ) 3
  );
in
{
  virtualisation.oci-containers.containers = master // slaves;

  sops.secrets.id_jenkins_agent = {
    format = "binary";
    sopsFile = ../secrets/jenkins_agent.secret;
  };

  services.nginx.virtualHosts."jenkins.${domain}" = {
    forceSSL = true;
    enableACME = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString port}/";
      proxyWebsockets = true;
    };
  };

  services.prometheus.scrapeConfigs = [
    {
      job_name = "jenkins";
      metrics_path = "/prometheus";
      static_configs = [ { targets = [ "127.0.0.1:${toString port}" ]; } ];
    }
  ];
}
