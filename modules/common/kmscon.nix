{
  pkgs,
  ...
}:
{
  fonts.packages = with pkgs; [
    nerd-fonts.fira-mono
    comic-mono
  ];
  fonts.fontconfig.enable = true;

  # Required when services.kmscon.config.hwaccel is enabled.
  hardware.graphics.enable = true;

  services.kmscon = {
    enable = true;
    config = {
      font-name = "FiraMono Nerd Font";
      hwaccel = true;
    };
  };
}
