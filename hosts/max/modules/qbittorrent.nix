{
  config,
  lib,
  pkgs,
  ...
}:
let
  constants = import ../../../constants.nix;
in
{
  networking.firewall.allowedTCPPorts = [ 
    constants.services.qbittorrent.port
    constants.services.qbittorrent.torrentPort
  ];

  virtualisation.oci-containers.containers.qbittorrent = {
    image = "ghcr.io/linuxserver/qbittorrent";
    environmentFiles = [
      config.sops.secrets.max-docker-env.path
    ];
    ports = [
      "${toString constants.services.qbittorrent.port}:8080"
      "${toString constants.services.qbittorrent.torrentPort}:6881"
      "${toString constants.services.qbittorrent.torrentPort}:6881/udp"
    ];
    volumes = [
      "/home/sandro/qbittorrent:/config"
      "/mnt/downloads:/downloads"
    ];
  };

  # Ensure container waits for NFS mount
  systemd.services.podman-qbittorrent = {
    wantedBy = [ "multi-user.target" ];
    after = [ "mnt-downloads.mount" "qbittorrent-config.service" ];
    requires = [ "mnt-downloads.mount" "qbittorrent-config.service" ];
  };

  # Generate qBittorrent config with secrets
  systemd.services.qbittorrent-config = {
    description = "Generate qBittorrent configuration with secrets";
    wantedBy = [ "multi-user.target" ];
    after = [ "sops-nix.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "root";
    };
    script = ''
      mkdir -p /home/sandro/qbittorrent/qBittorrent
      
      # Read secrets from SOPS
      QB_USERNAME=$(cat ${config.sops.secrets.qbittorrent-username.path})
      QB_PASSWORD=$(cat ${config.sops.secrets.qbittorrent-password.path})
      
      cat > /home/sandro/qbittorrent/qBittorrent/qBittorrent.conf << EOF
      [Application]
      FileLogger\Age=1
      FileLogger\AgeType=1
      FileLogger\Backup=true
      FileLogger\DeleteOld=true
      FileLogger\Enabled=true
      FileLogger\MaxSizeBytes=66560
      FileLogger\Path=/config/qBittorrent/logs

      [BitTorrent]
      Session\AlternativeGlobalDLSpeedLimit=5000
      Session\AlternativeGlobalUPSpeedLimit=1000
      Session\BandwidthSchedulerEnabled=true
      Session\ExcludedFileNames=
      Session\Port=9124
      Session\QueueingSystemEnabled=false
      Session\SSL\Port=24458
      Session\UseAlternativeGlobalSpeedLimit=true

      [Core]
      AutoDeleteAddedTorrentFile=Never

      [Meta]
      MigrationVersion=8

      [Network]
      Cookies=@Invalid()
      Proxy\AuthEnabled=false
      Proxy\HostnameLookupEnabled=true
      Proxy\IP=${constants.network.forwardProxy.ip}
      Proxy\Password=
      Proxy\Port=@Variant(\0\0\0\x85\x4\x38)
      Proxy\Type=SOCKS5
      Proxy\Username=

      [Preferences]
      General\Locale=en
      MailNotification\req_auth=true
      Scheduler\end_time=@Variant(\0\0\0\xf\x5%q\xa0)
      WebUI\AuthSubnetWhitelist=@Invalid()
      WebUI\Password_PBKDF2="$QB_PASSWORD"
      WebUI\Username=$QB_USERNAME

      [RSS]
      AutoDownloader\DownloadRepacks=true
      AutoDownloader\SmartEpisodeFilter=s(\\d+)e(\\d+), (\\d+)x(\\d+), "(\\d{4}[.\\-]\\d{1,2}[.\\-]\\d{1,2})", "(\\d{1,2}[.\\-]\\d{1,2}[.\\-]\\d{4})"
      EOF
    '';
  };
}
