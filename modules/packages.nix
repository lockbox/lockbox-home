{ pkgs, ...}:
{
    home.packages = with pkgs; [
        rustup
        
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
        btop
        just
        kmon

        # extra
        magic-wormhole
        awscli

        # nix
        colmena
        nix-output-monitor
        nil
        nixpkgs-fmt
        nix-prefetch-git
        nix-prefetch-github
        nix-du
    ];
}
