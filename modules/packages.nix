{ pkgs, ...}:
{
    home.packages = with pkgs; [
        # misc
        ranger
        bottom
        trippy
        bat
        du-dust
        fd
        lsd
        ripgrep
        broot
        jq
        nmap
        pciutils
        jo
        tokei

        # nix
        rnix-lsp
        nixpkgs-fmt
        nix-prefetch-git
        nix-prefetch-github
        nix-du
    ];
}
