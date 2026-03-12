{ pkgs, inputs, ... }:

let
  wpVhost = "vector.bartoostveen.nl";
  wpPackage = pkgs.callPackage "${inputs.nixpkgs}/pkgs/servers/web-apps/wordpress/generic.nix" {
    version = "6.9.4";
    hash = "sha256-22EK2fVJ4Ku1rz49XGcpxY2HRDllTN8K/qQlsuqJXzU=";
  };

  mkWpPlugin =
    {
      pname,
      id,
      version,
      hash,
      url ? "https://downloads.wordpress.org/plugin/${id}.${version}.zip",
    }:
    with pkgs;
    stdenv.mkDerivation (finalAttrs: {
      inherit pname version;
      src = fetchzip {
        inherit url hash;
      };
      installPhase = "mkdir -p $out; cp -R * $out/";
    });

  # TODO: group these wordpress packages into something like wordpressPackages.nix
  # keep-sorted start
  generic-oidc = mkWpPlugin {
    pname = "wp-generic-oidc";
    version = "3.11.3";
    id = "daggerhart-openid-connect-generic";
    hash = "sha256-/mqGWQz1lHsnA2dpQEZQVCWmqFSmDslFd4rzeEC4PA8=";
  };
  gutenberg-carousel = mkWpPlugin {
    pname = "wp-gutenberg-carousel";
    version = "2.0.6";
    id = "carousel-block";
    hash = "sha256-mUDnMPR5fIcLVx/sL/Gh7Nq7I0xgmvrRMpVyubWXFSg=";
  };
  modify-profile-fields = mkWpPlugin {
    pname = "wp-modify-profile-fields";
    version = "1.07";
    id = "modify-profile-fields-dashboa";
    hash = "sha256-+wxTQCkmmWYe3B0/XOljWEWyWj/SPk90rxvJwwspbFM=";
  };
  view-transitions = mkWpPlugin {
    pname = "wp-view-transitions";
    version = "1.2.0";
    id = "view-transitions";
    hash = "sha256-mHdek0LI51mfurpyXpM8QOK2E38PwoL8Ad3OQl9yW28=";
  };
  # keep-sorted end
  wp-language-nl =
    with pkgs;
    stdenv.mkDerivation {
      name = "wp-language-nl";
      src = fetchzip {
        url = "https://nl.wordpress.org/wordpress-6.9.3-nl_NL.zip";
        name = "wp-${wpPackage.version}-language-nl";
        hash = "sha256-5OxQDpkBrE1WWwFGL292Z8RQpFFehfbOIwWcmsVhPa4=";
      };
      installPhase = "mkdir -p $out; cp -r ./wp-content/languages/* $out/";
    };
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
