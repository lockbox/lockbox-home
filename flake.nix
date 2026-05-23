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
  {
    darwinConfigurations."pane" = nix-darwin.lib.darwinSystem {
      modules = [
        determinate.darwinModules.default
        home-manager.darwinModules.home-manager
        sops-nix.darwinModules.sops
        ./darwin
      ];
      specialArgs = { inherit inputs; };
    };
  };
}
