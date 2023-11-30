{ pkgs, ... }:
{
  # smol vim setup
  programs.vim = {
    enable = true;
    settings = {
      expandtab = true;
      background = "dark";
      tabstop = 4;
    };
    defaultEditor = true;

    plugins = [ pkgs.vimPlugins.vim-sensible pkgs.vimPlugins.vim-polyglot pkgs.vimPlugins.papercolor-theme ];

    # enable the theme
    extraConfig = ''
      colorscheme PaperColor
      set t_Co=256
      '';
  };
}