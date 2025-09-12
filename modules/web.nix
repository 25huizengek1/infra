{
  config,
  const,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  domains = [
    const.domain
    "omeduostuurcentenneef.nl"
  ];

  name = "web";
  imageName = "omeduostuurcentenneef-web";
  port = 6969;

  socketPath = "/run/omeduoweb.sock";

  pkg = inputs.omeduostuurcentenneef-web.packages.${pkgs.stdenv.hostPlatform.system}.default;

  dockerImage = pkgs.dockerTools.streamLayeredImage {
    name = imageName;
    tag = pkg.version;
    contents = [ pkg ];
    config.Cmd = [ "/bin/omeduostuurcentenneef-web" ];
  };
in
{
  virtualisation.oci-containers.containers.${name} = {
    image = "localhost/${imageName}:${pkg.version}"; # thank you podman implementation, very cool
    imageStream = dockerImage;
    environment.PORT = toString port;
    ports = [ "${toString port}:${toString port}" ];
  };

  services.nginx.virtualHosts = lib.genAttrs domains (_: {
    forceSSL = true;
    enableACME = true;
    locations."/".proxyPass = "http://localhost:${toString port}";
  });
}
