{ pkgs, inputs, ... }:

{
  networking.hostName = "pane";
  nixpkgs.hostPlatform = "aarch64-darwin";
  system.stateVersion = 6;

  # Linux remote builder VM for cross-arch Nix builds (e.g. building
  # packages.x86_64-linux.* outputs from this aarch64-darwin host).
  # Provisioned via Apple Virtualization framework, persists across
  # reboots; ephemeral=true gives each build a clean rootfs.
  #
  # Uses Determinate's `nixosVmBasedLinuxBuilder` instead of upstream
  # nix-darwin's `nix.linux-builder` because Determinate manages the
  # Nix daemon itself (`nix.enable = false`), so the upstream option's
  # `nix.enable` assertion fails. PR ref:
  # https://github.com/DeterminateSystems/determinate/pull/136
  #
  # `systems` advertises both arches to the host daemon, and the inner
  # NixOS config registers qemu-user binfmt for x86_64 so the (aarch64)
  # builder VM can transparently execute x86_64-linux build actions.
  # x86_64 builds are ~3-5x slower than native via emulation; tolerable
  # for one-off images, painful for large workloads — at which point
  # add a real x86_64 builder instead.
  determinateNix.nixosVmBasedLinuxBuilder = {
    enable    = true;
    ephemeral = true;
    maxJobs   = 4;
    systems   = [ "aarch64-linux" "x86_64-linux" ];
    config    = { ... }: {
      boot.binfmt.emulatedSystems = [ "x86_64-linux" ];
    };
  };

  # trusted-users goes through Determinate's customSettings — `nix.settings`
  # is locked when Determinate manages the daemon.
  determinateNix.customSettings.trusted-users = [ "@admin" ];

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
