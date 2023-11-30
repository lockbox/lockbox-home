{ ... }:

{
    programs.starship = {
        enable = true;
        enableBashIntegration = true;
    };

    # add config to dotfiles
    xdg.configFile."starship.toml".source = ./config.toml;
}