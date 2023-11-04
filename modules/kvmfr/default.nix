{ std }:
{ lib, pkgs, config, ... }:

with lib;

let
  cfg = config.virtualisation.kvmfr;

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

  dimensionsType = types.submodule {
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
      hdr = mkOption {
        type = types.bool;
        default = false;
        description = mdDoc "Whether HDR should be supported.";
      };
    };
  };

  deviceType = types.submodule {
    options = {
      dimensions = mkOption {
        type = dimensionsType;
        description = mdDoc "Dimensions the device should support.";
      };

      permissions = mkOption {
        type = permissionsType;
        default = { };
        description = mdDoc "Permissions of the kvmfr device.";
      };
    };
  };

  calculateSizeFromDimensions = dimensions:
    let
      ceilToPowerOf2 = n:
        std.num.pow 2 (std.num.bits.bitSize - std.num.bits.countLeadingZeros n);
      bytes = dimensions.width * dimensions.height
        * (if dimensions.hdr then 2 else 1) * 4 * 2;
    in ceilToPowerOf2 (bytes / 1024 / 1024 + 10);

  kvmfrKernelParameter = let
    deviceSizes =
      map (device: (calculateSizeFromDimensions device.dimensions)) cfg.devices;
    deviceSizesString = concatStringsSep "," (map toString (deviceSizes));
  in "kvmfr.static_size_mb=${deviceSizesString}";

  udevPackage = pkgs.writeTextDir "/lib/udev/rules.d/99-kvmfr.rules"
    (concatStringsSep "\n" (imap0 (index: deviceConfig: ''
      SUBSYSTEM=="kvmfr", KERNEL=="kvmfr${
        toString index
      }", OWNER="${deviceConfig.permissions.user}", GROUP="${deviceConfig.permissions.group}", MODE="${deviceConfig.permissions.mode}", TAG+="systemd"
    '') cfg.devices));

  apparmorAbstraction = (concatStringsSep "\n"
    (imap (index: _deviceConfig: "/dev/kvmfr${toString index} rw,")
      cfg.devices));

  libvirtDeviceACL = (imap (index: _deviceConfig: "/dev/kvmfr${toString index}"));
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
    boot.initrd.kernelModules = [ "kvmfr" ];

    boot.kernelParams = optionals (cfg.devices != [ ]) [ kvmfrKernelParameter ];
    services.udev.packages = optionals (cfg.devices != [ ]) [ udevPackage ];

    # create apparmor abstractions to allow libvirtd to use the kvmfr devices
    environment.etc."apparmor.d/local/abstractions/libvirt-qemu" =
      mkIf config.security.apparmor.enable {
        text = pkgs.lib.mkAfter apparmorAbstraction;
      };

    # add kvmfr devices to deviceACL so libvirtd can use them
    virtualisation.libvirtd.deviceACL = libvirtDeviceACL;
  };
}
