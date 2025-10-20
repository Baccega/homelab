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
  # Generate qBittorrent config with secrets
  systemd.services.qbittorrent-config = {
    description = "Generate qBittorrent configuration with secrets";
    wantedBy = [ "multi-user.target" ];
    after = [ "sops-nix.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "sandro";
    };
    script = ''
      mkdir -p /home/sandro/qbittorrent/qBittorrent
      
      # Read password from SOPS secret
      QBIT_PASSWORD=$(cat ${config.sops.secrets.qbittorrent-password.path})
      
      cat > /home/sandro/qbittorrent/qBittorrent/qBittorrent.conf << 'EOF'
      [Application]
      FileLogger\Enabled=true
      FileLogger\Age=6
      FileLogger\DeleteOld=true
      FileLogger\Backup=true
      FileLogger\AgeType=1

      [BitTorrent]
      Session\DefaultSavePath=/downloads
      Session\TempPath=/downloads/incomplete
      Session\Port=6881
      Session\QueueingSystemEnabled=true
      Session\MaxActiveDownloads=3
      Session\MaxActiveTorrents=5
      Session\MaxActiveUploads=3
      Session\GlobalMaxSeedingMinutes=0
      Session\GlobalMaxRatio=-1

      [Preferences]
      General\Locale=en
      WebUI\Address=*
      WebUI\Port=8080
      WebUI\LocalHostAuth=false
      WebUI\CSRFProtection=true
      WebUI\ClickjackingProtection=true
      WebUI\SecureCookie=true
      WebUI\CustomHTTPHeaders=
      WebUI\CustomHTTPHeadersEnabled=false
      WebUI\ReverseProxySupportEnabled=false
      WebUI\TrustedReverseProxiesList=
      WebUI\UseUPnP=false
      WebUI\Username=admin
      WebUI\Password_PBKDF2="$QBIT_PASSWORD"

      [LegalNotice]
      Accepted=true

      [Network]
      Proxy\Type=3
      Proxy\IP=${constants.max.hostname}
      Proxy\Port=1080
      Proxy\OnlyForTorrents=true
      EOF
    '';
  };
}

