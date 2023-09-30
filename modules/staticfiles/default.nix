{ lib, config, ... }:

with lib;

let
  cfg = config.environment.staticFiles;

  installStaticFile = path: drv: ''
    echo "linking '${drv}' to '${path}'..."

    DIR=$(dirname "${path}")
    if [ ! -d "''${DIR}" ]; then
      mkdir -p "''${DIR}"
    fi

    ln -sfn "${drv}" "${path}"
    echo "${path}" >> "${cfg.stateFileLocation}"
  '';

  cleanupStaticFiles = ''
    echo "[static_files] cleaning up static files..."

    if [ -e "${cfg.stateFileLocation}" ]; then
      for path in $(cat "${cfg.stateFileLocation}"); do
        if [ -e "''${path}" ]; then
          echo "removing ''${path}..."
          rm -rf "''${path}"
        fi
      done

      rm -f "${cfg.stateFileLocation}"
    fi
  '';

  installStaticFiles = concatStringsSep "\n"
    ([ "echo [static_files] installing static files..." ]
      ++ (mapAttrsToList installStaticFile cfg.files));
in {
  options.environment.staticFiles = {
    stateFileLocation = mkOption {
      type = types.str;
      default = "/.static_files";
      description = mdDoc ''
        Path at which the file containing the list of files to cleanup is stored/read from.
      '';
    };

    files = mkOption {
      type = types.attrsOf types.package;
      default = { };
      description = mdDoc ''
        attrset of paths and derivations to link.
      '';
    };
  };

  config = {
    system.activationScripts = {
      staticfilesCleanup = { text = cleanupStaticFiles; };
      staticfilesInstall = {
        text = installStaticFiles;
        deps = [ "staticfilesCleanup" ];
      };
    };
  };
}
