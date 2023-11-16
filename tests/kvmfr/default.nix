{ pkgs, imports, ... }:
let
  name = "kvmfr";
  kvmfrConfig = {
    enable = true;
    devices = [
      {
        resolution = {
          width = 1920;
          height = 1080;
        };

        permissions = { user = "tester"; };
      }
      {
        resolution = {
          width = 3840;
          height = 2160;
          pixelFormat = "rgba32";
        };

        permissions = {
          user = "tester";
          mode = "0777";
        };
      }
      {
        resolution = {
          width = 3840;
          height = 2160;
          pixelFormat = "rgb24";
        };
      }
      {
        size = 32;

        permissions = {
          user = "tester";
        };
      }
    ];
  };
in pkgs.nixosTest ({
  inherit name;

  nodes = {
    machine = { config, pkgs, ... }: {
      inherit imports;

      users.users.tester = {
        isNormalUser = true;
        home = "/home/tester";
      };

     users.users.qemu-libvirtd.group = "qemu-libvirtd";
     users.groups.qemu-libvirtd = {};

      virtualisation.kvmfr = kvmfrConfig;
      virtualisation.graphics = false;
    };
  };

  testScript = ''
    machine.succeed("grep -q 'kvmfr' /etc/modules-load.d/kvmfr.conf")
    machine.succeed("grep -q 'options kvmfr static_size_mb=32,128,64,32' /etc/modprobe.d/kvmfr.conf")

    machine.wait_for_unit("systemd-modules-load.service")
    machine.wait_for_unit("systemd-udevd.service")

    # check properties of kvmfr device nodes
    for dev, prop, expected in [
        ("/dev/kvmfr0", "%U", "tester"),
        ("/dev/kvmfr0", "%G", "root"),
        ("/dev/kvmfr0", "%a", "600"),
        ("/dev/kvmfr1", "%U", "tester"),
        ("/dev/kvmfr1", "%G", "root"),
        ("/dev/kvmfr1", "%a", "777"),
        ("/dev/kvmfr2", "%U", "root"),
        ("/dev/kvmfr2", "%G", "root"),
        ("/dev/kvmfr2", "%a", "600"),
        ("/dev/kvmfr3", "%U", "tester"),
    ]:
        name = dev.split('/')[-1]
        machine.wait_until_succeeds(f"systemctl status dev-{name}.device; test $? -ne 4")

        # check that device was created and has the correct permissions
        exitcode, stdout = machine.execute(f"stat -c '{prop}' '{dev}'")
        stdout = stdout.strip()
        assert exitcode == 0, f"Checking property '{prop}' of '{dev}' failed. Exitcode {exitcode}"
        assert stdout == expected, f"{dev} has wrong {prop}. Expected '{expected}', got '{stdout}'"
  '';
})
