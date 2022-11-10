{ config
, lib
, pkgs
, ...
}:
with lib; let
  cfg = config.virtualisation.libvirtd.qemuGuests;

  guestType = types.submodule {
    options = {
      config = mkOption {
        type = types.str;
        description = mdDoc ''
          libvirtd domain xml
        '';
      };

      autostart = mkOption {
        type = types.bool;
        default = false;
        description = mdDoc ''
          whether to start the guest on boot
        '';
      };
    };
  };

  writeValidatedXml = name: document:
    pkgs.runCommand "${name}.xml"
      ''
        echo ${document} > document.xml
        virt-xml-validate document.xml domain
        echo ${document} > $out
      '';

  tmpfilesPackage =
    let
      rules = mapAttrsToList
        (name: guest:
          let
            document = (writeValidatedXml name) guest.config;
            target =
              if guest.autostart
              then "/var/lib/libvirt/qemu/autostart/${name}.xml"
              else "/var/lib/libvirt/qemu/${name}.xml";
          in
          "L ${target} - - - - ${document}")
        cfg;
    in
    pkgs.writeText "libvirtd-guests" (concatStringsSep "\n" rules);

in
{
  ### Interface ###

  options.virtualisation.libvirtd.qemuGuests = mkOption {
    type = types.attrsOf (guestType);
    default = { };
    description = mdDoc ''
      libvirtd guests
    '';
  };

  ### Implementation ###

  config.systemd.tmpfiles.packages = [ tmpfilesPackage ];
}
