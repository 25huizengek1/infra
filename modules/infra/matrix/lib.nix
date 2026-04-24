{ pkgs, ... }:

{
  mkElementCall =
    elementCallConfig:
    pkgs.element-call.overrideAttrs {
      postInstall = ''
        install ${pkgs.writers.writeJSON "element-call.json" elementCallConfig} $out/config.json
      '';
    };

  mkAutokumaMonitor = homeserver: {
    tags.matrix = {
      name = "Matrix";
      color = "#0037ff";
    };
    monitors.continuwuity = {
      type = "json-query";
      name = "Matrix federation test (${homeserver}) [federationtester.matrix.org]";
      description = "Matrix federation for ${homeserver} Managed by AutoKuma";
      url = "https://federationtester.matrix.org/api/report?server_name=${homeserver}";
      notification_name_list = [ "autokuma-matrix" ];
      tag_names = [
        {
          name = "autokuma";
          value = "Matrix";
        }
        {
          name = "matrix";
          value = homeserver;
        }
      ];
      json_path = "FederationOK";
      json_path_operator = "==";
      expected_value = "true";
      timeout = 60;
      interval = 120;
      retry_interval = 120;
    };
  };
}
