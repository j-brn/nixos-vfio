{ config
, lib
, pkgs
, ...
}:
with lib; let
  cfg = config.virtualisation.libvirtd.qemuGuests;

  questType = types.submodule {
    options = {
      config = mkOption {
        type = types.str;
        descripton = mdDoc ''
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
            document = writeValidatedXml name guest.config;
            target = "/var/libvirt/qemu/" + (optional (guest.autostart) "autostart/") + "${name.xml}";
          in
          "L ${target} - - - - ${document}");
    in
    pkgs.writeTextFile "libvirtd-guests" concatStringsSep "\n" rules;

in
{
  ### Interface ###

  options.virtualisation.libvirtd.qemuGuests = mkOption {
    type = attrsOf (guestType);
    default = { };
    description = mdDoc ''
      libvirtd guests
    '';
  };

  ### Implementation ###

  systemd.tmpfiles.packages = [ tmpfilesPackage ];
}
