{ pkgs, ... }:

let
  fqdn = "vector.bartoostveen.nl";
  wpVhost = fqdn; # TODO: clean up

  wpPackage = pkgs.wordpress_6_9;

  # TODO: group these wordpress packages into something like wordpressPackages.nix
  # keep-sorted start
  generic-oidc =
    with pkgs;
    stdenv.mkDerivation (finalAttrs: {
      pname = "wp-generic-oidc";
      version = "3.11.3";

      src = fetchzip {
        url = "https://downloads.wordpress.org/plugin/daggerhart-openid-connect-generic.${finalAttrs.version}.zip";
        hash = "sha256-/mqGWQz1lHsnA2dpQEZQVCWmqFSmDslFd4rzeEC4PA8=";
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
  wp-language-nl =
    with pkgs;
    stdenv.mkDerivation {
      name = "wp-language-nl";
      src = fetchzip {
        url = "https://nl.wordpress.org/wordpress-${wpPackage.version}-nl_NL.zip";
        name = "wp-${wpPackage.version}-language-nl";
        hash = "sha256-Wev3K0GexZviRZ01USYQibcPjqd5tqY7kP4qvhLjMX4=";
      };
      installPhase = "mkdir -p $out; cp -r ./wp-content/languages/* $out/";
    };
  view-transitions =
    with pkgs;
    stdenv.mkDerivation (finalAttrs: {
      pname = "wp-view-transitions";
      version = "1.2.0";

      src = fetchzip {
        url = "https://downloads.wordpress.org/plugin/view-transitions.${finalAttrs.version}.zip";
        hash = "sha256-mHdek0LI51mfurpyXpM8QOK2E38PwoL8Ad3OQl9yW28=";
      };

      installPhase = "mkdir -p $out; cp -R * $out/";
    });
  # keep-sorted end
in
{
  services.wordpress = {
    webserver = "nginx";
    sites."vector.bartoostveen.nl" = {
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
      languages = [ wp-language-nl ];
      package = wpPackage;
    };
  };

  services.nginx.virtualHosts.${wpVhost} = {
    enableACME = true;
    forceSSL = true;
  };
}
