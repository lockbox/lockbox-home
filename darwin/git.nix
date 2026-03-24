{ config, pkgs, ... }:

{
  home.file.".gitconfig".source = ../configs/git-config;
  home.file.".gitignore_global".source = ../configs/git-ignore;
}
