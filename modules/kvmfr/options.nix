{ lib, ... }:

with lib;

let
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
        description =
          mdDoc "Maximum horizontal video size that should be supported by this device.";
      };
      height = mkOption {
        type = types.number;
        description =
          mdDoc "Maximum vertical video size that should be supported by this device.";
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
}