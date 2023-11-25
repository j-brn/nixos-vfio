{ pkgs, imports, ... }:

pkgs.nixosTest ({
  name = "libvirtd-domain";

  nodes = {
    machine = { config, pkgs, ... }: {
      inherit imports;

      users.users.qemu-libvirtd.group = "qemu-libvirtd";
      users.groups.qemu-libvirtd = { };

      virtualisation.libvirtd = {
        enable = true;

        qemu.domains = {
          declarative = true;

          domains = {
            win10 = {
              config = {
                memory = {
                  memory = {
                    value = 1;
                    unit = "G";
                  };

                  disableBallooning = true;
                  useHugepages = false;
                };

                os.enableBootmenu = true;

                vcpu = {
                  count = 2;
                  placement = "static";
                };

                cputune = {
                  vcpupins = [
                    {
                      vcpu = 1;
                      cpuset = [ 1 ];
                    }
                    {
                      vcpu = 2;
                      cpuset = [ 2 ];
                    }
                  ];
                };

                cpu = {
                  topology = {
                    sockets = 1;
                    dies = 1;
                    cores = 2;
                    threads = 1;
                  };
                };

                input = {
                  virtioMouse = true;
                  virtioKeyboard = true;
                };

                spice = {
                  spiceAudio = true;
                  spicemvcChannel = true;
                  spiceGraphics = true;
                };

                pciHostDevices = [{
                  sourceAddress = {
                    bus = "0x04";
                    slot = "0x00";
                    function = 1;
                  };
                }];

                networkInterfaces = [{ sourceNetwork = "default"; }];

                cdroms = [{
                  sourceFile = "/opt/someIso.iso";
                  bootIndex = 1;
                }];

                kvmfr = {
                  device = "/dev/kvmfr0";
                  size = "33554432";
                };
              };
            };

            rawXml.xml = ''
              <domain xmlns:qemu="http://libvirt.org/schemas/domain/qemu/1.0" type="kvm">
                <name>rawXml</name>
                <memory>131072</memory>
                <vcpu>1</vcpu>
                <os>
                  <type arch="i686">hvm</type>
                </os>
                <devices>
                  <emulator>/usr/bin/qemu-kvm</emulator>
                  <disk type="file" device="disk">
                    <source file="/var/lib/libvirt/images/demo2.img"/>
                    <target dev="hda"/>
                  </disk>
                  <interface type="network">
                    <source network="default"/>
                    <mac address="24:42:53:21:52:45"/>
                  </interface>
                  <graphics type="vnc" port="-1" keymap="de"/>
                </devices>
              </domain>
            '';
          };
        };
      };
    };
  };

  testScript = ''
    machine.wait_for_unit("libvirtd.service")
    machine.wait_until_succeeds("[ -f '/var/lib/libvirt/qemu/win10.xml' ]", 10)
    machine.wait_until_succeeds("[ -f '/var/lib/libvirt/qemu/rawXml.xml' ]", 10)
  '';
})
