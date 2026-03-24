{ config, pkgs, lib, ... }:

let
  # Shared shell init that works in both bash and zsh:
  # - GPG/SSH agent setup
  # - Helper functions (src_exists, ppath_exists, apath_exists)
  # - PATH additions for cargo, go, deno, doom, etc.
  # - Env sourcing for ghcup, rye, cargo, elan, etc.
  # - Deno env var
  # - fix-color alias
  #
  # The upstream bashrc guards Guix-specific lines with existence checks,
  # so they no-op on macOS. Shell hooks (zoxide, direnv, starship) and
  # bash-only builtins (shopt) are skipped here since home-manager
  # handles integrations natively for each shell.
  sharedInit = ''
    export GPG_TTY=$(tty)
    export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)

    # source the file if the provided FILE exists
    function src_exists() {
        local fpath="$1"
        if [ -f "''${fpath}" ]; then
          source "''${fpath}"
        fi
    }

    # prepend to PATH if the provided DIR exists
    function ppath_exists() {
        local path_dir="$1"
        if [ -d "''${path_dir}" ]; then
            export PATH="''${path_dir}:''${PATH}"
        fi
    }

    # append to PATH if the provided DIR exists
    function apath_exists() {
        local path_dir="$1"
        if [ -d "''${path_dir}" ]; then
            export PATH="''${PATH}:''${path_dir}"
        fi
    }

    # Source custom env installations
    src_exists "~/v/bin/activate"
    src_exists "~/.ghcup/env"
    src_exists "~/.rye/env"
    src_exists "~/.cargo/env"
    src_exists "~/.grit/bin/env"
    src_exists "~/.elan/env"

    # add .local/bin to path
    ppath_exists "''${HOME}/.local/bin"
    # add doom emacs to path
    ppath_exists "''${HOME}/.config/emacs/bin"
    # add cargo bins to path
    ppath_exists "''${HOME}/.cargo/bin"
    # add go-home to path
    ppath_exists "''${HOME}/.go/bin"
    # add deno to path
    ppath_exists "''${HOME}/.deno/bin"
    # add homebrew to path
    ppath_exists "/opt/homebrew/bin"

    if [ -d "''${HOME}/.deno" ]; then
      export DENO_INSTALL="''${HOME}/.deno"
    fi

    # ansi seq to reset color
    alias fix-color='echo -ne "\033[0m"'
  '';
in
{
  programs.bash = {
    enable = true;
    profileExtra = builtins.readFile ../profiles/bash/bash_profile;
    initExtra = sharedInit + ''

      # Bash-specific settings
      HISTFILESIZE=100000
      HISTSIZE=10000

      shopt -s histappend
      shopt -s checkwinsize
      shopt -s extglob
      shopt -s globstar
      shopt -s checkjobs
    '';
    logoutExtra = builtins.readFile ../profiles/bash/bash_logout;
  };

  programs.zsh = {
    enable = true;
    initContent = sharedInit + ''

      # Zsh-specific settings
      HISTSIZE=10000
      SAVEHIST=100000
      setopt APPEND_HISTORY
      setopt EXTENDED_GLOB
      setopt CHECK_JOBS
    '';
  };
}
