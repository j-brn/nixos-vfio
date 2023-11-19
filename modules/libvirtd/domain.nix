{ lib, pkgs, config, ... }:

with lib;

let
  cfg = config.virtualisation.libvirtd.domains.qemu;

  memoryOptionsType = let
    memoryType = types.submodule {
      options = {
        value = mkOption {
          type = types.number;
          description = mdDoc ''
            value
          '';
        };

        unit = mkOption {
          type = types.enum [
            "b"
            "bytes"
            "KB"
            "k"
            "KiB"
            "MB"
            "M"
            "MiB"
            "GB"
            "G"
            "GiB"
            "TB"
            "T"
            "TiB"
          ];
          description = mdDoc ''
            unit
          '';
        };
      };
    };
  in types.submodule {
    options = {
      memory = mkOption {
        type = memoryType;
        description = mdDoc ''
          Maximum allocation for the guest at boot time.
          See https://libvirt.org/formatdomain.html#memory-allocation for details
        '';
      };

      disableBallooning = mkOption {
        type = types.bool;
        default = true;
        description = mdDoc ''
          Whether to disable ballooning
        '';
      };

      useHugepages = mkOption {
        type = types.bool;
        default = false;
        description = mdDoc ''
          Whether to use hugepages.
        '';
      };
    };
  };

  osOptionsType = types.submodule {
    options = {
      arch = mkOption {
        type = types.str;
        default = "x86_64";
        description = mdDoc ''
          Machine architecture
        '';
      };

      machine = mkOption {
        type = types.str;
        default = "pc-q35-5.2";
        description = mdDoc ''
          Machine type to use. See https://libvirt.org/formatcaps.html for details
        '';
      };

      enableBootmenu = mkOption {
        type = types.bool;
        default = false;
        description = mdDoc ''
          Whether to enable the bootmenu
        '';
      };
    };
  };

  vcpuOptionsType = types.submodule {
    options = {
      count = mkOption {
        type = types.ints.positive;
        description = mdDoc ''
          Amount of vcpus to allocate.
        '';
      };

      placement = mkOption {
        type = types.enum [ "auto" "static" ];
        description = mdDoc ''
          vcpu placment. See https://libvirt.org/formatdomain.html#cpu-allocation for details
        '';
      };
    };
  };

  cputuneOptionsType = let
    vcpupinType = types.submodule {
      options = {
        vcpu = mkOption {
          type = types.ints.positive;
          description = mdDoc ''
            vcpu to pin
          '';
        };

        cpuset = mkOption {
          type = types.listOf types.ints.positive;
          description = mdDoc ''
            Comma separated list of cpus this vcpu can be pinned to.
          '';
        };
      };
    };

    iothreadpinType = types.submodule {
      options = {
        iothread = mkOption {
          type = types.ints.positive;
          description = mdDoc ''
            iothread to pin
          '';
        };

        cpuset = mkOption {
          type = types.listOf types.ints.positive;
          description = mdDoc ''
            Comma separated list of cpus this iothread can be pinned to.
          '';
        };
      };
    };

    emulatorpinType = types.submodule {
      options = {
        cpuset = mkOption {
          type = types.listOf types.ints.positive;
          description = mdDoc ''
            Comma separated list of cpus the emulator can be pinned to.
          '';
        };
      };
    };
  in types.submodule {
    options = {
      vcpupins = mkOption {
        type = types.listOf vcpupinType;
        default = [ ];
        description = mdDoc ''
          vcpupins
        '';
      };

      iothreadpins = mkOption {
        type = types.listOf iothreadpinType;
        default = [ ];
        description = mdDoc ''
          iothreadpins
        '';
      };

      emulatorpin = mkOption {
        type = types.nullOr emulatorpinType;
        default = null;
        description = mdDoc ''
          emulatorpin
        '';
      };
    };
  };

  cpuOptionsType = let
    topologyType = types.submodule {
      options = {
        sockets = mkOption {
          type = types.ints.positive;
          default = 1;
          description = mdDoc ''
            number of sockets
          '';
        };

        dies = mkOption {
          type = types.ints.positive;
          default = 1;
          description = mdDoc ''
            number of dies
          '';
        };

        cores = mkOption {
          type = types.ints.positive;
          default = 1;
          description = mdDoc ''
            number of cores
          '';
        };

        threads = mkOption {
          type = types.ints.positive;
          default = 1;
          description = mdDoc ''
            number of threads
          '';
        };
      };
    };
  in types.submodule {
    options = {
      mode = mkOption {
        type = types.str;
        default = "host-passthrough";
        description = mdDoc ''
          CPu mode
        '';
      };

      topology = mkOption {
        type = topologyType;
        description = mdDoc ''
          CPU topology
        '';
      };

      enableTopoext = mkOption {
        type = types.bool;
        default = true;
        description = mdDoc ''
          Whether to enable topoext
        '';
      };

      cacheMode = mkOption {
        type = types.enum [ "emulate" "passthrough" "disable" ];
        default = "passthrough";
        description = mdDoc ''
          Cache mode
        '';
      };
    };
  };

  inputOptionsType = types.submodule {
    options = {
      virtioMouse = mkOption {
        type = types.bool;
        default = true;
        description = mdDoc ''
          Whether to add a virtio mouse
        '';
      };

      virtioKeyboard = mkOption {
        type = types.bool;
        default = true;
        description = mdDoc ''
          Whether to add a virtio keyboard
        '';
      };
    };
  };

  spiceOptionsType = types.submodule {
    options = {
      spiceAudio = mkOption {
        type = types.bool;
        default = true;
        description = mdDoc ''
          Whether to add a spice audio device
        '';
      };

      spicemvcChannel = mkOption {
        type = types.bool;
        default = true;
        description = mdDoc ''
          Whether to add a spicemvc channel
        '';
      };

      spiceGraphics = mkOption {
        type = types.bool;
        default = true;
        description = mdDoc ''
          Whether to add a spice video device
        '';
      };
    };
  };

  pciHostdevType = let
    addressType = types.submodule {
      options = {
        domain = mkOption {
          type = types.str;
          default = "0x0000";
          description = mdDoc ''
            2-byte hex integer, not currently used by qemu
          '';
        };

        bus = mkOption {
          type = types.str;
          description = mdDoc ''
            hex value between 0 and 0xff, inclusive
          '';
        };

        slot = mkOption {
          type = types.str;
          description = mdDoc ''
            hex value between 0x0 and 0x1f, inclusive
          '';
        };

        function = mkOption {
          type = types.ints.positive;
          apply = value: toString value;
          description = mdDoc ''
            a value between 0 and 7, inclusive
          '';
        };
      };
    };
  in types.submodule {
    options = {
      sourceAddress = mkOption {
        type = addressType;
        description = mdDoc ''
          source address of the pci device
        '';
      };

      bootIndex = mkOption {
        type = types.nullOr types.ints.positive;
        default = null;
        description = mdDoc ''
          index in the boot order for this device
        '';
      };
    };
  };

  networkInterfaceType = types.submodule {
    options = {
      macAddress = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = mdDoc ''
          Mac address to use for this interface
        '';
      };

      sourceNetwork = mkOption {
        type = types.str;
        description = mdDoc ''
          Source network to use for this interface
        '';
      };

      bootIndex = mkOption {
        type = types.nullOr types.ints.positive;
        default = null;
        description = mdDoc ''
          index in the boot order for this device
        '';
      };
    };
  };

  cdromType = types.submodule {
    options = {
      sourceFile = mkOption {
        type = types.str;
        description = mdDoc ''
          Path to the source file
        '';
      };

      target = mkOption {
        type = types.submodule {
          options = {
            device = mkOption {
              type = types.str;
              default = "sda";
              description = mdDoc ''
                target device
              '';
            };

            bus = mkOption {
              type = types.str;
              default = "sata";
              description = mdDoc ''
                target bus
              '';
            };
          };
        };
        default = { };
      };

      bootIndex = mkOption {
        type = types.nullOr types.ints.positive;
        default = null;
        description = mdDoc ''
          index in the boot order for this device
        '';
      };
    };
  };

  kvmfrOptionsType = types.submodule {
    options = {
      device = mkOption {
        type = types.str;
        default = "/dev/kvmfr0";
        description = mdDoc ''
          kvmfr device to use
        '';
      };

      size = mkOption {
        type = types.str;
        description = mdDoc ''
          Size of the kvmfr device
        '';
      };
    };
  };

  domainDefinitionType = types.submodule {
    options = {
      memory = mkOption {
        type = memoryOptionsType;
        description = ''
          Memory configuration. See https://libvirt.org/formatdomain.html#memory-allocation for details.
        '';
      };

      os = mkOption {
        type = osOptionsType;
        default = { };
        description = ''
          OS configuration. See https://libvirt.org/formatdomain.html#operating-system-booting for details.
        '';
      };

      vcpu = mkOption {
        type = vcpuOptionsType;
        description = mdDoc ''
          vCPU allocation. See https://libvirt.org/formatdomain.html#cpu-allocation for details
        '';
      };

      cputune = mkOption {
        type = types.nullOr cputuneOptionsType;
        default = { };
        description = mdDoc ''
          CPU tuning options. See https://libvirt.org/formatdomain.html#cpu-tuning for details
        '';
      };

      cpu = mkOption {
        type = cpuOptionsType;
        default = { };
        description = mdDoc ''
          CPU and topology settings. See https://libvirt.org/formatdomain.html#cpu-model-and-topology for details
        '';
      };

      input = mkOption {
        type = inputOptionsType;
        default = { };
        description = mdDoc ''
          Configure input devices
        '';
      };

      spice = mkOption {
        type = spiceOptionsType;
        description = mdDoc ''
          Configure spice
        '';
      };

      pciHostDevices = mkOption {
        type = types.listOf pciHostdevType;
        default = [ ];
        description = mdDoc ''
          PCI host devices
        '';
      };

      networkInterfaces = mkOption {
        type = types.listOf networkInterfaceType;
        default = [ ];
        description = mdDoc ''
          Network interfaces
        '';
      };

      cdroms = mkOption {
        type = types.listOf cdromType;
        default = [ ];
        description = mdDoc ''
          CDROMs to attach to the domain
        '';
      };

      kvmfr = mkOption {
        type = types.nullOr kvmfrOptionsType;
        description = mdDoc ''
          kvmfr settings
        '';
      };

      extraXml = mkOption {
        type = types.str;
        default = "";
        description = mdDoc ''
          extra XML appended to the generated domain
        '';
      };
    };
  };

  domainType = types.submodule {
    options = {
      definition = mkOption {
        type = domainDefinitionType;
        description = mdDoc ''
          Definition of the domain
        '';
      };

      autostart = mkOption {
        type = types.bool;
        default = false;
        description = mdDoc ''
          Whether to start the domain on boot.
        '';
      };
    };

  };

  mkDomainXml = let
    mkMemoryXml = memory: ''
      <memory unit="${memory.memory.unit}">${
        toString memory.memory.value
      }</memory>

      ${optionalString memory.useHugepages ''
        <memoryBacking>
          <hugepages/>
        </memoryBacking>
      ''}
    '';

    mkVcpuXml = cfg: ''
      <vcpu placement="${cfg.placement}">${toString cfg.count}</vcpu>
    '';

    mkCputuneXml = let
      concatCpuset = cpuset:
        concatStringsSep "," (map (value: toString value) cpuset);
    in cfg: ''
      <cputune>
        ${
          concatStringsSep "\n" (map (pin: ''
            <vcpupin vcpu="${toString pin.vcpu}" cpuset="${
              concatCpuset pin.cpuset
            }"/>
          '') cfg.vcpupins)
        }
        ${
          concatStringsSep "\n" (map (pin: ''
            <iothreadpin iothread="${pin.iothread}" cpuset="${
              concatCpuset pin.cpuset
            }"/>
          '') cfg.iothreadpins)
        }
        ${
          optionalString (cfg.emulatorpin != null) ''
            <emulatorpin cpuset=${concatCpuset cfg.emulatorpin.cpuset} />
          ''
        }
      </cputune>
    '';

    mkCpuTopologyXml = let
      mkTopologyXml = topology: ''
        <topology
          sockets="${toString topology.sockets}"
          dies="${toString topology.dies}"
          cores="${toString topology.cores}"
          threads="${toString topology.threads}"
        />
      '';
    in cfg: ''
      <cpu mode="${cfg.mode}">
        ${mkTopologyXml cfg.topology}
        <cache mode="${cfg.cacheMode}"/>
        ${
          optionalString cfg.enableTopoext ''
            <feature policy="require" name="topoext"/>
          ''
        }
      </cpu>
    '';

    mkInputDevicesXml = cfg: ''
      ${optionalString cfg.virtioKeyboard ''
        <input type="keyboard" bus="virtio" />
      ''}

      ${optionalString cfg.virtioMouse ''
        <input type="mouse" bus="virtio" />
      ''}
    '';

    mkSpiceDevicesXml = cfg: ''
      ${optionalString cfg.spiceAudio ''
        <graphics type="spice" port="-1" tlsPort="-1" autoport="yes">
          <image compression="off"/>
        </graphics>

        <sound model="ich9">
          <audio id="1"/>
        </sound>
        <audio id="1" type="spice"/>
      ''}

      <video>
        <model type="${if cfg.spiceGraphics then "cirrus" else "none"}"/>
      </video>
    '';

    mkPciHostDevicesXml = let
      mkHostdevXml = dev: ''
        <hostdev mode="subsystem" type="pci" managed="yes">
          <driver name="vfio"/>
          <source>
            <address
              domain="${dev.sourceAddress.domain}"
              bus="${dev.sourceAddress.bus}"
              slot="${dev.sourceAddress.slot}"
              function="${toString dev.sourceAddress.function}"
            />
          </source>
          ${
            optionalString (dev.bootIndex != null) ''
              <boot order="${toString dev.bootIndex}"/>
            ''
          }
        </hostdev>
      '';
    in cfg: concatStringsSep "\n" (map (device: mkHostdevXml device) cfg);

    mkNetworkInterfaceDevicesXml = let
      mkInterfaceXml = interface: ''
        <interface type="network">
          ${
            optionalString (interface.macAddress != null) ''
              <mac address="${interface.macAddress}"/>
            ''
          }

          <model type="virtio" />
          <source network="${interface.sourceNetwork}"/>
          ${
            optionalString (interface.bootIndex != null) ''
              <boot order="${toString interface.bootIndex}"/>
            ''
          }
        </interface>
      '';
    in interfaces: concatStringsSep "\n" (map (mkInterfaceXml) interfaces);

    mkCdromDevicesXml = let
      mkCdromXml = cdrom: ''
        <disk type="file" device="cdrom">
          <driver name="qemu" type="raw"/>
          <source file="${cdrom.sourceFile}"/>
          <target dev="${cdrom.target.device}" bus="${cdrom.target.bus}"/>
          ${
            optionalString (cdrom.bootIndex != null) ''
              <boot order="${toString cdrom.bootIndex}"/>
            ''
          }
          <readonly/>
        </disk>
      '';
    in cdroms: concatStringsSep "\n" (map (mkCdromXml) cdroms);

    mkKvmfrXml = cfg: ''
      <qemu:commandline>
        <qemu:arg value="-device"/>
        <qemu:arg value="{&quot;driver&quot;:&quot;ivshmem-plain&quot;,&quot;id&quot;:&quot;shmem0&quot;,&quot;memdev&quot;:&quot;looking-glass&quot;}"/>
        <qemu:arg value="-object"/>
        <qemu:arg value="{&quot;qom-type&quot;:&quot;memory-backend-file&quot;,&quot;id&quot;:&quot;looking-glass&quot;,&quot;mem-path&quot;:&quot;${cfg.device}&quot;,&quot;size&quot;:${cfg.size},&quot;share&quot;:true}"/>
      </qemu:commandline>
    '';
  in name: definition: ''
    <domain xmlns:qemu="http://libvirt.org/schemas/domain/qemu/1.0" type="kvm">
      <name>${name}</name>

      <os>
        <type arch="${definition.os.arch}" machine="${definition.os.machine}">hvm</type>
        <loader readonly="yes" type="pflash">/run/libvirt/nix-ovmf/OVMF_CODE.fd</loader>
        <nvram template="/run/libvirt/nix-ovmf/OVMF_VARS.fd">/var/lib/libvirt/qemu/nvram/${name}_VARS.fd</nvram>
        <bootmenu enable="${
          if definition.os.enableBootmenu then "yes" else "no"
        }"/>
      </os>

      ${mkMemoryXml definition.memory}
      ${mkVcpuXml definition.vcpu}
      ${mkCputuneXml definition.cputune}
      ${mkCpuTopologyXml definition.cpu}

      <features>
        <acpi/>
        <apic/>
        <hyperv mode="custom">
          <relaxed state="on"/>
          <vapic state="on"/>
          <spinlocks state="on" retries="8191"/>
          <vpindex state="on"/>
          <runtime state="on"/>
          <synic state="on"/>
          <stimer state="on">
            <direct state="on"/>
          </stimer>
          <reset state="on"/>
          <vendor_id state="on" value="other"/>
          <frequencies state="on"/>
          <reenlightenment state="on"/>
          <tlbflush state="on"/>
          <ipi state="on"/>
          <evmcs state="off"/>
        </hyperv>
        <kvm>
          <hidden state="on"/>
        </kvm>
        <vmport state="off"/>
      </features>

      <clock offset="localtime">
        <timer name="rtc" tickpolicy="catchup"/>
        <timer name="pit" tickpolicy="delay"/>
        <timer name="hpet" present="no"/>
        <timer name="hypervclock" present="yes"/>
        <timer name="tsc" present="yes" mode="native"/>
      </clock>

      <on_poweroff>destroy</on_poweroff>
      <on_reboot>restart</on_reboot>
      <on_crash>destroy</on_crash>

      <pm>
        <suspend-to-mem enabled="no"/>
        <suspend-to-disk enabled="no"/>
      </pm>

      <devices>
        <emulator>/run/libvirt/nix-emulators/qemu-system-${definition.os.arch}</emulator>
        <controller type="usb" model="qemu-xhci" ports="15"/>
        <controller type="pci" model="pcie-root"/>
        <controller type="pci" model="pcie-root-port"/>
        <controller type="pci" model="pcie-root-port"/>
        <controller type="pci" model="pcie-root-port"/>
        <controller type="pci" model="pcie-root-port"/>
        <controller type="pci" model="pcie-root-port"/>
        <controller type="pci" model="pcie-root-port"/>
        <controller type="pci" model="pcie-root-port"/>
        <controller type="pci" model="pcie-root-port"/>
        <controller type="pci" model="pcie-root-port"/>
        <controller type="pci" model="pcie-root-port"/>
        <controller type="pci" model="pcie-root-port"/>
        <controller type="pci" model="pcie-root-port"/>
        <controller type="pci" model="pcie-root-port"/>
        <controller type="pci" model="pcie-root-port"/>
        <controller type="sata"/>
        <controller type="scsi"/>

        ${mkInputDevicesXml definition.input}
        ${mkSpiceDevicesXml definition.spice}
        ${mkPciHostDevicesXml definition.pciHostDevices}
        ${mkNetworkInterfaceDevicesXml definition.networkInterfaces}
        ${mkCdromDevicesXml definition.cdroms}

        ${
          optionalString definition.memory.disableBallooning ''
            <memballoon model="none"/>
          ''
        }
        ${
          optionalString definition.spice.spicemvcChannel ''
            <channel type="spicevmc">
              <target type="virtio" name="com.redhat.spice.0"/>
            </channel>
          ''
        }
      </devices>

      ${optionalString (definition.kvmfr != null) mkKvmfrXml definition.kvmfr}
      ${definition.extraXml}
    </domain>
  '';

  mkDomainXmlPackage = name: definition:
    pkgs.runCommand "libvirt-domain-${name}.xml" { } ''
      mkdir $out

      echo '${mkDomainXml name definition}' > $domain.xml
      ${pkgs.libxml2}/bin/xmllint --format $domain.xml > $out/domain.xml
      cat $out/domain.xml
      ${pkgs.libvirt}/bin/virt-xml-validate $out/domain.xml
    '';

  defineDomainsScript = let
    xmlPackages = mapAttrsToList mkDomainXmlPackage
      (mapAttrs (_: domain: domain.definition) cfg.domains);
    commands = map (xmlPackage: ''
      ${pkgs.libvirt}/bin/virsh define ${xmlPackage}/domain.xml;
    '') xmlPackages;
  in concatStringsSep "\n" commands;

  autostartDomainsScript = let
    domainsToAutostart = mapAttrsToList (name: _: name)
      (filterAttrs (_: domain: domain.autostart) cfg.domains);
    commands = map (domainName: ''
      ${pkgs.libvirt}/bin/virsh autostart ${name}
    '') domainsToAutostart;
  in concatStringsSep "\n" commands;

  purgeDomainsScript = ''
    ${pkgs.libvirt}/bin/virsh list --name | xargs --no-run-if-empty ${pkgs.libvirt}/bin/virsh undefine
  '';
in {
  options.virtualisation.libvirtd.domains.qemu = {
    declarative = mkOption {
      type = types.bool;
      default = false;
      description = mdDoc ''
        Whether to enable declarative qemu domains. WARNING: If this option is enabled, the module asumes beeing
        the only source of truth and will purge any domain no created by this module.
      '';
    };

    domains = mkOption {
      type = types.attrsOf domainType;
      default = { };
      description = mdDoc ''
        delcarative libvirtd qemu domains
      '';
    };
  };

  config = mkIf cfg.declarative {
    systemd.services = {
      libvirtd-purge-domains = {
        description = "purge existing libvirtd domains";
        serviceConfig = { Type = "oneshot"; };
        after = [ "libvirtd.service" ];
        wantedBy = [ "multi-user.target" ];
        script = purgeDomainsScript;
      };

      libvirtd-define-declarative-domains = {
        description = "define declarative libvirtd domains";
        serviceConfig = { Type = "oneshot"; };
        after = [ "libvirtd-purge-domains.service" ];
        wantedBy = [ "multi-user.target" ];
        script = defineDomainsScript;
      };

      libvirtd-autostart-declarative-domains = {
        description = "configure autostart for declarative libvirtd domains";
        serviceConfig = { Type = "oneshot"; };
        after = [ "libvirtd-define-declarative-domains.service" ];
        wantedBy = [ "multi-user.target" ];
        script = autostartDomainsScript;
      };
    };
  };
}
