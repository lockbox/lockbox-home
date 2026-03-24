{ config, pkgs, lib, ... }:

{
  imports = [
    ./packages.nix
    ./shell.nix
    ./git.nix
    ./gpg.nix
    ./emacs.nix
  ];

  home = {
    username = "lockbox";
    homeDirectory = lib.mkForce "/Users/lockbox";
    stateVersion = "24.11";
  };

  # Environment variables (matching Guix home-configuration.scm)
  home.sessionVariables = {
    EDITOR = "emacsclient";
    VISUAL = "emacsclient";
    LANG = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
    GOPATH = "$HOME/go";
    GOBIN = "$HOME/go/bin";
    RIPGREP_CONFIG_PATH = "$HOME/.ripgreprc";
  };

  home.sessionPath = [
    "$HOME/go/bin"
    "$HOME/.local/bin"
    "$HOME/.config/emacs/bin"
    "/opt/homebrew/bin"
  ];

  # Starship prompt (native module + shared config)
  programs.starship = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
  };
  xdg.configFile."starship.toml".source = ../configs/starship.toml;

  # Zoxide (smart cd)
  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
  };

  # Direnv with nix-direnv for fast flake shells
  programs.direnv = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
    # Workaround: direnv 2.37.1 in nixpkgs fails to build on macOS
    # due to CGO_ENABLED not being set for -linkmode=external
    package = pkgs.direnv.overrideAttrs (old: {
      env = (old.env or {}) // { CGO_ENABLED = "1"; };
    });
  };

  # Shared config symlinks
  xdg.configFile."zellij/config.kdl".source = ../configs/zellij-config.kdl;
  xdg.configFile."ghostty/config".source = ../configs/ghostty.config;
  xdg.configFile."wezterm/wezterm.lua".source = ../configs/wezterm.lua;
  home.file.".ripgreprc".source = ../configs/ripgreprc;
  home.file.".ssh/config".source = ../configs/ssh-config;

  programs.home-manager.enable = true;
}
