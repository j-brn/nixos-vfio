{ std }:
{ lib, pkgs, config, ... }:

with lib;

let
  cfg = config.virtualisation.kvmfr;

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
in {
  config = mkIf cfg.enable {
    boot.extraModulePackages = with config.boot.kernelPackages; [ kvmfr ];
    boot.initrd.kernelModules = [ "kvmfr" ];

    boot.kernelParams = optionals (cfg.devices != [ ]) [ kvmfrKernelParameter ];
    services.udev.packages = optionals (cfg.devices != [ ]) [ udevPackage ];
  };
}
