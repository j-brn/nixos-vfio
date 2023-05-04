{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.virtualisation.libvirtd.hooks;
  hookDir = "/var/lib/libvirt/hooks";

  mkHook = name: hookConfig:
    let
      innerHook = pkgs.writeShellScript "hook" hookConfig.script;
      wrapper = let
        objectsCondition = if (hookConfig.conditions.objects != null) then
          "$1 == @(" + (concatStringsSep "|" hookConfig.conditions.objects)
          + ")"
        else
          "";

        operationsCondition = if (hookConfig.conditions.operations != null) then
          "$1 == @(" + (concatStringsSep "|" hookConfig.conditions.operations)
          + ")"
        else
          "true";

        subOperationsCondition =
          if (hookConfig.conditions.subOperations != null) then
            "$1 == @("
            + (concatStringsSep "|" hookConfig.conditions.subOperations) + ")"
          else
            "true";
      in ''
        if true && [[ ${objectsCondition} ]] && [[ ${operationsCondition} ]] && [[ ${subOperationsCondition} ]]; then
          ${innerHook} "$@" < /dev/stdin
        fi
      '';
    in pkgs.writeShellScript name wrapper;

  mkHookStaticFileEntries = driver: hookConfigs:
    let
      hooks = mapAttrs (mkHook) hookConfigs;
      destination = "${hookDir}/${driver}.d/";
    in mapAttrs' (name: hook: nameValuePair "${destination}/${name}" hook)
    hooks;

  hookConditionsSubmodule = with types;
    submodule {
      options = {
        objects = mkOption {
          type = nullOr (listOf str);
          default = null;
          description = mdDoc ''
            If not null, the hook is only executed if the object matches a value in the given list.
          '';
        };

        operations = mkOption {
          type = nullOr (listOf str);
          default = null;
          description = mdDoc ''
            If not null, the hook is only executed if the operation matches a value in the given list.
          '';
        };

        subOperations = mkOption {
          type = nullOr (listOf str);
          default = null;
          description = mdDoc ''
            If not null, the hook is only executed if the sub-operation matches a value in the given list.
          '';
        };
      };
    };

  mkHooksSubmoduleType = with types;
    driver:
    types.attrsOf (submodule {
      options = {
        enable = mkOption {
          type = bool;
          default = true;
          description = lib.mdDoc ''
            Whether to enable the hook
          '';
        };

        conditions = mkOption {
          type = hookConditionsSubmodule;
          default = null;
          description = lib.mdDoc ''
            Limit the execution of the hook to certain objects, operations or sub-operations.
          '';
        };

        script = mkOption {
          type = str;
          default = "";
          description = lib.mdDoc ''
            Hook to execute
          '';
        };

        driver = mkOption {
          type = str;
          default = driver;
          internal = true;
          visible = true;
        };
      };
    });
in {
  ###### interface

  options.virtualisation.libvirtd.hooks = {
    daemon = mkOption {
      type = mkHooksSubmoduleType "daemon";
      description = "daemon hooks";
      default = { };
    };

    qemu = mkOption {
      type = mkHooksSubmoduleType "qemu";
      description = "qemu hooks";
      default = { };
    };

    lxc = mkOption {
      type = mkHooksSubmoduleType "lxc";
      description = "lxc hooks";
      default = { };
    };

    libxl = mkOption {
      type = mkHooksSubmoduleType "libxl";
      description = "libxl hooks";
      default = { };
    };

    network = mkOption {
      type = mkHooksSubmoduleType "network";
      description = "network hooks";
      default = { };
    };
  };

  ###### implementation
  config.environment.staticFiles.files = mkMerge [
    (mkHookStaticFileEntries "daemon"
      (filterAttrs (name: hookConfig: hookConfig.enable) cfg.daemon))
    (mkHookStaticFileEntries "qemu"
      (filterAttrs (name: hookConfig: hookConfig.enable) cfg.qemu))
    (mkHookStaticFileEntries "lxc"
      (filterAttrs (name: hookConfig: hookConfig.enable) cfg.lxc))
    (mkHookStaticFileEntries "libxl"
      (filterAttrs (name: hookConfig: hookConfig.enable) cfg.libxl))
    (mkHookStaticFileEntries "network"
      (filterAttrs (name: hookConfig: hookConfig.enable) cfg.network))
  ];
}
