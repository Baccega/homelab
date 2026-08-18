{ config, pkgs, lib, ... }:
let
  constants = import ../../constants.nix;
in
{
    imports = [
        ./oci-containers.nix
    ];

    boot.loader.grub = {
        # no need to se2t devices, disko will add all devices that have a EF02 partition to the list already
        # devices = [ ];
        efiSupport = true;
        efiInstallAsRemovable = true;
    };

    # Set your time zone.
    time.timeZone = "Europe/Vienna";

    # Select internationalisation properties.
    i18n.defaultLocale = "en_US.UTF-8";
    i18n.extraLocaleSettings = {
        LC_ADDRESS = "it_IT.UTF-8";
        LC_IDENTIFICATION = "it_IT.UTF-8";
        LC_MEASUREMENT = "it_IT.UTF-8";
        LC_MONETARY = "it_IT.UTF-8";
        LC_NAME = "it_IT.UTF-8";
        LC_NUMERIC = "it_IT.UTF-8";
        LC_PAPER = "it_IT.UTF-8";
        LC_TELEPHONE = "it_IT.UTF-8";
        LC_TIME = "it_IT.UTF-8";
    };
    # Allow unfree packages
    nixpkgs.config.allowUnfree = true;

    # List packages installed in system profile. To search, run:
    # $ nix search nixpkgs wget
    environment.systemPackages = with pkgs; map lib.lowPrio [
        # Core command-line tools
        coreutils
        findutils
        file
        which
        less
        unzip
        zip
        gzip
        
        # Networking and downloading
        curl
        wget
        iputils
        inetutils
        nmap
        traceroute
        openssh
        rsync

        # System monitoring & debugging
        htop
        lsof
        pciutils
        usbutils
        
        # Development tools
        gitMinimal
        tig
        
        # Containers & virtualization
        docker-compose
        
        # Text editing & convenience
        vim
        nano

        # Optional quality-of-life utilities
        ncdu    # disk usage viewer
        man-pages
    ];

    # Nemo split-view DNS. Public resolvers would send *.baccegasandro.dev
    # through Cloudflare Access instead of LAN Caddy.
    networking = {
		nameservers = [ constants.network.vlans.servers.gateway ];
		defaultGateway = constants.network.vlans.servers.gateway;
	};

    # Podman
    virtualisation = {
        containers.enable = true;
        podman = {
            enable = true;
            dockerCompat = true;
            defaultNetwork.settings.dns_enabled = true;
        };
        oci-containers.backend = "podman";
    };

    # Enable the OpenSSH daemon.
    #
    # Notes on "SSH hangs after auth":
    # - Reverse DNS lookups (`UseDNS`) can block session startup if DNS/revDNS is slow/broken.
    # - User rc scripts (`~/.ssh/rc`) can also block interactive sessions.
    services.openssh = {
        enable = true;
        settings = {
            PasswordAuthentication = false;
            UseDns = false;
            PermitUserRC = false;
        };
    };

    # Optimize nix store
    nix.settings.auto-optimise-store = true;

    # Enable flakes permanently
    nix.settings.experimental-features = [ "nix-command" "flakes" ];

    # After backups (00:00-03:00): free store space first, then upgrade.
    # nix.gc is the NixOS timer that runs nix-collect-garbage; it is usually
    # a few minutes, so upgrade at 03:20 leaves a comfortable gap.
    nix.gc = {
        automatic = true;
        dates = "Sun *-*-* 03:00:00";
        randomizedDelaySec = "10min";
        persistent = true;
        options = "--delete-older-than 14d";
    };

    system.autoUpgrade = {
        enable = true;
        flake = "github:Baccega/homelab";
        dates = "Sun *-*-* 03:20:00";
        persistent = true;
        randomizedDelaySec = "15min";
        allowReboot = true;
    };

    systemd.services.nixos-upgrade.serviceConfig.ExecStartPre = lib.mkBefore [
      (pkgs.writeShellScript "nixos-upgrade-wait-for-backups" ''
        set -euo pipefail
        while ${pkgs.systemd}/bin/systemctl list-units --type=service --state=running --no-legend 'backup-*.service' \
            | ${pkgs.gnugrep}/bin/grep -v backup-watchdog \
            | ${pkgs.gnugrep}/bin/grep -q .; do
          echo "Waiting for backup jobs to finish before upgrade..."
          sleep 30
        done
      '')
    ];

    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "24.11";
}