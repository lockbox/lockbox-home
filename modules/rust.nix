{ config, pkgs, ... }:

{
  home = {
    # NOTE: let rustup manaage rust installations instead of nix,
    # so that is why rustup is not added to packages, but we still
    # add the cargo bin to the path
    packages = with pkgs; [
      #rustup
    ];
    sessionPath = [ "$HOME/.cargo/bin" ];
  };
}
