{ lib, pkgs, config, ... }:

with lib;

let
  cfg = config.virtualisation.libvirtd.qemu.networks;

  networkType = with types;
    (submodule ({ name, config, options, ... }: {
      options = {
        config = mkOption {
          type = nullOr (submodule {
            options = {
              bridge = mkOption {
                type = (submodule {
                  options = {
                    name = mkOption {
                      type = str;
                      description = mdDoc ''
                        Defines the name of a bridge device which will be used to
                        construct the virtual network. The virtual machines will be connected to this bridge device allowing
                        them to talk to each other. The bridge device may also be connected to the LAN. When defining a new
                        network with a <forward> mode of "nat", "route", or "open"
                        (or an isolated network with no <forward> element), libvirt will automatically generate a unique name
                        for the bridge device if none is given, and this name will be permanently stored in the network
                        configuration so that that the same name will be used every time the network is started. For these types
                        of networks (nat, route, open, and isolated), a bridge name beginning with the prefix "virbr" is
                        recommended (and that is what is auto-generated), but not enforced.
                      '';
                    };
                  };
                });
              };

              mtu = mkOption {
                type = submodule {
                  options = {
                    size = mkOption {
                      type = nullOr ints.positive;
                      default = null;
                      description = mdDoc ''
                        Specifies the Maximum Transmission Unit (MTU) for the network. In the case of a libvirt-managed network
                        (one with forward mode of nat, route, open, or no forward element (i.e. an isolated network), this will
                        be the MTU assigned to the bridge device when libvirt creates it, and thereafter also assigned to all
                        tap devices created to connect guest interfaces. Network types not specifically mentioned here don't
                        support having an MTU set in the libvirt network config. If mtu size is unspecified, the default
                        setting for the type of device being used is assumed (usually 1500).
                      '';
                    };
                  };
                };

                default = { };
              };

              forward = mkOption {
                type = nullOr (submodule {
                  options = {
                    mode = mkOption {
                      type = enum [
                        "nat"
                        "route"
                        "open"
                        "bridge"
                        "private"
                        "vepa"
                        "passthrough"
                        "hostdev"
                      ];
                      default = "nat";
                      description = mdDoc ''
                        Determines the method of forwarding. If there is no forward element, the network will be isolated from
                        any other network (unless a guest connected to that network is acting as a router, of course).
                        The following are valid settings for mode (if there is a forward element but mode
                        is not specified, mode='nat' is assumed)
                      '';
                    };

                    dev = mkOption {
                      type = nullOr str;
                      default = null;
                      description = mdDoc ''
                        If set, the firewall rules will restrict forwarding to the named device only. Inbound connections
                        from other networks are all prohibited; all connections between guests on the same network, and
                        to/from the host to the guests, are unrestricted and not NATed
                      '';
                    };
                  };
                });

                default = null;
              };

              ips = mkOption {
                type = listOf (submodule {
                  options = {
                    address = mkOption {
                      type = str;
                      description = mdDoc ''
                        Defines an IPv4 address in dotted-decimal format, or an IPv6 address in standard colon-separated
                        hexadecimal format, that will be configured on the bridge device associated with the virtual network.
                        To the guests this IPv4 address will be their IPv4 default route. For IPv6, the default route is
                        established via Router Advertisement.
                      '';
                    };

                    prefix = mkOption {
                      type = ints.positive;
                      description = mdDoc ''
                        Specifies the significant bits of the network address.
                      '';
                    };

                    family = mkOption {
                      type = enum [ "ipv4" "ipv6" ];
                      default = "ipv4";
                      description = mdDoc ''
                        Used to specify the type of address - ipv4 or ipv6; if no family is given, ipv4 is assumed.
                      '';
                    };

                    dhcpRanges = mkOption {
                      type = listOf (submodule {
                        options = {
                          start = mkOption {
                            type = str;
                            description = mdDoc ''
                              Lower boundary of the DHCP range.
                            '';
                          };

                          end = mkOption {
                            type = str;
                            description = mdDoc ''
                              Upper boundary of the DHCP range.
                            '';
                          };
                        };
                      });

                      default = [ ];
                    };
                  };
                });
              };
            };
          });
          default = null;
          description = mdDoc ''
            Nix definition of the network. Overrides xml if set.
          '';
        };

        xml = mkOption {
          type = str;
          description = mdDoc ''
            Raw XML definition of the network. Will be overridden by config, if set.
          '';
        };

        autostart = mkOption {
          type = bool;
          default = false;
          description = mdDoc ''
            Whether to start the domain on boot.
          '';
        };
      };

      config = {
        xml = mkIf (config.config != null) (mkNetworkXml name config.config);
      };
    }));

  mkNetworkXml = name: config: ''
    <network>
      <name>${name}</name>
      ${
        optionalString (config.bridge != null)
        ''<bridge name="${config.bridge.name}"/>''
      }
      ${
        optionalString (config.forward != null) ''
          <forward mode="${config.forward.mode}" ${
            optionalString (config.forward.dev != null)
            ''dev="${config.forward.dev}"''
          }/>
        ''
      }
      ${
        concatStringsSep "\n" (map (ip: ''
          <ip
            family="${ip.family}"
            address="${ip.address}"
            prefix="${toString ip.prefix}"
          >
            ${
              optionalString (ip.dhcpRanges != [ ]) ''
                <dhcp>
                  ${
                    concatStringsSep "\n" (map (range: ''
                      <range start="${range.start}" end="${range.end}"/>
                    '') ip.dhcpRanges)
                  }
                </dhcp>
              ''
            }
          </ip>
        '') config.ips)
      }
    </network>
  '';

  mkNetworkXmlPackage = name: config:
    pkgs.runCommand "libvirt-network-${name}.xml" { } ''
      mkdir $out
      echo '${config.xml}' > network.xml
      ${pkgs.libxml2}/bin/xmllint --format network.xml > $out/network.xml
      ${pkgs.libvirt}/bin/virt-xml-validate $out/network.xml
    '';

  defineNetworksScript = let
    xmlPackages = mapAttrs mkNetworkXmlPackage cfg.networks;
    commands = mapAttrsToList (name: xmlPackage: ''
      ln -s ${xmlPackage}/network.xml /var/lib/libvirt/qemu/networks/${name}.xml
    '') xmlPackages;
  in concatStringsSep "\n" commands;

  autostartNetworksScript = let
    domainsToAutostart = mapAttrsToList (name: _: name)
      (filterAttrs (_: network: network.autostart) cfg.networks);
    commands = map (name: ''
      ln -s /var/lib/libvirt/qemu/networks/${name}.xml /var/lib/libvirt/qemu/networks/autostart/${name}.xml
    '') domainsToAutostart;
  in concatStringsSep "\n" commands;
in {
  options.virtualisation.libvirtd.qemu.networks = {
    declarative = mkOption {
      type = types.bool;
      default = false;
      description = mdDoc ''
        Whether to enable declarative qemu networks. WARNING: If this option is enabled, the module asumes beeing
        the only source of truth and will purge any network not created by this module.
      '';
    };

    networks = mkOption {
      type = types.attrsOf networkType;
      default = { };
      description = mdDoc ''
        declarative libvirt virtual networks
      '';
    };
  };

  config = mkIf cfg.declarative {
    systemd.services.libvirtd-config.wantedBy = [ "multi-user.target" ];
    systemd.services.libvirtd-config.script = lib.mkAfter ''
      mkdir -p /var/lib/libvirt/qemu/networks
      mkdir -p /var/lib/libvirt/qemu/networks/autostart

      rm -f /var/lib/libvirt/qemu/networks/*.xml
      rm -f /var/lib/libvirt/qemu/networks/autostart/*.xml

      ${defineNetworksScript}
      ${autostartNetworksScript}
    '';
  };
}
