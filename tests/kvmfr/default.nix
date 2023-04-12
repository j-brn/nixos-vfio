{ pkgs, module, ... }:
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
      imports = [ module ];

      users.users.tester = {
        isNormalUser = true;
        home = "/home/tester";
      };

      virtualisation.kvmfr = kvmfrConfig;
      virtualisation.graphics = false;
    };
  };

  testScript = ''
    start_all()

    # check kernel parameters
    machine.succeed('grep -q "kvmfr.static_size_mb=32,256" /proc/cmdline')

    # check device one
    machine.succeed('[[ "$(stat -c \"%U\" /dev/kvmfr0)" == "tester" ]] || exit 1')
    machine.succeed('[[ "$(stat -c \"%G\" /dev/kvmfr0)" == "root" ]] || exit 1')
    machine.succeed('[[ "$(stat -c \"%a\" /dev/kvmfr0)" == "600" ]] || exit 1')

    # device two
    machine.succeed('[[ "$(stat -c \"%U\" /dev/kvmfr1)" == "tester" ]] || exit 1')
    machine.succeed('[[ "$(stat -c \"%G\" /dev/kvmfr1)" == "root" ]] || exit 1')
    machine.succeed('[[ "$(stat -c \"%a\" /dev/kvmfr1)" == "777" ]] || exit 1')
  '';
})
