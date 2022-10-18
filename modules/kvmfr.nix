{ lib, pkgs, config, ... }:

with lib;

let
  cfg = config.virtualisation.kvmfr;

  udevRules =
    concatStringsSep "\n" (imap0
      (index: deviceConfig:
        ''
          SUBSYSTEM=="kvmfr", KERNEL="kvmfr${toString index}", OWNER="${deviceConfig.permissions.user}", GROUP="${deviceConfig.permissions.group}", MODE="${deviceConfig.permissions.mode}"
        ''
      )
      cfg.devices);

  deviceSizes = concatStringsSep "," (map (deviceConfig: toString deviceConfig.size) cfg.devices);

  permissionsType = types.submodule {
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

  deviceType = types.submodule {
    options = {
      size = mkOption {
        type = types.int;
        description = "Size of the shared memory device in megabytes.";
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

    boot.kernelParams = optionals (cfg.devices != [ ]) [ "kvmfr.static_size_mb=${deviceSizes}" ];
    services.udev.extraRules = optionals (cfg.devices != [ ]) udevRules;
  };

  meta.maintainers = with maintainers; [ j-brn ];
}
