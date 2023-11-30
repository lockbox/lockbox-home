{ pkgs, ... }:
{
  # .gitconfig
  programs.git = {
    package = pkgs.gitAndTools.gitFull;
    enable = true;
    userName = "lockbox";
    userEmail = "lockbox.06@protonmail.com";
    ignores = [ "*~" "*.swp" ".direnv" ];
    extraConfig = {
      init.defaultBranch = "main";
      core.editor = "vim";
    };
  };
}