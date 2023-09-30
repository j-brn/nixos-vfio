{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.vfio.libvirtd.hooks;

  mkHook = name: hook:
    let
      innerHook = pkgs.writeShellScript "hook" hook.script;
      wrapper = let
        objectsCondition = if (hook.scope.objects != null) then
          "$1 == @(" + (concatStringsSep "|" hook.scope.objects) + ")"
        else
          "true";

        operationsCondition = if (hook.scope.operations != null) then
          "$1 == @(" + (concatStringsSep "|" hook.scope.operations) + ")"
        else
          "true";

        subOperationsCondition = if (hook.scope.subOperations != null) then
          "$1 == @(" + (concatStringsSep "|" hook.scope.subOperations) + ")"
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

  hookscopeSubmodule = with types;
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

        scope = mkOption {
          type = hookscopeSubmodule;
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

  options.vfio.libvirtd.hooks = {
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

  config.virtualisation.libvirtd.hooks = mapAttrs (driver: hooks: mapAttrs (mkHook) hooks) cfg;
}
