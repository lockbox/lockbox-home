# home-manager

This assumes that `nix` is installed.

on first install run

TLDR;
```bash
$ git clone git@github.com:lockbox/dot.git ~/.config/home-manager
$ ./.config/home-manager/install.sh
# should setup everything
```

OR (assuming `nix` is already installed)

```bash
$ git clone git@github.com:lockbox/dot.git ~/.config/home-manager
$ nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
$ nix-channel --update
$ nix-shell '<home-manager>' -A install
$ home-manager switch --extra-experimental-features nix-command --extra-experimental-features flakes
```

then afterwards just run

```bash
$ home-manager switch
```

like normal.

## Updating

```bash
$ cd ~/.config/home-manager && nix flake update && home-manager switch
```

## creds
i copied a lot of this from <https://github.com/tars0x9752/home> when starting out
