{ pkgs, ...}:
{
    home.packages = with pkgs; [
        # emacs
        nodejs
        nodePackages_latest.pnpm
        texlive.combined.scheme-medium
        sqlite

        rustup
        
        # shell utils
        ranger
        bottom
        trippy
        taplo-cli
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
        htop
        just
        kmon
        fzf
        zoxide

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
