{ pkgs, inputs, ... }:

{
  networking.hostName = "pane";
  nixpkgs.hostPlatform = "aarch64-darwin";
  system.stateVersion = 6;

  # Apply emacs-overlay for bleeding-edge emacs
  nixpkgs.overlays = [
    inputs.emacs-overlay.overlay
  ];

  # Enable shells
  programs.bash.enable = true;
  programs.zsh.enable = true;

  # System-level packages
  environment.systemPackages = with pkgs; [
    vim
  ];

  # Fonts (installed to ~/Library/Fonts via nix-darwin)
  fonts.packages = with pkgs; [
    fira-code
    fira-mono
    font-awesome
  ];

  # Allow TouchID for sudo
  security.pam.services.sudo_local.touchIdAuth = true;

  # Home Manager as nix-darwin module
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "bak";
    users.lockbox = import ./home.nix;
  };
}
