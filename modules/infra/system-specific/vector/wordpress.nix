{ pkgs, ... }:

let
  domain = "popkoorklankkleur.nl";
  # wpPackage = pkgs.callPackage "${inputs.nixpkgs}/pkgs/servers/web-apps/wordpress/generic.nix" {
  #   version = "6.9.4";
  #   hash = "sha256-22EK2fVJ4Ku1rz49XGcpxY2HRDllTN8K/qQlsuqJXzU=";
  # };
  wpPackage = pkgs.wordpress_6_9;

  mkWpPlugin =
    {
      pname,
      id,
      version,
      hash,
      url ? "https://downloads.wordpress.org/plugin/${id}.${version}.zip",
    }:
    with pkgs;
    stdenv.mkDerivation (_finalAttrs: {
      inherit pname version;
      src = fetchzip {
        inherit url hash;
      };
      installPhase = "mkdir -p $out; cp -R * $out/";
    });

  # TODO: group these wordpress packages into something like wordpressPackages.nix
  generic-oidc = mkWpPlugin {
    pname = "wp-generic-oidc";
    version = "3.11.3";
    id = "daggerhart-openid-connect-generic";
    hash = "sha256-/mqGWQz1lHsnA2dpQEZQVCWmqFSmDslFd4rzeEC4PA8=";
  };
  gutenberg-carousel = mkWpPlugin {
    pname = "wp-gutenberg-carousel";
    version = "2.1.1";
    id = "carousel-block";
    hash = "sha256-WKQ3aGqzcyWnI9XqNVKvd0RUOvg12sduNbJ6rKdCbQE=";
  };
  modify-profile-fields = mkWpPlugin {
    pname = "wp-modify-profile-fields";
    version = "1.1.0";
    id = "user-profile-dashboard-fields-control";
    hash = "sha256-f2lALAuTVTWmZB8z+A7fvv87vbwcwiASH7fsrK4WWGI=";
  };
  view-transitions = mkWpPlugin {
    pname = "wp-view-transitions";
    version = "1.2.0";
    id = "view-transitions";
    hash = "sha256-mHdek0LI51mfurpyXpM8QOK2E38PwoL8Ad3OQl9yW28=";
  };
  wp-language-nl =
    with pkgs;
    stdenv.mkDerivation {
      name = "wp-language-nl";
      src = fetchzip {
        url = "https://nl.wordpress.org/wordpress-${wpPackage.version}-nl_NL.zip";
        name = "wp-${wpPackage.version}-language-nl";
        hash = "sha256-beU5XYpNX6ISD2y46q8r1Jy813V8zxWBzRK4V9d8L9M=";
      };
      installPhase = "mkdir -p $out; cp -r ./wp-content/languages/* $out/";
    };
in
{
  services.wordpress = {
    webserver = "nginx";
    sites.${domain} = {
      settings = {
        WP_DEFAULT_THEME = "twentytwentyfive";
        WP_SITEURL = "https://${domain}";
        WP_HOME = "https://${domain}";
        WP_DEBUG = true;
        WP_DEBUG_DISPLAY = false;

        WPLANG = "nl_NL";
        FORCE_SSL_ADMIN = true;
        AUTOMATIC_UPDATER_DISABLED = true;
      };
      plugins = {
        inherit
          # keep-sorted start
          generic-oidc
          gutenberg-carousel
          modify-profile-fields
          view-transitions
          # keep-sorted end
          ;
        inherit (pkgs.wordpressPackages.plugins)
          # keep-sorted start
          antispam-bee
          gutenberg
          opengraph
          wp-user-avatars
          # keep-sorted end
          ;
        inherit (pkgs.local) wp-oidc-roles;
      };
      themes = {
        inherit (pkgs.wordpressPackages.themes) twentytwentyfive;
      };
      languages = [ wp-language-nl ];
      package = wpPackage;
    };
  };

  services.nginx.virtualHosts.${domain} = {
    enableACME = true;
    forceSSL = true;
  };

  infra.backup.jobs.state.paths = [ "/var/lib/wordpress/${domain}" ];
}
