# Steam on the bolt gaming guest (used with Sunshine / Moonlight).
{
  ...
}:
{
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = false;
    dedicatedServer.openFirewall = false;
  };
}
