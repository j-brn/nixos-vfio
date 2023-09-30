{ pkgs, imports, ... }:
let name = "libvirt";
in pkgs.nixosTest ({
  inherit name;

  nodes = {
    machine = { config, ... }: {
      inherit imports;

      virtualisation.libvirtd.enable = true;

      vfio.libvirtd.hooks.qemu = {
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

  testScript = ''
    machine.wait_for_unit("libvirtd.service")
    machine.succeed("[ -f '/var/lib/libvirt/hooks/qemu.d/printSomethingBeforeWin10Starts' ]")
  '';
})
