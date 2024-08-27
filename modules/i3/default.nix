{ ... }:
{
    # home manager doesn't own the i3 session, yet.
    # inspiration:
    # https://github.com/srid/nix-config/blob/705a70c094da53aa50cf560179b973529617eb31/nix/home/i3.nix
    # https://nixos.wiki/wiki/I3
    # https://github.com/NixOS/nixpkgs/blob/nixos-23.05/pkgs/applications/window-managers/i3/status-rust.nix
    xdg.configFile."i3/config".source = ./config;
    xdg.configFile."i3status/config".source = ./i3status-config;
}
