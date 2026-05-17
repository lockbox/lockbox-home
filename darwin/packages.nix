{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Security / credentials
    gnupg
    pinentry-curses
    pass
    yubikey-manager
    restic
    rclone
    sops
    age
    ssh-to-age

    # Version control
    git
    git-lfs

    # Languages / runtimes
    go
    zig
    nodejs
    bun
    openjdk

    # Build tools
    cmake
    ninja
    bear
    ccache

    # Dev utilities
    cloc
    tokei
    shellcheck
    actionlint
    gdb

    # Terminal / shell utilities
    lsd
    btop
    ripgrep
    fd
    jq
    just
    watchexec
    zellij
    ranger

    # Network / fetch
    curl
    wget
    nmap

    # Infrastructure
    wireguard-tools
    ansible
    opentofu
    awscli2
    k9s
    kubectl
    kubernetes-helm

    # Documents
    pandoc
    aspell
    aspellDicts.en

    # Compression
    lz4
    xz

    # Data
    duckdb
  ];
}
