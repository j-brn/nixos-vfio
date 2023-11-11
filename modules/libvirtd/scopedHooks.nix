{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.virtualisation.libvirtd.scopedHooks;

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
    types.attrsOf (submodule ({ name, config, options, ... }: {
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
          type = nullOr str;
          description = lib.mdDoc ''
            Hook to execute
          '';
        };

        source = mkOption {
          type = path;
          description = mdDoc ''
            Path to the source file of the hook.
          '';
        };

        driver = mkOption {
          type = str;
          default = driver;
          internal = true;
          visible = true;
        };
      };

      config = {
        source = mkIf (config.script != null) (pkgs.writeShellScript
          "libvirtd-hook-source-${name}" config.script);
      };
    }));

  mkHook = name: hook:
    let
      conditions = map (condition: "[[ ${condition} ]]") ([ ]
        ++ optionals (hook.scope.objects != null) [ ("$1 == @(" + (concatStringsSep "|" hook.scope.objects) + ")") ]
        ++ optionals (hook.scope.operations != null) [ ("$2 == @(" + (concatStringsSep "|" hook.scope.operations) + ")") ]
        ++ optionals (hook.scope.subOperations != null) [ ("$3 == @(" + (concatStringsSep "|" hook.scope.subOperations) + ")")]);
    in if (conditions != [ ]) then
      pkgs.writeShellScript "libvirtd-hook-${name}" ''
        if ${concatStringsSep " && " conditions}; then
          ${hook.source} "$@" < /dev/stdin
        fi
      ''
    else
      hook.source;
in {
  ###### interface

  options.virtualisation.libvirtd.scopedHooks = {
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

  ### Implementation

  config.virtualisation.libvirtd.hooks = mapAttrs (driver: hooks: mapAttrs (mkHook) hooks) cfg;
}
