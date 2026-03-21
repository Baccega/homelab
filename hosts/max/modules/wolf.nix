# Wolf – Games on Whales (Moonlight-compatible game streaming)
# Runs as a Podman container. Uses host network (required by upstream for
# streaming and discovery); other services on this host use the ipvlan
# network stack. Nvidia: Wolf needs matching userspace libs at /usr/nvidia
# (NVIDIA_DRIVER_VOLUME_NAME + Podman volume). We fill nvidia-driver-vol from
# hardware.nvidia.package on each boot when the store path changes; without that,
# EGL hits Mesa/Zink and encoders fall back to software x264/x265.
# Ref: https://games-on-whales.github.io/wolf/stable/user/quickstart.html (Podman → Nvidia)
# Pair with Moonlight on Mac/Apple TV by adding this host's IP (e.g. 192.168.20.4).
#
# Default config (with Steam in the "User" profile) is deployed once; Wolf
# then owns the file for pairings. Add more apps in /etc/wolf/cfg/config.toml.
#
# Direct Steam game launch: copy the Steam app block, set title and
#   STEAM_STARTUP_FLAGS=steam://rungameid/APPID (get APPID from steamdb.info).
# App data on host: /etc/wolf/profile_data/${profile_id}/${app_title}.
# Steam first-run may need: mk_steam_dir.sh <profile_id> (see Steam docs;
#   script uses profile-data/ path). Shared library: mounts = [ '/path/to/steamapps:/home/retro/.steam/debian-installation/steamapps:rw' ].
#
# Refs:
#   https://games-on-whales.github.io/wolf/stable/user/quickstart.html
#   https://games-on-whales.github.io/wolf/stable/user/configuration.html
#   https://games-on-whales.github.io/wolf/stable/apps/steam.html
{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Default config deployed only when /etc/wolf/cfg/config.toml does not exist
  # (so we do not overwrite paired_clients after first run).
  wolfDefaultConfig = pkgs.writeText "wolf-config.toml" ''
    hostname = "wolf"
    support_hevc = true
    config_version = 2
    uuid = "0f75f4d1-e28e-410a-b318-c0579f18f8d1"
    paired_clients = []
    gstreamer = {}

    [[profiles]]
    id = "moonlight-profile-id"

        [[profiles.apps]]
        title = "Wolf UI"
        start_virtual_compositor = true
        icon_png_path = "https://raw.githubusercontent.com/games-on-whales/wolf-ui/refs/heads/main/src/Icons/wolf_ui_icon.png"

            [profiles.apps.runner]
            type = "docker"
            name = "Wolf-UI"
            image = "ghcr.io/games-on-whales/wolf-ui:main"
            devices = ["/dev/dri:/dev/dri", "/dev/input:/dev/input"]
            env = [
                "GOW_REQUIRED_DEVICES=/dev/input/event* /dev/dri/* /dev/nvidia*",
                "WOLF_SOCKET_PATH=/var/run/wolf/wolf.sock",
                "WOLF_UI_AUTOUPDATE=False",
                "LOGLEVEL=INFO"
            ]
            mounts = ["/var/run/wolf/wolf.sock:/var/run/wolf/wolf.sock"]
            ports = []
            base_create_json = "{\"HostConfig\":{\"IpcMode\":\"host\",\"CapAdd\":[\"NET_RAW\",\"MKNOD\",\"NET_ADMIN\",\"SYS_ADMIN\",\"SYS_NICE\"],\"Privileged\":false,\"DeviceCgroupRules\":[\"c 13:* rmw\",\"c 244:* rmw\"],\"Devices\":[{\"PathOnHost\":\"/dev/dri\",\"PathInContainer\":\"/dev/dri\",\"CgroupPermissions\":\"rwm\"},{\"PathOnHost\":\"/dev/input\",\"PathInContainer\":\"/dev/input\",\"CgroupPermissions\":\"rwm\"}],\"DeviceRequests\":[{\"Driver\":\"nvidia\",\"Count\":-1,\"Capabilities\":[[\"gpu\"]]}]}}"

        [[profiles.apps]]
        title = "Test ball"
        icon_png_path = "https://raw.githubusercontent.com/games-on-whales/wolf/refs/heads/stable/docs/images/test_ball_icon.png"
        start_audio_server = false
        start_virtual_compositor = false

            [profiles.apps.runner]
            type = "process"
            run_cmd = "sh -c \"while :; do echo 'running...'; sleep 10; done\""

            [profiles.apps.audio]
            source = "audiotestsrc wave=ticks is-live=true"

            [profiles.apps.video]
            source = "videotestsrc pattern=ball flip=true is-live=true ! video/x-raw, framerate={fps}/1"

    [[profiles]]
    id = "user"
    name = "User"

        [[profiles.apps]]
        title = "Steam"
        start_virtual_compositor = true
        icon_png_path = "https://games-on-whales.github.io/wildlife/apps/steam/assets/icon.png"

            [profiles.apps.runner]
            type = "docker"
            name = "WolfSteam"
            image = "ghcr.io/games-on-whales/steam:edge"
            mounts = ["/run/udev:/run/udev:ro"]
            env = [
                "PROTON_LOG=1",
                "RUN_SWAY=true",
                "GOW_REQUIRED_DEVICES=/dev/input/* /dev/dri/* /dev/nvidia*"
            ]
            devices = ["/dev/dri:/dev/dri"]
            ports = []
            base_create_json = "{\"HostConfig\":{\"IpcMode\":\"host\",\"CapAdd\":[\"SYS_ADMIN\",\"SYS_NICE\"],\"Privileged\":false,\"DeviceCgroupRules\":[\"c 13:* rmw\",\"c 244:* rmw\"],\"Devices\":[{\"PathOnHost\":\"/dev/dri\",\"PathInContainer\":\"/dev/dri\",\"CgroupPermissions\":\"rwm\"}],\"DeviceRequests\":[{\"Driver\":\"nvidia\",\"Count\":-1,\"Capabilities\":[[\"gpu\"]]}]}}"
  '';
in
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

  # Ensure config and socket dirs exist. /var/run/wolf must be on the host so
  # Wolf creates the API socket there and child containers (Wolf-UI, etc.) can
  # mount it when Podman creates them; otherwise Wolf-UI never starts.
  systemd.tmpfiles.rules = [
    "d /etc/wolf 0755 root root -"
    "d /etc/wolf/cfg 0755 root root -"
    "d /var/run/wolf 0755 root root -"
  ];

  # Remove stale Podman containers that block Wolf after a Moonlight disconnect/reconnect.
  # - WolfPulseAudio: "name already in use" -> no Pulse -> crash (exit 11).
  # - Wolf-UI_<session> / WolfSteam_*: Docker API 500 "that name is already in use" -> Connect freezes.
  systemd.services.wolf-clean-stale-containers = {
    description = "Remove stale Wolf PulseAudio / Wolf-UI / WolfSteam Podman containers";
    requiredBy = [ "podman-wolf.service" ];
    before = [ "podman-wolf.service" ];
    serviceConfig.Type = "oneshot";
    script = ''
      PODMAN="${config.virtualisation.podman.package}/bin/podman"
      "$PODMAN" rm -f WolfPulseAudio 2>/dev/null || true
      "$PODMAN" ps -a --format '{{.Names}}' 2>/dev/null | while IFS= read -r name; do
        [ -n "$name" ] || continue
        case "$name" in
          Wolf-UI_*|WolfSteam_*) "$PODMAN" rm -f "$name" 2>/dev/null || true ;;
        esac
      done
    '';
  };

  # Deploy default config (with Steam + GPU devices for Wolf-UI) when config.toml
  # does not exist. Runs before every podman-wolf start (no RemainAfterExit) so
  # if you remove config.toml and restart, we copy again instead of Wolf writing
  # its built-in default (which has no /dev/dri for Wolf-UI → black screen).
  systemd.services.wolf-ensure-config = {
    description = "Ensure Wolf config exists (default with Steam and GPU devices)";
    requiredBy = [ "podman-wolf.service" ];
    before = [ "podman-wolf.service" ];
    serviceConfig.Type = "oneshot";
    script = ''
      if [ ! -f /etc/wolf/cfg/config.toml ]; then
        cp ${wolfDefaultConfig} /etc/wolf/cfg/config.toml
        echo "Created /etc/wolf/cfg/config.toml from Nix default (Steam + /dev/dri for Wolf-UI)."
      fi
    '';
  };

  # Podman named volume with Nvidia userspace libs. Wolf passes this volume to child
  # containers via NVIDIA_DRIVER_VOLUME_NAME, so a plain bind-mount of the Nix store
  # into wolf alone is not enough — we copy hardware.nvidia.package into the volume.
  #
  # Important: `cp -a` keeps symlinks into /nix/store; the Wolf container has no /nix,
  # so libEGL etc. break and Mesa/Zink wins → smithay EGL fails. Use `cp -aL` (dereference)
  # and rewrite share/**/*.json paths to /usr/nvidia. Stamp version bumps force refresh.
  #
  # Optional upstream alternative (non-Nix): GOW Dockerfile + podman build (quickstart).
  systemd.services.wolf-nvidia-driver-vol = {
    description = "Populate Podman nvidia-driver-vol from Nix Nvidia driver (Wolf EGL/NVENC)";
    requiredBy = [ "podman-wolf.service" ];
    before = [ "podman-wolf.service" ];
    serviceConfig.Type = "oneshot";
    script = let
      nvRoot = toString config.hardware.nvidia.package;
    in ''
      set -eu
      PODMAN="${config.virtualisation.podman.package}/bin/podman"
      NV="${nvRoot}"
      # Bump when copy logic changes (forces volume refresh on existing hosts).
      STAMP_VER="3-glvnd-dirs"

      if ! "$PODMAN" volume inspect nvidia-driver-vol &>/dev/null; then
        "$PODMAN" volume create nvidia-driver-vol
      fi
      MP=$("$PODMAN" volume inspect nvidia-driver-vol -f '{{ .Mountpoint }}' 2>/dev/null || true)
      if [ -z "$MP" ] || [ ! -d "$MP" ]; then
        echo "wolf-nvidia-driver-vol: could not resolve nvidia-driver-vol mountpoint"
        exit 1
      fi

      STAMP="$MP/.wolf-nvidia-nix-store-path"
      if [ -f "$STAMP" ] && [ "$(cat "$STAMP")" = "$NV $STAMP_VER" ] && [ -d "$MP/lib" ] && [ -n "$(ls -A "$MP/lib" 2>/dev/null)" ]; then
        exit 0
      fi

      echo "wolf-nvidia-driver-vol: syncing Nvidia userspace from Nix store → nvidia-driver-vol (dereference symlinks)"
      if [ ! -d "$NV/lib" ]; then
        echo "wolf-nvidia-driver-vol: missing $NV/lib — enable proprietary Nvidia (hardware.nvidia.package)."
        exit 1
      fi

      rm -rf "$MP/lib" "$MP/lib32" "$MP/share" 2>/dev/null || true
      mkdir -p "$MP/lib"
      cp -aL "$NV/lib/." "$MP/lib/"
      if [ -d "$NV/share" ]; then
        mkdir -p "$MP/share"
        cp -aL "$NV/share/." "$MP/share/"
      fi
      if [ -d "$NV/lib32" ]; then
        mkdir -p "$MP/lib32"
        cp -aL "$NV/lib32/." "$MP/lib32/"
      fi

      # GLVND / Vulkan JSON from Nix often embed absolute /nix/store/... paths.
      if [ -d "$MP/share" ]; then
        find "$MP/share" -name '*.json' -type f -print0 2>/dev/null | while IFS= read -r -d "" j; do
          sed -i "s|$NV/|/usr/nvidia/|g" "$j" || true
        done
      fi

      echo "$NV $STAMP_VER" > "$STAMP"
    '';
  };

  # Optional: to silence "Could not open nvrtc library libnvrtc.so" add a volume
  # mounting pkgs.cudaPackages.cuda_nvrtc (or cudatoolkit) into the container and
  # set LD_LIBRARY_PATH; the store path must exist on this host (e.g. build here).
  # WOLF_RENDER_NODE: ls -l /sys/class/drm/renderD*/device/driver → pick Nvidia node.
  virtualisation.oci-containers.containers.wolf = {
    image = "ghcr.io/games-on-whales/wolf:stable";
    environment = {
      NVIDIA_DRIVER_CAPABILITIES = "all";
      NVIDIA_VISIBLE_DEVICES = "all";
      NVIDIA_DRIVER_VOLUME_NAME = "nvidia-driver-vol";
      # Default in Wolf is true; explicit so child containers are torn down when streams end
      # (reduces stale Wolf-UI_/WolfSteam_* names if the client disconnects abruptly).
      WOLF_STOP_CONTAINER_ON_EXIT = "TRUE";
      WOLF_RENDER_NODE = "/dev/dri/renderD128";
      WOLF_SOCKET_PATH = "/var/run/wolf/wolf.sock";
      # libglvnd: EGL_EXT_device_enumeration needs *every* vendor ICD loaded, not a single
      # __EGL_VENDOR_LIBRARY_FILENAMES entry (that caused "extension not supported").
      # Nvidia JSONs first (cp -aL volume), then image Mesa — smithay can pick the DRM device.
      __EGL_VENDOR_LIBRARY_DIRS = "/usr/nvidia/share/glvnd/egl_vendor.d:/etc/glvnd/egl_vendor.d:/usr/share/glvnd/egl_vendor.d";
      GBM_BACKEND = "nvidia-drm";
    };
    volumes = [
      "/etc/wolf:/etc/wolf:rw"
      "/var/run/wolf:/var/run/wolf:rw"
      "/run/podman/podman.sock:/var/run/docker.sock:ro"
      "/dev:/dev:rw"
      "/run/udev:/run/udev:rw"
      "nvidia-driver-vol:/usr/nvidia:rw"
    ];
    devices = [
      "/dev/dri"
      "/dev/uinput"
      "/dev/uhid"
      "/dev/nvidia-uvm"
      "/dev/nvidia-uvm-tools"
      "/dev/nvidiactl"
      "/dev/nvidia0"
      "/dev/nvidia-modeset"
    ];
    # Host network required for Moonlight streaming; do not use ipvlan here.
    # Match Wolf Podman quadlet: explicit /dev/nvidia* + driver volume (not CDI-only).
    extraOptions = [
      "--network=host"
      "--ipc=host"
      "--device-cgroup-rule=c 13:* rmw"
      "--label=io.containers.autoupdate=registry"
    ];
  };

  systemd.services.podman-wolf = {
    wantedBy = [ "multi-user.target" ];
    requires = [
      "wolf-clean-stale-containers.service"
      "wolf-ensure-config.service"
      "wolf-nvidia-driver-vol.service"
    ];
    after = [
      "network-online.target"
      "wolf-ensure-config.service"
      "wolf-nvidia-driver-vol.service"
      "wolf-clean-stale-containers.service"
    ];
  };
}
