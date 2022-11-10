{ config
, lib
, pkgs
, ...
}:
with lib; let
  cfg = config.virtualisation.libvirtd.qemuGuests;
  qemuDir = "/var/lib/libvirtd/qemu";
  virsh = "${pkgs.libvirt}/bin/virsh";

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

      undefineOnCleanup = mkOption {
        type = types.bool;
        default = false;
        description = mdDoc ''
          whether the domain should be undefined when libvirtd shuts down
        '';
      };
    };
  };

  defineDomainsScript =
    concatStringsSep
      "\n"
      (mapAttrsToList
        (name: guest:
          let
            xmlFile = pkgs.writeText "${name}.xml" guest.config;
          in
          ''${virsh} define ${xmlFile}'')
        cfg);

  autostartDomainsScript =
    let
      domainsToAutostart = filterAttrs (name: guest: guest.autostart) cfg;
    in
    concatStringsSep
      "\n"
      (mapAttrsToList
        (name: guest: "${virsh} autostart ${name}")
        domainsToAutostart);

  undefineDomainsScript =
    let
      domainsToUndefine = filterAttrs (name: guest: guest.undefineOnCleanup) cfg;
    in
    concatStringsSep
      "\n"
      (mapAttrsToList
        (name: guest: "${virsh} undefine ${name}")
        domainsToUndefine);

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

  config.systemd.services.define-libvirtd-domains = {
    description = "defines libvirtd domains";
    serviceConfig.Type = "oneshot";
    after = [ "libvirtd.service" ];
    wantedBy = [ "multi-user.target" ];
    script = defineDomainsScript;
  };

  config.systemd.services.autostart-libvirtd-domains = {
    description = "configures autostart for libvirtd domains";
    serviceConfig.Type = "oneshot";
    after = [ "define-libvirtd-domains.service" ];
    wantedBy = [ "multi-user.target" ];
    script = autostartDomainsScript;
  };

  config.systemd.services.libvirtd.preStop = undefineDomainsScript;
}
