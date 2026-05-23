{ config, pkgs, inputs, lib, ... }:

{
  networking.hostName = "pane";
  nixpkgs.hostPlatform = "aarch64-darwin";
  system.stateVersion = 6;

  # Host-side sops-nix. Reuses the same age key the VM uses
  # (/Users/lockbox/.config/sops/age/keys.txt), set up by
  # scripts/bootstrap-sops-builder.sh. Decrypts the nix-serve signing
  # key at darwin activation; darwin-rebuild must run with --impure
  # because the age key path is outside the flake.
  sops = {
    defaultSopsFile = ../secrets.yaml;
    age.keyFile     = "/Users/lockbox/.config/sops/age/keys.txt";
    # macOS has no /etc/ssh/ssh_host_{rsa,ed25519}_key by default;
    # sops-install-secrets noisily warns about each missing path during
    # activation. We use age exclusively here, so disable both SSH-key
    # fallbacks to silence the warnings.
    age.sshKeyPaths   = [];
    gnupg.sshKeyPaths = [];
    secrets."nix-serve-priv-key" = {
      owner = "root";
      mode  = "0400";
    };
  };

  # Binary cache serving the host /nix/store to the linux-builder VM.
  # Independent of nix-daemon -- works alongside Determinate's
  # `nix.enable = false` because it only reads /nix/store over HTTP.
  #
  # Determinate's nixosVmBasedLinuxBuilder runs the VM under qemu user-mode
  # networking (SLIRP), NOT a bridged interface. The VM lives on the
  # 10.0.2.0/24 SLIRP subnet and reaches the host's loopback through the
  # SLIRP gateway at 10.0.2.2 -- there is no bridge100 / 192.168.x.
  # Therefore: bind nix-serve to 127.0.0.1 on the host, and the VM hits
  # it as http://10.0.2.2:5000. Loopback binding also keeps the cache
  # off Wi-Fi / Ethernet / utun interfaces with no firewall work.
  #
  # nix-darwin does not have a services.nix-serve module (that is NixOS
  # only); we wire the daemon via launchd instead. NIX_REMOTE=daemon
  # tells nix-serve to talk to the nix-daemon socket rather than
  # accessing /nix/store directly (required when the daemon owns the
  # store). NIX_SECRET_KEY_FILE is read by nix-serve at startup to sign
  # narinfo responses with the host's private key.
  launchd.daemons.nix-serve = {
    serviceConfig = {
      Label            = "org.nixos.nix-serve";
      # nix-serve-ng is a maintained Rust rewrite of nix-serve with the
      # same CLI flags and a drop-in binary named `nix-serve`. The
      # original nix-serve package is marked broken in nixpkgs.
      ProgramArguments = [
        "${pkgs.nix-serve-ng}/bin/nix-serve"
        "--listen"
        "127.0.0.1:5000"
      ];
      EnvironmentVariables = {
        NIX_REMOTE          = "daemon";
        NIX_SECRET_KEY_FILE = config.sops.secrets."nix-serve-priv-key".path;
      };
      RunAtLoad        = true;
      KeepAlive        = true;
      StandardOutPath  = "/var/log/nix-serve.log";
      StandardErrorPath = "/var/log/nix-serve.log";
    };
  };

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
    config    = { config, lib, pkgs, ... }: {
      imports = [ inputs.sops-nix.nixosModules.sops ];

      boot.binfmt.emulatedSystems = [ "x86_64-linux" ];

      # nix.work-cache.net is on Tailscale (CNAME -> *.ts.net -> 100.x
      # CGNAT). Apple Virtualization NAT masquerades VM egress through the
      # host's primary interface, not utun, and Tailscale's WireGuard drops
      # packets whose source isn't a tailnet IP. The only working path is
      # to run tailscaled inside the VM itself.
      #
      # ephemeral=true wipes /var on every build, so the daemon must
      # re-auth each boot via a reusable+ephemeral pre-auth key. The key is
      # held in ./secrets.yaml encrypted with age, decrypted by sops-nix at
      # VM activation, and materialised at /run/secrets/tailscale-authkey
      # (root:0400). Generate the source key at
      # https://login.tailscale.com/admin/settings/keys (reusable,
      # ephemeral, pre-approved, tagged e.g. tag:builder).
      services.tailscale = {
        enable        = true;
        authKeyFile   = config.sops.secrets.tailscale-authkey.path;
        extraUpFlags  = [ "--ssh=false" "--accept-dns=true" ];
      };
      # sops-nix on this version (Mic92/sops-nix in the determinate
      # nixosVmBasedLinuxBuilder context) decrypts via an activation
      # script, NOT a systemd unit. /run/secrets is therefore populated
      # by the time multi-user.target services start, so no explicit
      # systemd After= ordering is required for tailscaled-autoconnect.
      # A previous Requires=sops-install-secrets.service blocked the
      # autoconnect unit (systemd treated the missing service as a failed
      # dependency); we deliberately leave the override unset.

      # sops-nix wiring for the VM. The age private key is sourced from
      # the host at eval time (path NOT in this repo) and copied into the
      # VM image via /nix/store. /nix/store is world-readable in the VM,
      # but the VM only has root + builder users; the encrypted-in-git
      # property is what we're protecting. Rotate the age key if leaked.
      sops = {
        defaultSopsFile = ../secrets.yaml;
        # Point sops-install-secrets directly at the /etc symlink populated
        # by environment.etc below. Avoids racing systemd-tmpfiles, which
        # runs after the activation phase where sops-nix wants the key.
        # The symlink target lives in /nix/store (world-readable inside the
        # VM, but the VM only has builder + it-admin users); rotate the
        # age key if leaked.
        age.keyFile = "/etc/sops-nix-age-key";
        secrets.tailscale-authkey = {
          owner = "root";
          mode  = "0400";
        };
        # mkpasswd -m sha-512 output for the it-admin user. Landed in
        # /run/secrets/ alongside other regular secrets; NixOS reads
        # users.<n>.hashedPasswordFile at activation time, which runs
        # AFTER sops has decrypted, so no neededForUsers gymnastics are
        # required. (neededForUsers needs the age key accessible from a
        # very-early activation hook before /etc is populated, which
        # would require staging the key in the initrd via
        # boot.initrd.secrets — overkill for this use case.)
        secrets.it-admin-password-hash = {
          owner = "root";
          mode  = "0400";
        };
      };
      # Source path is outside the flake, so darwin-rebuild must run with
      # --impure (see scripts/bootstrap-sops-builder.sh). Keeping the key
      # in the standard sops location avoids tracking secret material in
      # the dotfiles repo at all, even gitignored. The file is read at
      # eval time and pinned into /nix/store as a content-addressed copy.
      environment.etc."sops-nix-age-key" = {
        source = /Users/lockbox/.config/sops/age/keys.txt;
        mode   = "0400";
      };

      # Diagnostic/admin user for poking at tailscaled, sops, journal,
      # etc. inside the VM. `builder` stays unprivileged (it is the
      # nix-daemon's worker identity); only `it-admin` is in `wheel` and
      # only `it-admin` can sudo. Auth is SSH-key based (reuses the host's
      # builder_ed25519 public key so no extra key management) with a
      # hashed password from sops kept for console / recovery access.
      users.users.it-admin = {
        isNormalUser = true;
        description  = "Privileged admin (sudo + console) for the linux-builder VM";
        extraGroups  = [ "wheel" ];
        # The host's builder_ed25519.pub is the same key nix-daemon uses
        # to SSH in as `builder`; reauthorizing it for `it-admin` means a
        # plain `ssh it-admin@...` from the host works without any new key.
        openssh.authorizedKeys.keyFiles = [
          /etc/nix/builder_ed25519.pub
        ];
        hashedPasswordFile = config.sops.secrets.it-admin-password-hash.path;
      };
      # Wheel can sudo without a password; the it-admin password is for
      # interactive console / recovery only, not routine sudo gating.
      security.sudo.wheelNeedsPassword = false;

      # MagicDNS resolves nix.work-cache.net once tailscaled is up.
      # Belt-and-suspenders host entry for the brief window before login.
      networking.extraHosts = ''
        100.64.0.1 nix.work-cache.net
      '';

      # Substituter priority is list order: first entry tried first.
      # Host nix-serve sits at position 0 so the VM hits the host's
      # /nix/store before falling through to remote caches. mkForce
      # neutralises the NixOS default that would otherwise inject
      # cache.nixos.org at the head of the list.
      #
      # 10.0.2.2 is the qemu SLIRP gateway: it transparently forwards
      # VM traffic to the host's loopback, where nix-serve listens on
      # 127.0.0.1:5000. No bridge IP, no firewall holes.
      nix.settings.substituters = lib.mkForce [
        "http://10.0.2.2:5000"
        "https://cache.nixos.org/"
        "https://nix-community.cachix.org"
        "https://nix.work-cache.net/nix-cache"
      ];
      nix.settings.trusted-public-keys = lib.mkForce [
        "this-host-nix-serve-1:BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB="
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
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
    "https://nix.work-cache.net/nix-cache"
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
