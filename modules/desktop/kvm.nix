{ pkgs, ... }:

{
  virtualisation.spiceUSBRedirection.enable = true;
  virtualisation.libvirtd = {
    enable = true;

    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;
    };
  };

  users.users.bart.extraGroups = [ "libvirtd" ];

  programs.virt-manager.enable = true;
}
