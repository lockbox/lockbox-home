# dotfiles

## Assumptions
- linux
- virtualenv at `$HOME/v` (python 3.8+)
- bash

## Configs / Additions

Things it will attempt to source:
- ghcup env
- cargo env
- python venv (@ `$HOME/v`)

Things it will attempt to add to path:
- local bin
- lean bin
- jetbrains toolbox

Things it will attempt to alias:
- ls -> lsd

Misc:
- emacs vterm support hooks
- direnv hooks
- starship hooks

Config symlinks installed:
- zellij
- starship
- i3
- wezterm

TODO
- nix home-manager


### More

Additional default working set of command line tools (not really having to do w dotfiles):
- bat
- ripgrep
- find
- dust
- btm (bottom)
- lsd
- zellij

installed via

```bash
$ cargo install --force --locked bat ripgrep fd-find du-dust bottom lsd zellij
```

## Things not handled
- vscode (settings sync)