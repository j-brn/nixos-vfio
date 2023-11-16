{ std }:
{ lib, pkgs, config, ... }:

with lib;

let
  cfg = config.virtualisation.kvmfr;

  sizeFromResolution = resolution:
    let
      ceilToPowerOf2 = n:
        std.num.pow 2 (std.num.bits.bitSize - std.num.bits.countLeadingZeros n);
      pixelSize = if resolution.pixelFormat == "rgb24" then 3 else 4;
      bytes = resolution.width * resolution.height * pixelSize * 2;
    in ceilToPowerOf2 (bytes / 1024 / 1024 + 10);

  deviceSizes = map (device: device.size) cfg.devices;

  devices =
    imap (index: _deviceConfig: "/dev/kvmfr${toString index}") cfg.devices;

  udevPackage = pkgs.writeTextDir "/lib/udev/rules.d/99-kvmfr.rules"
    (concatStringsSep "\n" (imap0 (index: deviceConfig: ''
      SUBSYSTEM=="kvmfr", KERNEL=="kvmfr${
        toString index
      }", OWNER="${deviceConfig.permissions.user}", GROUP="${deviceConfig.permissions.group}", MODE="${deviceConfig.permissions.mode}", TAG+="systemd"
    '') cfg.devices));

  apparmorAbstraction =
    concatStringsSep "\n" (map (device: "${device} rw") devices);

  permissionsType = types.submodule {
    options = {
      user = mkOption {
        type = types.str;
        default = "root";
        description = mdDoc "Owner of the shared memory device.";
      };
      group = mkOption {
        type = types.str;
        default = "root";
        description = mdDoc "Group of the shared memory device.";
      };
      mode = mkOption {
        type = types.str;
        default = "0600";
        description = mdDoc "Mode of the shared memory device.";
      };
    };
  };

  resolutionType = types.submodule {
    options = {
      width = mkOption {
        type = types.number;
        description = mdDoc
          "Maximum horizontal video size that should be supported by this device.";
      };

      height = mkOption {
        type = types.number;
        description = mdDoc
          "Maximum vertical video size that should be supported by this device.";
      };

      pixelFormat = mkOption {
        type = types.enum [ "rgba32" "rgb24" ];
        description = mdDoc "Pixel format to use.";
        default = "rgba32";
      };
    };
  };

  deviceType = (types.submodule ({ config, options, ... }: {
    options = {
      resolution = mkOption {
        type = types.nullOr resolutionType;
        default = null;
        description = mdDoc ''
          Automatically calculate the minimum device size for a specific resolution. Overrides `size` if set.
        '';
      };

      size = mkOption {
        type = types.number;
        description = mdDoc ''
          Size for the kvmfr device in megabytes.
        '';
      };

      permissions = mkOption {
        type = permissionsType;
        default = { };
        description = mdDoc "Permissions of the kvmfr device.";
      };
    };

    config = {
      size =
        mkIf (config.resolution != null) (sizeFromResolution config.resolution);
    };
  }));
in {
  options.virtualisation.kvmfr = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = mdDoc "Whether to enable the kvmfr kernel module.";
    };

    devices = mkOption {
      type = types.listOf deviceType;
      default = [ ];
      description = mdDoc "List of devices to create.";
    };
  };

  config = mkIf cfg.enable {
    boot.extraModulePackages = with config.boot.kernelPackages; [ kvmfr ];
    services.udev.packages = optionals (cfg.devices != [ ]) [ udevPackage ];

    environment.etc = {
      "modules-load.d/kvmfr.conf".text = ''
        kvmfr
      '';

      "modprobe.d/kvmfr.conf".text = ''
        options kvmfr static_size_mb=${
          concatStringsSep "," (map (size: toString size) deviceSizes)
        }
      '';

      "apparmor.d/local/abstractions/libvirt-qemu" =
        mkIf config.security.apparmor.enable {
          text = mkIf config.security.apparmor.enable apparmorAbstraction;
        };
    };

    virtualisation.libvirtd.deviceACL = devices;
  };
}
