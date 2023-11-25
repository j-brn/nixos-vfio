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
            config = {
              bridge = { name = "virbr0"; };
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
            };

            autostart = true;
          };

          rawXml = {
            xml = ''
              <network>
                <name>rawWithOverrides</name>
                <bridge name="virbr0"/>
                <forward mode="nat"/>
                <ip address="192.168.122.1" netmask="255.255.255.0">
                  <dhcp>
                    <range start="192.168.122.2" end="192.168.122.254"/>
                  </dhcp>
                </ip>
                <ip family="ipv6" address="2001:db8:ca2:2::1" prefix="64"/>
              </network>
            '';
          };
        };
      };
    };
  };

  testScript = ''
    machine.wait_for_unit("libvirtd.service")
    machine.wait_until_succeeds("[ -f '/var/lib/libvirt/qemu/networks/default.xml' ]", 10)
    machine.wait_until_succeeds("[ -f '/var/lib/libvirt/qemu/networks/rawXml.xml' ]", 10)
  '';
})
