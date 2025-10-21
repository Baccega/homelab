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
    networks = [ "default" ];
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

      # Read password from SOPS secret
      QBIT_PASSWORD=$(cat ${config.sops.secrets.qbittorrent-password.path})
      
      cat > /home/sandro/qbittorrent/qBittorrent/qBittorrent.conf << EOF
      [Application]
      FileLogger\Age=1
      FileLogger\AgeType=1
      FileLogger\Backup=true
      FileLogger\DeleteOld=true
      FileLogger\Enabled=true
      FileLogger\MaxSizeBytes=66560
      FileLogger\Path=/config/qBittorrent/logs

      [AutoRun]
      enabled=false
      program=

      [BitTorrent]
      Session\AddTorrentStopped=false
      Session\AlternativeGlobalDLSpeedLimit=0
      Session\AlternativeGlobalUPSpeedLimit=0
      Session\BandwidthSchedulerEnabled=true
      Session\DefaultSavePath=/downloads/
      Session\ExcludedFileNames=
      Session\GlobalDLSpeedLimit=7000
      Session\GlobalUPSpeedLimit=500
      Session\Port=6881
      Session\QueueingSystemEnabled=true
      Session\SSL\Port=55097
      Session\ShareLimitAction=Stop
      Session\TempPath=/downloads/incomplete/
      Session\UseAlternativeGlobalSpeedLimit=true

      [Core]
      AutoDeleteAddedTorrentFile=Never

      [LegalNotice]
      Accepted=true

      [Meta]
      MigrationVersion=8

      [Network]
      PortForwardingEnabled=false
      Proxy\AuthEnabled=false
      Proxy\HostnameLookupEnabled=false
      Proxy\IP=${constants.network.forwardProxy.ip}
      Proxy\Password=
      Proxy\Port=@Variant(\0\0\0\x85\x4\x38)
      Proxy\Profiles\BitTorrent=true
      Proxy\Profiles\Misc=true
      Proxy\Profiles\RSS=true
      Proxy\Type=SOCKS5
      Proxy\Username=

      [Preferences]
      Connection\PortRangeMin=6881
      Connection\UPnP=false
      Downloads\SavePath=/downloads/
      Downloads\TempPath=/downloads/incomplete/
      General\Locale=en
      MailNotification\req_auth=true
      Scheduler\end_time=@Variant(\0\0\0\xf\x5%q\xa0)
      WebUI\Address=*
      WebUI\AuthSubnetWhitelist=@Invalid()
      WebUI\Password_PBKDF2="$QBIT_PASSWORD"
      WebUI\ServerDomains=*

      [RSS]
      AutoDownloader\DownloadRepacks=true
      AutoDownloader\SmartEpisodeFilter=s(\\d+)e(\\d+), (\\d+)x(\\d+), "(\\d{4}[.\\-]\\d{1,2}[.\\-]\\d{1,2})", "(\\d{1,2}[.\\-]\\d{1,2}[.\\-]\\d{4})"
      EOF
    '';
  };
}

