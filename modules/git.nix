{ pkgs, ... }:
{
  # .gitconfig
  programs.git = {
    package = pkgs.gitAndTools.gitFull;
    enable = true;

    userName = "lockbox";
    userEmail = "lockbox@struct.foo";

    # ignore some editor common + direnv things
    ignores = [ "*~" "*.swp" ".direnv" "__pycache__" "build" "target" ];

    # setup signing defaults
    signing = {
      key = null;
      signByDefault = true;
    };

    extraConfig = {
      init.defaultBranch = "main";
      core.editor = "vim";
    };
  };
}
