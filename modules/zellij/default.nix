{ ... }:

{
    programs.zellij = {
        enable = true;
    };

    # add config to dotfiles
    xdg.configFile."zellij/config.kdl".source = ./config.kdl;
}