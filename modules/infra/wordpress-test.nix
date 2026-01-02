{ pkgs, ... }:

let
  fqdn = "bartoostveen.nl";
  wpVhost = "wordpress-test.${fqdn}";

  # keep-sorted start
  generic-oidc =
    with pkgs;
    stdenv.mkDerivation (finalAttrs: {
      pname = "wp-generic-oidc";
      version = "3.10.2";

      src = fetchzip {
        url = "https://downloads.wordpress.org/plugin/daggerhart-openid-connect-generic.${finalAttrs.version}.zip";
        hash = "sha256-bi4EWbMqgRvx0gyu94XMMNY0Tt1YGY6SYhKds/gZknY=";
      };

      installPhase = "mkdir -p $out; cp -R * $out/";
    });
  gutenberg-carousel =
    with pkgs;
    stdenv.mkDerivation (finalAttrs: {
      pname = "wp-gutenberg-carousel";
      version = "2.0.6";

      src = fetchzip {
        url = "https://downloads.wordpress.org/plugin/carousel-block.${finalAttrs.version}.zip";
        hash = "sha256-BBw5lK0/kGaGePMtGcw/RXqGZz/aTxIke9IOC5TWwGA=";
      };

      installPhase = "mkdir -p $out; cp -R * $out/";
    });
  modify-profile-fields =
    with pkgs;
    stdenv.mkDerivation (_finalAttrs: {
      pname = "wp-modify-profile-fields";
      version = "1.07";

      src = fetchzip {
        url = "https://downloads.wordpress.org/plugin/modify-profile-fields-dashboard-menu-buttons.zip";
        hash = "sha256-+wxTQCkmmWYe3B0/XOljWEWyWj/SPk90rxvJwwspbFM=";
      };

      installPhase = "mkdir -p $out; cp -R * $out/";
    });
  view-transitions =
    with pkgs;
    stdenv.mkDerivation (finalAttrs: {
      pname = "wp-view-transitions";
      version = "1.1.1";

      src = fetchzip {
        url = "https://downloads.wordpress.org/plugin/view-transitions.${finalAttrs.version}.zip";
        hash = "sha256-tJZSwV51CWYPZW0BwksRvcZDWCV6UJxvtMrur25CqAg=";
      };

      installPhase = "mkdir -p $out; cp -R * $out/";
    });
  # keep-sorted end

  wordpress_6_9 =
    with pkgs;
    wordpress.overrideAttrs rec {
      version = "6.9";
      src = fetchurl {
        url = "https://wordpress.org/wordpress-${version}.tar.gz";
        hash = "sha256-WzY5AjPjL+9oy19mQ1uzK91Q4LPfpXUKzrLePFmT1yA=";
      };
    };
in
{
  services.wordpress = {
    webserver = "nginx";
    sites.${wpVhost} = {
      settings = {
        WP_DEFAULT_THEME = "twentytwentyfive";
        WP_SITEURL = "https://${wpVhost}";
        WP_HOME = "https://${wpVhost}";
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
      languages = [
        (with pkgs; stdenv.mkDerivation {
          name = "wp-language-nl";
          src = fetchzip {
            url = "https://nl.wordpress.org/wordpress-${wordpress_6_9.version}-nl_NL.zip";
            name = "wp-${wordpress_6_9.version}-language-nl";
            hash = "sha256-iMQPKAIeVGnoBFbhlLbVZaiBVGL3DhiqSe9iKvRYK4E=";
          };
          installPhase = "mkdir -p $out; cp -r ./wp-content/languages/* $out/";
        })
      ];
      package = wordpress_6_9;
    };
  };

  services.nginx.virtualHosts.${wpVhost} = {
    enableACME = true;
    forceSSL = true;
  };
}
