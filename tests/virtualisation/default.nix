{ pkgs, imports, ... }:
let
  name = "virtualisation";
in pkgs.nixosTest ({
  inherit name;

  nodes = {
    machine = { config, pkgs, ... }: {
      inherit imports;

           users.users.qemu-libvirtd.group = "qemu-libvirtd";
           users.groups.qemu-libvirtd = {};

      virtualisation.hugepages = {
        enable = true;
        defaultPageSize = "2M";
        pageSize = "2M";
        numPages = 4;
      };
    };
  };

  testScript = ''
    machine.succeed('grep -q "default_hugepagesz=2M" /proc/cmdline')
    machine.succeed('grep -q "hugepagesz=2M" /proc/cmdline')
    machine.succeed('grep -q "hugepages=4" /proc/cmdline')
  '';
})
