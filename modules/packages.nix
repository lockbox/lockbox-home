{ pkgs, ...}:
{
    home.packages = with pkgs; [
        # misc
        ranger

        # utils - slowly adding all of them
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
