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
    config    = { lib, ... }: {
      boot.binfmt.emulatedSystems = [ "x86_64-linux" ];

      nix.settings.extra-substituters = [
        "https://nix-community.cachix.org"
        "https://nix.work-cache.net"
      ];
      nix.settings.extra-trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "work-cache-1:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
      ];

      # Default VM is 3 GB / 1 vCPU. Linking large Rust binaries with LTO
      # under qemu-user emulation (x86 binfmt on aarch64 host) blows past
      # 3 GB and OOMs. Bump generously; the host has plenty.
      #
      # mkForce on memorySize because nix-builder-vm.nix sets it at the
      # same priority and conflicts otherwise. cores is mkDefault upstream
      # so plain assignment wins.
      virtualisation.memorySize = lib.mkForce 16384; # MiB
      virtualisation.cores      = 8;
    };
  };

  # trusted-users + extra substituters go through Determinate's customSettings;
  # `nix.settings` is locked when Determinate manages the daemon.
  determinateNix.customSettings.trusted-users = [ "@admin" ];

  # rust-overlay's outputs (rustc, cargo, rust-std, …) are not built by NixOS
  # Hydra and therefore never land in cache.nixos.org. The community-maintained
  # cachix is the canonical substituter. Without it, every `rust-bin.*`
  # invocation pulls the toolchain from upstream and extracts locally — which
  # on the linux-builder VM dominates build time for any aarch64-linux or
  # x86_64-linux closure that touches the rust toolchain.
  determinateNix.customSettings.extra-substituters = [
    "https://nix-community.cachix.org"
    "https://nix.work-cache.net"
  ];
  determinateNix.customSettings.extra-trusted-public-keys = [
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    "work-cache-1:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
  ];

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
