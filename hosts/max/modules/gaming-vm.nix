# Bolt – gaming VM on Max (libvirt / NixVirt).
#
# Isolates Sunshine/Steam from the host: GTX 1050 Ti + its HDMI audio are bound
# to vfio-pci and passed through; Tesla P4 stays on the host for Ollama/etc.
# Networking is macvtap bridge on eno1 so bolt gets a real VLAN-20 IP (.50),
# same idea as the Podman ipvlan stack.
#
# Prerequisites (one-time):
#   1. Enable Intel VT-d / IOMMU in the motherboard BIOS (Max currently shows
#      0 IOMMU groups without it — passthrough will not work until this is on).
#   2. Deploy this host config, reboot so vfio claims 05:00.0 / 05:00.1.
#   3. Install NixOS into the bolt volume (see hosts/bolt), then:
#        virsh start bolt
#
# Virtual display/audio live in the *guest* (hosts/bolt), not here.
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  constants = import ../../../constants.nix;
  bolt = constants.hosts.bolt;
  nixvirt = inputs.nixvirt;

  # Stable UUIDs for libvirt objects (do not regenerate casually).
  domainUuid = "b0171050-b017-4000-8000-000000000050";
  poolUuid = "b0171050-b017-4000-8000-000000000001";
  volumeName = "${bolt.hostname}.qcow2";
  imagesDir = "/var/lib/libvirt/images";

  # Parse "0000:05:00.0" → domain/bus/slot/function for libvirt hostdev XML.
  parsePci = addr:
    let
      parts = lib.splitString ":" addr;
      df = lib.splitString "." (lib.elemAt parts 2);
    in {
      domain = "0x${lib.elemAt parts 0}";
      bus = "0x${lib.elemAt parts 1}";
      slot = "0x${lib.elemAt df 0}";
      function = "0x${lib.elemAt df 1}";
    };

  videoPci = parsePci bolt.gpu.video.address;
  audioPci = parsePci bolt.gpu.audio.address;

  poolXml = nixvirt.lib.pool.writeXML {
    name = "default";
    uuid = poolUuid;
    type = "dir";
    target = { path = imagesDir; };
  };

  volumeXml = nixvirt.lib.volume.writeXML {
    name = volumeName;
    capacity = { count = bolt.diskGiB; unit = "GiB"; };
  };

  domainXml = pkgs.writeText "bolt-domain.xml" ''
    <domain type="kvm">
      <name>${bolt.hostname}</name>
      <uuid>${domainUuid}</uuid>
      <memory unit="GiB">${toString bolt.memoryGiB}</memory>
      <currentMemory unit="GiB">${toString bolt.memoryGiB}</currentMemory>
      <vcpu placement="static">${toString bolt.vcpus}</vcpu>
      <os firmware="efi">
        <type arch="x86_64" machine="q35">hvm</type>
        <loader readonly="yes" type="pflash">/run/libvirt/nix-ovmf/edk2-x86_64-code.fd</loader>
        <nvram template="/run/libvirt/nix-ovmf/edk2-i386-vars.fd">/var/lib/libvirt/qemu/nvram/${bolt.hostname}_VARS.fd</nvram>
        <boot dev="hd"/>
      </os>
      <features>
        <acpi/>
        <apic/>
        <kvm>
          <hidden state="on"/>
        </kvm>
      </features>
      <cpu mode="host-passthrough" check="none" migratable="on">
        <topology sockets="1" dies="1" cores="${toString bolt.vcpus}" threads="1"/>
      </cpu>
      <clock offset="utc">
        <timer name="rtc" tickpolicy="catchup"/>
        <timer name="pit" tickpolicy="delay"/>
        <timer name="hpet" present="no"/>
      </clock>
      <on_poweroff>destroy</on_poweroff>
      <on_reboot>restart</on_reboot>
      <on_crash>destroy</on_crash>
      <devices>
        <emulator>/run/libvirt/nix-emulators/qemu-system-x86_64</emulator>
        <disk type="file" device="disk">
          <driver name="qemu" type="qcow2" discard="unmap"/>
          <source file="${imagesDir}/${volumeName}"/>
          <target dev="vda" bus="virtio"/>
          <address type="pci" domain="0x0000" bus="0x04" slot="0x00" function="0x0"/>
        </disk>
        <!-- macvtap bridge: appears as another host on VLAN 20 (eno1). -->
        <interface type="direct">
          <mac address="${bolt.mac}"/>
          <source dev="eno1" mode="bridge"/>
          <model type="virtio"/>
          <address type="pci" domain="0x0000" bus="0x01" slot="0x00" function="0x0"/>
        </interface>
        <serial type="pty">
          <target type="isa-serial" port="0">
            <model name="isa-serial"/>
          </target>
        </serial>
        <console type="pty">
          <target type="serial" port="0"/>
        </console>
        <channel type="unix">
          <target type="virtio" name="org.qemu.guest_agent.0"/>
          <address type="virtio-serial" controller="0" bus="0" port="1"/>
        </channel>
        <controller type="virtio-serial" index="0">
          <address type="pci" domain="0x0000" bus="0x03" slot="0x00" function="0x0"/>
        </controller>
        <controller type="pci" index="0" model="pcie-root"/>
        <controller type="pci" index="1" model="pcie-root-port">
          <model name="pcie-root-port"/>
          <target chassis="1" port="0x10"/>
          <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x0" multifunction="on"/>
        </controller>
        <controller type="pci" index="2" model="pcie-root-port">
          <model name="pcie-root-port"/>
          <target chassis="2" port="0x11"/>
          <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x1"/>
        </controller>
        <controller type="pci" index="3" model="pcie-root-port">
          <model name="pcie-root-port"/>
          <target chassis="3" port="0x12"/>
          <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x2"/>
        </controller>
        <controller type="pci" index="4" model="pcie-root-port">
          <model name="pcie-root-port"/>
          <target chassis="4" port="0x13"/>
          <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x3"/>
        </controller>
        <controller type="pci" index="5" model="pcie-root-port">
          <model name="pcie-root-port"/>
          <target chassis="5" port="0x14"/>
          <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x4"/>
        </controller>
        <controller type="pci" index="6" model="pcie-root-port">
          <model name="pcie-root-port"/>
          <target chassis="6" port="0x15"/>
          <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x5"/>
        </controller>
        <input type="mouse" bus="ps2"/>
        <input type="keyboard" bus="ps2"/>
        <!-- Headless: no emulated GPU. Use virsh console / SSH for management. -->
        <memballoon model="virtio">
          <address type="pci" domain="0x0000" bus="0x02" slot="0x00" function="0x0"/>
        </memballoon>
        <hostdev mode="subsystem" type="pci" managed="yes">
          <source>
            <address domain="${videoPci.domain}" bus="${videoPci.bus}" slot="${videoPci.slot}" function="${videoPci.function}"/>
          </source>
          <address type="pci" domain="0x0000" bus="0x05" slot="0x00" function="0x0"/>
        </hostdev>
        <hostdev mode="subsystem" type="pci" managed="yes">
          <source>
            <address domain="${audioPci.domain}" bus="${audioPci.bus}" slot="${audioPci.slot}" function="${audioPci.function}"/>
          </source>
          <address type="pci" domain="0x0000" bus="0x06" slot="0x00" function="0x0"/>
        </hostdev>
      </devices>
    </domain>
  '';
in
{
  # IOMMU + bind 1050 Ti (video+audio) to vfio before the host NVIDIA driver.
  # Tesla P4 (04:00.0) is intentionally left for the host.
  boot.kernelParams = [
    "intel_iommu=on"
    "iommu=pt"
    "vfio-pci.ids=${bolt.gpu.video.id},${bolt.gpu.audio.id}"
  ];
  boot.initrd.kernelModules = [
    "vfio_pci"
    "vfio"
    "vfio_iommu_type1"
  ];
  boot.kernelModules = [
    "vfio_pci"
    "vfio"
    "vfio_iommu_type1"
  ];

  # OVMF firmware comes from the QEMU package (/run/libvirt/nix-ovmf/edk2-*).
  virtualisation.libvirtd.qemu = {
    package = pkgs.qemu_kvm;
    runAsRoot = true;
  };

  virtualisation.libvirt = {
    enable = true;
    connections."qemu:///system" = {
      pools = [
        {
          definition = poolXml;
          active = true;
          volumes = [
            { definition = volumeXml; }
          ];
        }
      ];
      domains = [
        {
          definition = domainXml;
          # Keep off until NixOS is installed on the volume.
          active = false;
        }
      ];
    };
  };

  environment.systemPackages = with pkgs; [
    virt-manager
    qemu
    pciutils
  ];

  users.users.${constants.users.sandro.name}.extraGroups = [
    "libvirtd"
    "kvm"
  ];

  # Ensure NVRAM dir exists for OVMF vars.
  systemd.tmpfiles.rules = [
    "d /var/lib/libvirt/qemu/nvram 0755 root root -"
    "d ${imagesDir} 0755 root root -"
  ];
}
