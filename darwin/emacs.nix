{ config, pkgs, lib, ... }:

let
  # Bleeding-edge Emacs from emacs-overlay with native compilation
  # Apply emacs-plus patches for proper macOS integration
  patchBranch = "emacs-30";
  patchBase = "https://raw.githubusercontent.com/d12frosted/homebrew-emacs-plus/master/patches/${patchBranch}";

  myEmacs = pkgs.emacs-unstable.overrideAttrs (old: {
    patches = (old.patches or []) ++ [
      # Fix window role so macOS WMs (Yabai, etc.) recognize Emacs properly
      # Note: emacs-30/fix-window-role.patch is a symlink to emacs-28/
      (builtins.fetchurl {
        url = "https://raw.githubusercontent.com/d12frosted/homebrew-emacs-plus/master/patches/emacs-28/fix-window-role.patch";
        sha256 = "0c41rgpi19vr9ai740g09lka3nkjk48ppqyqdnncjrkfgvm2710z";
      })
      # Round undecorated frame support
      (builtins.fetchurl {
        url = "${patchBase}/round-undecorated-frame.patch";
        sha256 = "0x187xvjakm2730d1wcqbz2sny07238mabh5d97fah4qal7zhlbl";
      })
      # Respond to OS-level light/dark mode changes
      (builtins.fetchurl {
        url = "${patchBase}/system-appearance.patch";
        sha256 = "1dkx8xc3v2zgnh6fpx29cf6kc5h18f9misxsdvwvy980cj0cxcwy";
      })
    ];
  });

  # Bundle vterm so it's built against the correct emacs
  emacsWithPackages = (pkgs.emacsPackagesFor myEmacs).emacsWithPackages (epkgs: [
    epkgs.vterm
  ]);
in
{
  home.packages = [ emacsWithPackages ];

  # Doom Emacs config symlinks (~/.config/doom/)
  xdg.configFile."doom/init.el".source = ../configs/doom/init.el;
  xdg.configFile."doom/config.el".source = ../configs/doom/config.el;
  xdg.configFile."doom/packages.el".source = ../configs/doom/packages.el;

  # macOS-specific early-init: remove title bar with rounded corners
  # Uses the undecorated-round frame parameter added by round-undecorated-frame.patch
  xdg.configFile."doom/early-init.el".text = ''
    (push '(undecorated-round . t) default-frame-alist)
  '';

  # Emacs daemon as a launchd user service (starts on login)
  launchd.agents.emacs = {
    enable = true;
    config = {
      Label = "org.gnu.emacs.daemon";
      ProgramArguments = [
        "${emacsWithPackages}/Applications/Emacs.app/Contents/MacOS/Emacs"
        "--fg-daemon"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/emacs-daemon.log";
      StandardErrorPath = "/tmp/emacs-daemon.log";
    };
  };

  # Aliases: emacs launches a client frame, falls back to starting daemon
  programs.bash.shellAliases.emacs = "emacsclient -c -a ''";
  programs.zsh.shellAliases.emacs = "emacsclient -c -a ''";
}
