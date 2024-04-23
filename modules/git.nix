{ pkgs, ... }:
{
  # .gitconfig
  programs.git = {
    package = pkgs.gitAndTools.gitFull;
    enable = true;

    userName = "lockbox";
    userEmail = "lockbox@struct.foo";

    # ignore some editor common + direnv things
    ignores = [ "*~" "*.swp" ] 
    # direnv
    ++ [ ".direnv" ]
    # python garbage
    ++ [ "__pycache__" ]
    # build dir's
    ++ [ "build" "target" ]
    # built objects
    ++ [ "*.so" ".o" ".ko"]
    # custom stuff
    ++ [ ".lockbox" ];

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
