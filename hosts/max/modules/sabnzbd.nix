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
  # Generate SABnzbd config with secrets
  systemd.services.sabnzbd-config = {
    description = "Generate SABnzbd configuration with secrets";
    wantedBy = [ "multi-user.target" ];
    after = [ "sops-nix.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "sandro";
    };
    script = ''
      mkdir -p /home/sandro/sabnzbd
      
      # Read secrets from SOPS
      SAB_PASSWORD=$(cat ${config.sops.secrets.sabnzbd-password.path})
      SAB_API_KEY=$(cat ${config.sops.secrets.sabnzbd-api-key.path})
      
      cat > /home/sandro/sabnzbd/sabnzbd.ini << 'EOF'
      [misc]
      host = 0.0.0.0
      port = 8080
      https_port = ""
      username = admin
      password = $SAB_PASSWORD
      web_dir = Glitter
      web_color = Auto
      api_key = $SAB_API_KEY
      nzb_key = $SAB_API_KEY 
      permissions = 0777
      auto_browser = 0
      language = en
      enable_https = 0
      enable_https_verification = 1
      https_cert = server.cert
      https_key = server.key
      https_chain = ""
      complete_dir = /config/downloads/complete
      download_dir = /config/downloads/incomplete
      admin_dir = admin
      nzb_backup_dir = backup
      script_dir = scripts
      log_dir = logs
      dirscan_dir = ""
      dirscan_speed = 5
      refresh_rate = 0
      cache_limit = ""
      par_option = ""
      pre_check = 0
      nice = ""
      ionice = ""
      fail_hopeless_jobs = 1
      auto_disconnect = 1
      pre_script = None
      end_queue_script = None
      queue_complete_pers = 0
      history_retention = 0
      use_pickle = 0

      [servers]
      # Add your Usenet server configuration here via WebUI
      # Or define it manually following this format:
      # [[server]]
      # name = MyProvider
      # host = news.provider.com
      # port = 563
      # username = your_username
      # password = your_password
      # connections = 8
      # ssl = 1
      # ssl_verify = 2
      # ssl_ciphers = ""
      # enable = 1
      # optional = 0
      # retention = 0
      # priority = 0
      # notes = ""

      [categories]
      [[*]]
      name = *
      order = 0
      pp = 3
      script = None
      dir = ""
      newzbin = ""
      priority = 0

      [logging]
      log_level = 1
      max_log_size = 5242880
      log_backups = 5
      enable_cherrypy_logging = 0

      [nzb]
      nzb_backup_dir = ""
      direct_unpack = 0
      auto_sort = ""
      no_series_dupes = 0
      series_propercheck = 1
      replace_spaces = 0
      replace_dots = 0
      sanitize_safe = 1
      pause_on_pwrar = 1
      ignore_samples = 0
      deobfuscate_final_filenames = 0
      auto_disconnect = 1
      pre_script = None
      unwanted_extensions = 

      [quota]
      size = ""
      period = m
      resume_limit = ""

      [newzbin]
      username = ""
      password = ""
      bookmarks = 0
      bookmark_rate = 60
      unbookmark = 1

      [rating]
      enable_rating = 1
      rating_host = ""
      rating_api_key = ""

      [ncenter]
      enable_growl = 0
      enable_prowl = 0
      enable_pushover = 0
      enable_pushbullet = 0
      enable_nscript = 0
      EOF
    '';
  };
}

