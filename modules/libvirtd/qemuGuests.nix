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
    let
      validate = "${pkgs.libvirt}/bin/virt-xml-validate";
      xmlFile = pkgs.writeText "${name}.xml" document;
    in
    pkgs.runCommand "${name}.xml" { } ''${validate} ${xmlFile} && cp ${xmlFile} $out'';

  tmpfilesPackage =
    let
      rules = mapAttrsToList
        (name: guest:
          let
            document = writeValidatedXml name guest.config;
            target =
              if guest.autostart
              then "/var/lib/libvirt/qemu/autostart/${name}.xml"
              else "/var/lib/libvirt/qemu/${name}.xml";
          in
          "L+ ${target} - - - - ${document}")
        cfg;
    in
    pkgs.writeTextDir "lib/tmpfiles.d/libvirtd-guests.conf" (concatStringsSep "\n" rules);

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
  config.systemd.services.libvirtd.after = [ "systemd-tmpfiles-setup.service" ];
}
