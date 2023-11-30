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
        unzip
        protobuf
        coreutils
        binutils
        pciutils
        gawk
        gnumake
        gnused
        jo
        jq
        curl
        wget
        xsel
        xclip
        xdotool
        copyq
        gettext

        # nix
        rnix-lsp
        nixpkgs-fmt
        nix-prefetch-git
        nix-prefetch-github
        nix-du
    ];
}