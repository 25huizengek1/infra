{
  config,
  const,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  name = "web";
  imageName = "omeduostuurcentenneef-web";
  port = 6969;

  pkg = inputs.omeduostuurcentenneef-web.packages.${pkgs.stdenv.hostPlatform.system}.default;

  dockerImage = pkgs.dockerTools.streamLayeredImage {
    name = imageName;
    tag = pkg.version;
    contents = with pkgs; [
      pkg
      cacert
      curl
      coreutils-full
      bashInteractive
    ];
    config = {
      Cmd = [ "/bin/omeduostuurcentenneef-web" ];
      Env = [ "NODE_EXTRA_CA_CERTS=/etc/ssl/certs/ca-bundle.crt" ];
    };
  };
in
{
  virtualisation.oci-containers.containers.${name} = {
    image = "localhost/${imageName}:${pkg.version}"; # thank you podman implementation, very cool
    imageStream = dockerImage;
    environment.PORT = toString port;
    environmentFiles = [ config.sops.secrets.web-env.path ];
    ports = [ "${toString port}:${toString port}" ];
  };

  services.nginx.virtualHosts.${const.domain} = {
    forceSSL = true;
    enableACME = true;
    locations."/".proxyPass = "http://localhost:${toString port}";
  };

  sops.secrets.web-env = {
    format = "binary";
    sopsFile = ../secrets/web.env.secret;
    restartUnits = [ "podman-web.service" ];
  };
}
