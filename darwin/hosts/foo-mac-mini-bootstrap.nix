{ pkgs, lib, ... }:

# foo-mac-mini-bootstrap: minimal first-install target.
#
# Chicken-and-egg: the real `foo-mac-mini` darwin config compiles a
# customised NixOS image for the linux-builder VM (sops in VM, tailscale,
# it-admin user, etc.). Compiling that image needs an aarch64-linux
# builder, which doesn't exist on a fresh mac. This bootstrap module
# brings up a vanilla Determinate `nixosVmBasedLinuxBuilder` (no inner
# overrides, so the image comes from cache) just to get aarch64-linux +
# x86_64-linux builders online. After this activates once, switch to
# `.#foo-mac-mini` for the full configuration.
#
# Deliberately omitted: sops, nix-serve, home-manager, emacs overlay,
# custom VM config — anything that needs secrets or pulls non-cached
# closures. Keep the bootstrap path fast and self-contained.

{
  networking.hostName  = "foo-mac-mini";
  nixpkgs.hostPlatform = "aarch64-darwin";
  system.stateVersion  = 6;

  # Vanilla Determinate linux-builder VM. No `config` field, so the
  # default NixOS module set runs — the resulting image is the same one
  # other Determinate users boot, and is therefore in Determinate's
  # public cache (no local cross-compile needed).
  determinateNix.nixosVmBasedLinuxBuilder = {
    enable    = true;
    ephemeral = true;
    maxJobs   = 4;
    systems   = [ "aarch64-linux" "x86_64-linux" ];
  };

  # Mirror the trusted-users + emulated-systems wiring from the full
  # config so `nix build` on this host can offload x86_64-linux jobs to
  # the bootstrap VM (the inner NixOS image enables binfmt for x86 by
  # default in Determinate's module).
  determinateNix.customSettings.trusted-users = [ "@admin" ];

  programs.bash.enable = true;
  programs.zsh.enable  = true;

  security.pam.services.sudo_local.touchIdAuth = true;
}
