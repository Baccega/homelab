# Wolf – Games on Whales (Moonlight-compatible game streaming)
# Runs as a Podman container. Uses host network (required by upstream for
# streaming and discovery); other services on this host use the ipvlan
# network stack. NVENC via Nvidia 1050 Ti (container toolkit).
# Pair with Moonlight on Mac/Apple TV by adding this host's IP (e.g. 192.168.20.4).
#
# Ref: https://games-on-whales.github.io/wolf/stable/user/quickstart.html
{
  config,
  lib,
  ...
}:
{
  networking.firewall.allowedTCPPorts = [
    47984  # HTTPS
    47989  # HTTP (pairing)
    48010  # RTSP
  ];
  networking.firewall.allowedUDPPorts = [
    47999  # Control
    48100  # Video
    48200  # Audio
  ];

  # Wolf virtual input devices (uinput/uhid and virtual gamepads)
  services.udev.extraRules = ''
    # Allow Wolf to access /dev/uinput (joypad support)
    KERNEL=="uinput", SUBSYSTEM=="misc", MODE="0660", GROUP="input", OPTIONS+="static_node=uinput", TAG+="uaccess"
    # Allow Wolf to access /dev/uhid (DualSense emulation)
    KERNEL=="uhid", GROUP="input", MODE="0660", TAG+="uaccess"
    # Virtual joypads created by Wolf
    KERNEL=="hidraw*", ATTRS{name}=="Wolf PS5 (virtual) pad", GROUP="input", MODE="0660", ENV{ID_SEAT}="seat9"
    SUBSYSTEMS=="input", ATTRS{name}=="Wolf X-Box One (virtual) pad", MODE="0660", ENV{ID_SEAT}="seat9"
    SUBSYSTEMS=="input", ATTRS{name}=="Wolf PS5 (virtual) pad", MODE="0660", ENV{ID_SEAT}="seat9"
    SUBSYSTEMS=="input", ATTRS{name}=="Wolf gamepad (virtual) motion sensors", MODE="0660", ENV{ID_SEAT}="seat9"
    SUBSYSTEMS=="input", ATTRS{name}=="Wolf Nintendo (virtual) pad", MODE="0660", ENV{ID_SEAT}="seat9"
  '';

  # Ensure config directory exists for the container volume
  systemd.tmpfiles.rules = [
    "d /etc/wolf 0755 root root -"
  ];

  virtualisation.oci-containers.containers.wolf = {
    image = "ghcr.io/games-on-whales/wolf:stable";
    environment = {
      NVIDIA_DRIVER_CAPABILITIES = "all";
      NVIDIA_VISIBLE_DEVICES = "all";
    };
    volumes = [
      "/etc/wolf:/etc/wolf:rw"
      "/run/podman/podman.sock:/var/run/docker.sock:ro"
      "/dev:/dev:rw"
      "/run/udev:/run/udev:rw"
    ];
    devices = [
      "/dev/dri"
      "/dev/uinput"
      "/dev/uhid"
    ];
    # Host network required for Moonlight streaming; do not use ipvlan here.
    extraOptions = [
      "--network=host"
      "--device-cgroup-rule=c 13:* rmw"
      "--device=nvidia.com/gpu=all"
      "--label=io.containers.autoupdate=registry"
    ];
  };

  systemd.services.podman-wolf = {
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
  };
}
