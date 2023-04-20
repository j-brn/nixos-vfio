{ lib, config, ... }:

with lib;

{
  config = lib.mkIf cfg.enable {
    services.udev.extraRules = ''
      SUBSYSTEM=="vfio", OWNER="root", GROUP="kvm"
    '';

    boot.kernelParams = (if cfg.IOMMUType == "intel" then [
      "intel_iommu=on"
      "intel_iommu=igfx_off"
    ] else
      [ "amd_iommu=on" ]) ++ (optional (builtins.length cfg.devices > 0)
        ("vfio-pci.ids=" + builtins.concatStringsSep "," cfg.devices))
      ++ (optionals cfg.applyACSpatch [
        "pcie_acs_override=downstream,multifunction"
        "pci=nomsi"
      ]) ++ (optional cfg.disableEFIfb "video=efifb:off")
      ++ (optionals cfg.ignoreMSRs [
        "kvm.ignore_msrs=1"
        "kvm.report_ignored_msrs=0"
      ]);

    boot.blacklistedKernelModules =
      optionals cfg.blacklistNvidia [ "nvidia" "nouveau" ];
  };
}
