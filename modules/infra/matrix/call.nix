{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.infra.matrix;

  inherit (pkgs.callPackage ./lib.nix { }) mkElementCall;
  inherit (lib) mkIf;
in
{
  services.nginx.virtualHosts.${cfg.call.domain} = mkIf cfg.call.enable {
    enableACME = true;
    forceSSL = true;
    root = "${mkElementCall {
      default_server_config."m.homeserver" = {
        base_url = "https://${cfg.domain}";
        server_name = cfg.fqdn;
      };
      features.feature_use_device_session_member_events = true;
      livekit.livekit_service_url = "https://${cfg.livekit.domain}/livekit/jwt";
      matrix_rtc_session = {
        delayed_leave_event_delay_ms = 18000;
        delayed_leave_event_restart_ms = 4000;
        membership_event_expiry_ms = 180000000;
        network_error_retry_ms = 100;
        wait_for_key_rotation_ms = 3000;
      };
      media_devices = {
        enable_audio = false;
        enable_video = false;
      };
      app_prompt = false;
      ssla = "https://static.element.io/legal/element-software-and-services-license-agreement-uk-1.pdf";
    }}";
    locations."/".extraConfig = ''
      try_files $uri /$uri /index.html;
    '';
  };
}
