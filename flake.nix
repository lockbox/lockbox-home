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
  };

  outputs = inputs@{ self, nixpkgs, nix-darwin, home-manager, determinate, emacs-overlay }:
  {
    darwinConfigurations."pane" = nix-darwin.lib.darwinSystem {
      modules = [
        determinate.darwinModules.default
        home-manager.darwinModules.home-manager
        ./darwin
      ];
      specialArgs = { inherit inputs; };
    };
  };
}
