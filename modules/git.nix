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
    # things that should be "opt in commit" only
    ++ [ ".dir-locals.el" ".local-env" ".envrc" ]
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

      # update refs by default
      rebase.updateRefs = true;
      rebase.ff = "only";

      # put branches in columns if there's room
      column.ui = "auto";

      # reuse recorded resolution
      # "on rebase remember how i fixed merge conflict"
      rerere.enabled = true;

      # stash everything
      alias.astash = "stash --all";

      # safer version of push --force-with-lease, which is a safer form of
      # push --force
      alias.fpush = "push --force-if-includes";
    };

    # use lfs
    lfs = {
      enable = true;
    };

    # difftastic diff viewer
    difftastic = {
      enable = true;
    };
  };
}
