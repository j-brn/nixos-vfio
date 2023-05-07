{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.virtualisation.libvirtd;

  boolToZeroOne = x: if x then "1" else "0";

  aclString = with lib.strings;
    concatMapStringsSep ''
      ,
    '' escapeNixString cfg.deviceACL;
in {
  imports = [ ./hooks.nix ];

  options.virtualisation.libvirtd = {
    deviceACL = mkOption {
      type = types.listOf types.str;
      description = mdDoc ''
        Devices to add to the libvirt device ACL.
      '';
      default = [ ];
    };
    clearEmulationCapabilities = mkOption {
      type = types.bool;
      description = mdDoc ''
        Clear emulation capabilities
      '';
      default = true;
    };
  };

  config.users = {
    users.qemu-libvirtd = {
      group = "qemu-libvirtd";
      isSystemUser = true;
      extraGroups = optionals (!cfg.qemu.runAsRoot) [ "kvm" "input" ];
    };
    groups.qemu-libvirtd = { };
  };

  config.virtualisation.libvirtd.qemu.verbatimConfig = ''
    clear_emulation_capabilities = ${
      boolToZeroOne cfg.clearEmulationCapabilities
    }
    cgroup_device_acl = [
      ${aclString}
    ]

    user = "jonas"
    group = "libvirtd"
  '';
}
