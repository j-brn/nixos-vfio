{ config
, lib
, pkgs
, ...
}:
with lib; let
  cfg = config.virtualisation.libvirtd.qemuGuests;
  qemuDir = "/var/lib/libvirtd/qemu";

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

  links = mapAttrsToList
    (name: guest:
      let
        document = writeValidatedXml name guest.config;
        target =
          if guest.autostart
          then "${qemuDir}/autostart/${name}.xml"
          else "${qemuDir}/${name}.xml";
      in
      { source = document; inherit target; })
    cfg;

  setupScript = concatStringsSep "\n" ([ "mkdir -p ${qemuDir}/autostart" ]
    ++ (map ({ source, target }: "ln -sf ${source} ${target}") links));

  cleanupScript = concatStringsSep "\n" (map ({ target, ... }: "rm ${target}") links);
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

  config.systemd.services.libvirtd = {
    preStart = setupScript;
    postStop = cleanupScript;
  };
}
