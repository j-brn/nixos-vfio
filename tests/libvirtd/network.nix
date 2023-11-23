{ pkgs, imports, ... }:

pkgs.nixosTest ({
  name = "libvirtd-network";

  nodes = {
    machine = { config, pkgs, ... }: {
      inherit imports;

      users.users.qemu-libvirtd.group = "qemu-libvirtd";
      users.groups.qemu-libvirtd = { };

      virtualisation.libvirtd = {
        enable = true;

        qemu.networks.declarative = true;
        qemu.networks.networks = {
          default = {
            forward = { mode = "nat"; };

            ips = [
              {
                family = "ipv4";
                address = "192.168.100.1";
                prefix = 24;

                dhcpRanges = [{
                  start = "192.168.100.128";
                  end = "192.168.100.254";
                }];
              }
              {
                family = "ipv6";
                address = "2001:db8:ca2:2::1";
                prefix = 64;

                dhcpRanges = [{
                  start = "2001:db8:ca2:2::100";
                  end = "2001:db8:ca2:2::1ff";
                }];
              }
            ];

            autostart = true;
          };
        };
      };
    };
  };

  testScript = ''
    machine.wait_for_unit("libvirtd.service")
    machine.wait_until_succeeds("[ -f '/var/lib/libvirt/qemu/networks/default.xml' ]", 10)
  '';
})
