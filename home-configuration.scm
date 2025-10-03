;; -*- mode: Scheme -*-
;; This "home-environment" file can be passed to 'guix home reconfigure'
;; to reproduce the content of your profile.  This is "symbolic": it only
;; specifies package names.  To reproduce the exact same profile, you also
;; need to capture the channels being used, as returned by "guix describe".
;; See the "Replicating Guix" section in the manual.
;; TODO: add home-xdg-*service-type's
;; TODO: add home-fontconfig-service-type
;; TODO: add home-sway-service-type
;; TODO: add home-openssh-service-type
;; TODO: add home-bash-service-type
;; TODO: add home-inputrc-service-type
;; TODO: add home-batsignal-service-type
;; TODO: add home-syncthing-service-type

(use-modules
 (guix build utils)
 (gnu packages)
 (gnu services)
 (gnu services security-token)
 (guix gexp)
 (guix channels)
 (gnu packages shells)
 (gnu packages gnupg)
 (gnu home)
 (gnu home services)
 (gnu home services xdg)
 (gnu home services guix)
 (gnu home services gnupg)
 (gnu home services shells)
 (ice-9 ftw)
 (ice-9 match)
 (srfi srfi-1))

;; Helper function to recursively map a directory's files for deployment
(define (directory->config-alist source-dir target-dir)
  "Recursively map all files from SOURCE-DIR to TARGET-DIR for home-xdg-configuration-files-service-type.
   Returns an alist of (target-path . local-file) pairs."
  (define (strip-prefix prefix path)
    (if (string-prefix? prefix path)
        (substring path (string-length prefix))
        path))

  (define (process-directory dir prefix)
    (let ((entries '()))
      (ftw dir
           (lambda (path stat flag)
             (cond
              ;; Regular file
              ((eq? flag 'regular)
               (let* ((relative-path (strip-prefix prefix path))
                      (target-path (string-append target-dir relative-path)))
                 (set! entries
                       (cons (list target-path
                                   (local-file path
                                              (string-append "doom-"
                                                             (basename path))
                                              #:recursive? #f))
                             entries))))
              ;; Directory - just traverse it
              ((eq? flag 'directory) #t)
              ;; Skip everything else
              (else #t))
             #t))
      entries))

  ;; Resolve source-dir relative to this file's location
  (let* ((this-file (current-source-location))
         (this-dir (dirname (assoc-ref this-file 'filename)))
         (absolute-source-dir (string-append this-dir "/" source-dir))
         ;; Ensure source-dir ends with /
         (prefix (if (string-suffix? "/" absolute-source-dir)
                     absolute-source-dir
                     (string-append absolute-source-dir "/"))))
    (process-directory absolute-source-dir prefix)))

(home-environment
  ;; Below is the list of packages that will show up in your
  ;; Home profile, under ~/.guix-home/profile.
  (packages
   (specifications->packages
    (list
     ;; base
     "nss-certs"
     "glibc-locales"
     "zlib"
     "libtool"

     ;; guix
     "mumi"

     ;; security
     "gnupg"
     "pinentry"
     "ccid"
     "pcsc-lite"
     "python-yubikey-manager"

     ;; messaging
     "mu"
     "fetchmail"
     "weechat"

     ;; git
     "git"
     "git:send-email"
     "git-lfs"

     ;; wm
     "i3status"
     "i3status-rust"
     "bemenu"
     "wl-clipboard"
     "flameshot"
     "waylock"

     ;; infra
     "wireguard-tools"
     "ansible"
     "ansible-core"
     "k9s"
     "kubectl"
     "python-netaddr"
     "helm-kubernetes"
     "podman"
     "podman-compose"

     ;; 3d printing
     "prusa-slicer"
     "freecad"
     "openscad"

     ;; programming
     "go"
     "zig"
     "cloc"
     "mold"
     "node"
     "cmake"
     "ninja"
     "tokei"
     "bear"
     "openjdk"
     "openjdk:jdk"
     "ccache"
     "googletest"
     "actionlint"
     "shellcheck"
     "clang"
     "llvm"
     "guile-next"
     "guile-ares-rs"
     "emacs-arei"
     "emacs-next"
     "pinentry-emacs"

     ;; firmware stuff
     "uefitool"
     "efitools"
     "sbsigntools"
     "efi-analyzer"
     "gnu-efi"
     "squashfs-tools-ng"
     "dfu-util"
     "teensy-loader-cli"
     "teensy-udev-rules"
     "avrdude"
     "openocd"
     "binwalk"

     ;; random
     "elfutils"
     "patchelf"

     ;; utils
     "gimp"
     "kitty"
     "direnv"
     "ranger"
     "pciutils"
     "fd"
     "starship"
     "lsd"
     "du-dust"
     "ripgrep"
     "watchexec"
     "hwdata"
     "nmap"
     "just"
     "inetutils"
     "netcat"
     "zoxide"
     "feh"
     "strace"
     "btop"
     "curl"
     "gzip"
     "bzip2"
     "duckdb"
     "xz"
     "lzo"
     "unrar-free"
     "lz4"
     "bat"
     "wget"
     "gdb-multiarch"
     "poke"
     "emacs-poke-mode"
     "restic"
     "rclone"
     "password-store"
     "qtpass"

     ;; dict + ssg
     "aspell"
     "aspell-dict-en"
     "pandoc"
     "haunt"
     "hugo"

     ;; fonts
     "fontconfig"
     "freetype@2"          ; TODO: upstream symlink
     "font-fira-mono"
     "emacs-nerd-icons"
     "font-fira-sans"
     "font-fira-code"
     "font-awesome")))

  ;; Below is the list of Home services.  To search for available
  ;; services, run 'guix home search KEYWORD' in a terminal.
  (services
   (list
    (service home-xdg-user-directories-service-type
             (home-xdg-user-directories-configuration
               (desktop "$HOME/Desktop/")
               (documents "$HOME/Documents/")
               (download "$HOME/Downloads/")
               (pictures "$HOME/Pictures/")
               (videos "$HOME/Videos/")))
    (simple-service 'env-variables-service
                    home-environment-variables-service-type
                    `(("LANG" . "en_US.utf8")
                      ("LC_ALL" . "en_US.utf8")
                      ("GPG_TTY" . "$(tty)")
                      ;; TODO: figure out how to pickup guix installed emacs packages
                      ;;("EMACSLOADPATH" . "$HOME/.guix-home/profile/share/emacs/site-lisp:/usr/share/emacs/site-lisp")
                      ;; set editor to use a new emacs frame,
                      ;; and start an emacs daemon if it does not yet
                      ;; exist
                      ("EDITOR" . "$(which emacsclient) -c -a=\"\"")
                      ("TERM" . "xterm-256color")
                      ;; TODO: only set when on foreign distro
                      ("SSL_CERT_DIR" . "/etc/ssl/certs")
                      ("SSL_CERT_FILE" . "/etc/ssl/certs/ca-certificates.crt")
                      ;; end foreign distro todo
                      ("GIT_SSL_CAINFO" . "$SSL_CERT_FILE")
                      ("CURL_CA_BUNDLE" . "$SSL_CERT_FILE")
                      ("LESSHISTFILE" . "$XDG_CACHE_HOME/.lesshst")
                      ("RIPGREP_CONFIG_PATH" . "$XDG_CONFIG_HOME/ripgreprc")
                      ("GOPATH" . "$HOME/.go")
                      ;; fix bad gui's
                      ("SDL_VIDEODRIVER" . "wayland")
                      ("QT_QPA_PLATFORM" . "wayland")
                      ("WEBKIT_DISABLE_COMPOSITING_MODE" . "1")
                      ("_JAVA_AWT_WM_NONREPARENTING" . "1")))
    (simple-service 'gnupg-files
                    home-files-service-type
                    `((".gnupg/gpg.conf" ,(local-file "configs/gpg.conf"))
                      (".gnupg/scdaemon.conf" ,(local-file "configs/scdaemon.conf"))))
    (simple-service 'ssh-config
                    home-files-service-type
                    `((".ssh/config" ,(local-file "configs/ssh-config"))))
    ;; TODO: get scripts working
    (simple-service 'scripts
                    home-files-service-type
                    `((".local/bin/reconfigure" ,(local-file "scripts/reconfigure"))))
    (simple-service 'config-files
                    home-xdg-configuration-files-service-type
                    (append
                     `(("dunst/dunstrc" ,(local-file "configs/dunstrc"))
                       ("i3/config" ,(local-file "configs/i3-config"))
                       ("i3status/config" ,(local-file "configs/i3status-config"))
                       ("i3status-rust/config.toml" ,(local-file "configs/i3status-rs.toml"))
                       ("xdg-desktop-portal/sway-portals.conf" ,(local-file "configs/xdg-desktop-portal-sway-portals.conf"))
                       ("sway/config" ,(local-file "configs/sway.config"))
                       ("polybar/config.ini" ,(local-file "configs/polybar.ini"))
                       ("polybar/launch" ,(local-file "configs/launch_polybar.sh"))
                       ("picom/picom.conf" ,(local-file "configs/picom.conf"))
                       ("rofi/config.rasi" ,(local-file "configs/rofi-config.rasi"))
                       ("rofi/theme.rasi" ,(local-file "configs/rofi-themes/black.rasi"))
                       ("starship.toml" ,(local-file "configs/starship.toml"))
                       ("ripgreprc" ,(local-file "configs/ripgreprc"))
                       ("git/config" ,(local-file "configs/git-config"))
                       ("git/ignore" ,(local-file "configs/git-ignore"))
                       ("wezterm/wezterm.lua" ,(local-file "configs/wezterm.lua"))
                       ("zellij/config.kdl" ,(local-file "configs/zellij-config.kdl")))
                     ;; Doom Emacs configuration - recursively copy entire directory
                     (directory->config-alist "configs/doom" "doom")))
    (simple-service 'extra-channels-service
                    home-channels-service-type
                    (list
                     (channel
                       (name 'guix)
                       (url "https://git.savannah.gnu.org/git/guix.git")
                       (branch "master")
                       (introduction
                        (make-channel-introduction
                         "9edb3f66fd807b096b48283debdcddccfea34bad"
                         (openpgp-fingerprint
                          "BBB0 2DDF 2CEA F6A8 0D1D  E643 A2A0 6DF2 A33A 54FA"))))
                     (channel
                       (name 'small-guix)
                       (url "https://codeberg.org/fishinthecalculator/small-guix.git")
                       (introduction
                        (make-channel-introduction
                         "f260da13666cd41ae3202270784e61e062a3999c"
                         (openpgp-fingerprint
                          "8D10 60B9 6BB8 292E 829B  7249 AED4 1CC1 93B7 01E2"))))
                     (channel
                       (name 'nonguix)
                       (url "https://gitlab.com/nonguix/nonguix")
                       (branch "master")
                       (introduction
                        (make-channel-introduction
                         "897c1a470da759236cc11798f4e0a5f7d4d59fbc"
                         (openpgp-fingerprint
                          "2A39 3FFF 68F4 EF7A 3D29  12AF 6F51 20A0 22FB B2D5"))))))
    (service home-gpg-agent-service-type
             (home-gpg-agent-configuration
               (pinentry-program
                (file-append pinentry "/bin/pinentry"))
               (ssh-support? #t)
               (extra-content "grab\nallow-emacs-pinentry\nallow-loopback-pinentry\n")))
    (service home-bash-service-type
             (home-bash-configuration
               (guix-defaults? #f)
               (aliases
                '(("docker-compose" . "docker compose")
                  ("ls" . "lsd")
                  ("vim" . "emacsclient -nw -a=''")
                  ("e" . "emacsclient -a=''")
                  ))
               (bashrc
                (list
                 (local-file "profiles/bash/bashrc" "bashrc")))
               (bash-profile
                (list
                 (local-file "profiles/bash/bash_profile"
                             "bash_profile")))
               (bash-logout
                (list
                 (local-file "profiles/bash/bash_logout"
                             "bash_logout"))))))))
