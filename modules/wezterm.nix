{ pkgs, ... }:
{
    # need to manually install wezterm unless want to
    # engage in jank nixGL hax
    #home.packages = with pkgs; [
    #    wezterm
    #];

    xdg.configFile."wezterm/wezterm.lua".text = ''
        local wezterm = require 'wezterm'

        local config = {}

        config.enable_tab_bar = false
        config.hide_tab_bar_if_only_one_tab = true

        return config
    '';
}
