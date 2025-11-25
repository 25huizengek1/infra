{ config, ... }:

{
  sops.secrets.nm-env = {
    owner = "root";
    group = "root";
    mode = "0600";

    sopsFile = ../secrets/nm-env.secret;
    format = "binary";
  };

  networking.networkmanager.ensureProfiles = {
    environmentFiles = [
      config.sops.secrets.nm-env.path
    ];

    profiles = {
      "; DROP TABLE WIFI; --" = {
        connection = {
          id = "; DROP TABLE WIFI; --";
          interface-name = "wlp0s20f3";
          permissions = "user:bart:;";
          type = "wifi";
          uuid = "7bf4ea33-f403-4bfe-bca0-6b7cd8a71e6d";
        };
        ipv4 = {
          method = "auto";
        };
        ipv6 = {
          addr-gen-mode = "default";
          method = "auto";
        };
        proxy = { };
        wifi = {
          mode = "infrastructure";
          ssid = "\\\\; DROP TABLE WIFI\\\\; --";
        };
        wifi-security = {
          key-mgmt = "sae";
          leap-password-flags = "1";
          psk = "$HOME_WIFI_PSK";
          psk-flags = "1";
          wep-key-flags = "1";
        };
      };
      "Bart's Nothing Phone (2a)" = {
        connection = {
          id = "Bart's Nothing Phone (2a)";
          interface-name = "wlp0s20f3";
          permissions = "user:bart:;";
          type = "wifi";
          uuid = "5d0a5831-8014-4a1a-b622-af6ec194e9ff";
        };
        ipv4 = {
          method = "auto";
        };
        ipv6 = {
          addr-gen-mode = "default";
          method = "auto";
        };
        proxy = { };
        wifi = {
          mode = "infrastructure";
          ssid = "Bart's Nothing Phone (2a)";
        };
        wifi-security = {
          auth-alg = "open";
          key-mgmt = "sae";
          leap-password-flags = "1";
          psk = "$PHONE_HOTSPOT_PSK";
          psk-flags = "1";
          wep-key-flags = "1";
        };
      };
      eduroam = {
        "802-1x" = {
          anonymous-identity = "anonymous@utwente.nl";
          ca-cert = "/etc/ssl/certs/ca-certificates.crt";
          domain-suffix-match = "radius.utwente.nl";
          eap = "ttls;";
          identity = "b.oostveen@student.utwente.nl";
          password-flags = "1";
          phase2-auth = "mschapv2";
        };
        connection = {
          id = "eduroam";
          permissions = "user:bart:;";
          type = "wifi";
          uuid = "51611409-d62a-4b19-8d14-5e3bdcf0f10c";
        };
        ipv4 = {
          method = "auto";
        };
        ipv6 = {
          addr-gen-mode = "stable-privacy";
          method = "auto";
        };
        proxy = { };
        wifi = {
          mode = "infrastructure";
          ssid = "eduroam";
        };
        wifi-security = {
          key-mgmt = "wpa-eap";
          psk = "$EDUROAM_UNIVERSITY_PASSWORD";
        };
      };
    };
  };
}
