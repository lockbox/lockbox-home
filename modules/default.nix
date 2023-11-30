{ ... }:
{
    imports = [
        ./direnv.nix
        ./starship
        ./wezterm.nix
        ./git.nix
        ./vim.nix
        ./haskell.nix
        ./packages.nix
        ./rust.nix
        ./zellij
        ./i3
    ];
}