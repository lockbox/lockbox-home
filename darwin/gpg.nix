{ config, pkgs, ... }:

{
  home.file.".gnupg/gpg.conf".source = ../configs/gpg.conf;
  home.file.".gnupg/scdaemon.conf".source = ../configs/scdaemon.conf;

  # gpg-agent.conf: shared base config + nix-specific pinentry path + SSH support
  home.file.".gnupg/gpg-agent.conf".text = ''
    ${builtins.readFile ../configs/gpg-agent.conf}
    pinentry-program ${pkgs.pinentry-curses}/bin/pinentry-curses
    enable-ssh-support
  '';
}
