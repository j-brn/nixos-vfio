{ pkgs, imports, ... }:
let
  name = "kvmfr";
  kvmfrConfig = {
    enable = true;
    devices = [
      {
        dimensions = {
          width = 1920;
          height = 1080;
        };

        permissions = { user = "tester"; };
      }
      {
        dimensions = {
          width = 3840;
          height = 2160;
          hdr = true;
        };

        permissions = {
          user = "tester";
          mode = "0777";
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
    # check kernel parameters
    machine.succeed('grep -q "kvmfr.static_size_mb=32,256" /proc/cmdline')
    machine.wait_for_unit("systemd-udevd.service")

    # check properties of kvmfr device nodes
    for dev, prop, expected in [
        ("/dev/kvmfr0", "%U", "tester"),
        ("/dev/kvmfr0", "%G", "root"),
        ("/dev/kvmfr0", "%a", "600"),
        ("/dev/kvmfr1", "%U", "tester"),
        ("/dev/kvmfr1", "%G", "root"),
        ("/dev/kvmfr1", "%a", "777"),
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
