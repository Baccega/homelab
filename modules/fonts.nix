{
  pkgs,
  ...
}:
{
    fonts = {
        packages = with pkgs; [
            comic-mono
            nerd-fonts.fira-mono
        ];

        fontconfig = {
            enable = true;
            defaultFonts = {
                monospace = [
                    "FiraMono Nerd Font"
                    "Comic Mono"
                ];
            };
        };
    };
}