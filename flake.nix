{
  description = "lockbox-home: cross-platform dotfiles (Guix Home + nix-darwin)";

  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0";

    nix-darwin = {
      url = "https://flakehub.com/f/nix-darwin/nix-darwin/0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "https://flakehub.com/f/nix-community/home-manager/0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/3";

    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # sops-nix: secrets encrypted at rest in this repo, decrypted at
    # activation time. Used to ship the Tailscale auth key into the
    # ephemeral linux-builder VM without committing plaintext.
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, nix-darwin, home-manager, determinate, emacs-overlay, sops-nix }:
  let
    # Shared module list. Per-host wrapper modules under ./darwin/hosts set
    # networking.hostName + nixpkgs.hostPlatform; everything else lives in
    # ./darwin and is reused across hosts.
    mkHost = hostModule: nix-darwin.lib.darwinSystem {
      modules = [
        determinate.darwinModules.default
        home-manager.darwinModules.home-manager
        sops-nix.darwinModules.sops
        hostModule
        ./darwin
      ];
      specialArgs = { inherit inputs; };
    };
  in
  {
    darwinConfigurations."pane"          = mkHost ./darwin/hosts/pane.nix;
    darwinConfigurations."foo-mac-mini"  = mkHost ./darwin/hosts/foo-mac-mini.nix;

    # First-install bootstrap target for foo-mac-mini. Deliberately does
    # NOT import ./darwin: that module imports local.nix and configures
    # sops + custom VM + nix-serve, which require an aarch64-linux
    # builder already running. The bootstrap stands up a vanilla
    # Determinate builder VM so the subsequent `.#foo-mac-mini` switch
    # has aarch64-linux available locally. See the module header for
    # full rationale.
    darwinConfigurations."foo-mac-mini-bootstrap" = nix-darwin.lib.darwinSystem {
      modules = [
        determinate.darwinModules.default
        ./darwin/hosts/foo-mac-mini-bootstrap.nix
      ];
      specialArgs = { inherit inputs; };
    };
  };
}
