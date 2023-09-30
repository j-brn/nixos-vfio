{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.virtualisation;
in {
  options.virtualisation = {
    hugepages = {
      enable = mkEnableOption "Hugepages";

      defaultPageSize = mkOption {
        type = types.strMatching "[0-9]*[kKmMgG]";
        default = "1M";
        description =
          "Default size of huge pages. You can use suffixes K, M, and G to specify KB, MB, and GB.";
      };
      pageSize = mkOption {
        type = types.strMatching "[0-9]*[kKmMgG]";
        default = "1M";
        description =
          "Size of huge pages that are allocated at boot. You can use suffixes K, M, and G to specify KB, MB, and GB.";
      };
      numPages = mkOption {
        type = types.ints.positive;
        default = 1;
        description = "Number of huge pages to allocate at boot.";
      };
    };
  };

  config.boot.kernelParams = optionals cfg.hugepages.enable [
    "default_hugepagesz=${cfg.hugepages.defaultPageSize}"
    "hugepagesz=${cfg.hugepages.pageSize}"
    "hugepages=${toString cfg.hugepages.numPages}"
  ];
}