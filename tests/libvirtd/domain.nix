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
        };
      };
    };
  };

  testScript = ''
    machine.wait_for_unit("libvirtd.service")
    machine.wait_until_succeeds("[ -f '/var/lib/libvirt/qemu/win10.xml' ]", 10)
  '';
})
