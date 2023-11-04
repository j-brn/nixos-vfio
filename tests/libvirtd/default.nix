{ pkgs, imports, ... }:
let name = "libvirt";
in pkgs.nixosTest ({
  inherit name;

  nodes = {
    machine = { config, ... }: {
      inherit imports;

           users.users.qemu-libvirtd.group = "qemu-libvirtd";
           users.groups.qemu-libvirtd = {};

      virtualisation.libvirtd = {
        enable = true;

        qemu.runAsRoot = false;
        clearEmulationCapabilities = true;
        deviceACL = [
          "/some/allowed/device"
        ];

        scopedHooks.qemu = {
          printSomethingBeforeWin10Starts = {
            enable = true;

            scope = {
              objects = [ "win10" ];
              operations = [ "prepare" ];
            };

            script = ''
              echo "win10 vm is starting"
            '';
          };
        };
      };
    };
  };

  testScript = ''
    machine.wait_for_unit("libvirtd.service")
    machine.succeed("[ -f '/var/lib/libvirt/hooks/qemu.d/printSomethingBeforeWin10Starts' ]")

    machine.succeed("id -nG 'qemu-libvirtd' | grep -qw 'kvm'")
    machine.succeed("id -nG 'qemu-libvirtd' | grep -qw 'input'")

    machine.succeed("grep -q 'clear_emulation_capabilities = 1' /var/lib/libvirt/qemu.conf")
    machine.succeed("grep -q 'cgroup_device_acl' /var/lib/libvirt/qemu.conf")
    machine.succeed("grep -q '/some/allowed/device' /var/lib/libvirt/qemu.conf")
  '';
})
