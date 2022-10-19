{ std }: { lib, pkgs, config, ... }:

with lib;

let
  cfg = config.virtualisation.kvmfr;

  calculateSizeFromDimensions = dimensions:
    let
      ceilToPowerOf2 = n: std.num.pow 2 (std.num.bits.bitSize - std.num.bits.countLeadingZeros n);
      bytes = dimensions.width * dimensions.height * (if dimensions.hdr then 2 else 1) * 4 * 2;
    in
    ceilToPowerOf2 (bytes / 1024 / 1024 + 10);

  kvmfrKernelParameter =
    let
      deviceSizes = map (device: (calculateSizeFromDimensions device.dimensions)) cfg.devices;
      deviceSizesString = concatStringsSep "," (map toString (deviceSizes));
    in
    "kvmfr.static_size_mb=${deviceSizesString}";

  udevRules =
    concatStringsSep "\n" (imap0
      (index: deviceConfig:
        ''
          SUBSYSTEM=="kvmfr", KERNEL="kvmfr${toString index}", OWNER="${deviceConfig.permissions.user}", GROUP="${deviceConfig.permissions.group}", MODE="${deviceConfig.permissions.mode}"
        ''
      )
      cfg.devices);

  permissionsType =
    types.submodule
      {
        options = {
          user = mkOption {
            type = types.str;
            default = "root";
            description = "Owner of the shared memory device.";
          };
          group = mkOption {
            type = types.str;
            default = "root";
            description = "Group of the shared memory device.";
          };
          mode = mkOption {
            type = types.str;
            default = "0600";
            description = "Mode of the shared memory device.";
          };
        };
      };

  dimensionsType = types.submodule {
    options = {
      width = mkOption {
        type = types.number;
        description = "Maximum horizontal video size that should be supported by this device.";
      };
      height = mkOption {
        type = types.number;
        description = "Maximum vertical video size taht should be supported by this device.";
      };
      hdr = mkOption {
        type = types.bool;
        default = false;
        description = "Whether HDR should be supported.";
      };
    };
  };

  deviceType = types.submodule {
    options = {
      dimensions = mkOption {
        type = dimensionsType;
      };

      permissions = mkOption {
        type = permissionsType;
        default = { };
      };
    };
  };
in
{
  ### Interface ###

  options.virtualisation.kvmfr = {
    enable = mkEnableOption "kvmfr";

    devices = mkOption {
      type = types.listOf deviceType;
      default = [ ];
    };
  };

  ### Implementation ###

  config = mkIf cfg.enable {
    boot.extraModulePackages = with config.boot.kernelPackages; [ kvmfr ];
    boot.initrd.kernelModules = [ "kvmfr" ];

    boot.kernelParams = optionals (cfg.devices != [ ]) [ kvmfrKernelParameter ];
    services.udev.extraRules = optionals (cfg.devices != [ ]) udevRules;
  };

  meta.maintainers = with maintainers; [ j-brn ];
}
