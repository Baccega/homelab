{
    pkgs,
    config,
    ...
}:
{
    services.kmscon = {
        enable = true;
        fonts = [
            {
                package = pkgs.nerd-fonts.fira-mono;
                name = "FiraMono Nerd Font"; 
            }
            {
                package = pkgs.comic-mono;
                name = "Comic Mono";
            }
        ];
        hwRender = true;
  };
}
