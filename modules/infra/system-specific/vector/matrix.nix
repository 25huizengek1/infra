{
  continuwuityPkgs,
  ...
}:

{
  imports = [
    ../../matrix
  ];

  infra.matrix =
    let
      fqdn = "continuwuity-old.bartoostveen.nl";
    in
    {
      enable = true;
      alertmanager.enable = false;
      package = continuwuityPkgs.matrix-continuwuity.overrideAttrs {
        patches = [
          ./feat-Implement-sketchy-backwards-compatibility-for-invites.patch
        ];
      };
      inherit fqdn;
      domain = "server.${fqdn}";
    };

  services.matrix-continuwuity.settings.global.enable_legacy_invite_support = true;
}
