;; -*- mode: Scheme -*-
;; This "home-environment" file can be passed to 'guix home reconfigure'
;; to reproduce the content of your profile.  This is "symbolic": it only
;; specifies package names.  To reproduce the exact same profile, you also
;; need to capture the channels being used, as returned by "guix describe".
;; See the "Replicating Guix" section in the manual.

(use-modules
 (guix build utils)
 (gnu packages)
 (gnu services)
 (guix gexp)
 (guix channels)
 (gnu packages shells)
 (gnu packages gnupg)
 (gnu home)
 (gnu home services)
 (gnu home services guix)
 (gnu home services gnupg)
 (gnu home services shells))

(home-environment
 ;; Below is the list of packages that will show up in your
 ;; Home profile, under ~/.guix-home/profile.
 (packages
  (specifications->packages
   (list "guile"
         "glibc-locales"
         "inetutils"
         "i3status"
         "git"
         "nss-certs"
         "git-lfs"
         "fd"
         "ripgrep"
         "gnupg"
         "pinentry"
	 "du-dust"
	 "btop"
         "kubectl"
         "minikube"
         "k9s"
         "pciutils"
         "hwdata"
         "nmap"
         "strace"
         "kmonad"
         "node"
         "bat"
         "fontconfig"
         "curl"
         "aspell"
         "aspell-dict-en"
         "direnv"
	 "ranger"
         "mumi"
         "zoxide"
         "awscli@2.2.0"
         "font-fira-mono"
         "font-fira-sans"
         "font-fira-code"
         "font-awesome")))
 ;; Below is the list of Home services.  To search for available
 ;; services, run 'guix home search KEYWORD' in a terminal.
 (services
  (list
   (simple-service 'env-variables-service
                   home-environment-variables-service-type
                   `(("LANG" . "en_US.utf8")
                     ("LC_ALL" . "en_US.utf8")
                     ("GPG_TTY" . "$(tty)")
                     ("SSL_CERT_DIR" . "/etc/ssl/certs")
                     ("SSL_CERT_FILE" . "/etc/ssl/certs/ca-certificates.crt")
                     ("GIT_SSL_CAINFO" . "$SSL_CERT_FILE")
                     ("CURL_CA_BUNDLE" . "$SSL_CERT_FILE")
                     ("LESSHISTFILE" . "$XDG_CACHE_HOME/.lesshst")
                     ("_JAVA_AWT_WM_NONREPARENTING" . #t)))
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
                   `(("dunst/dunstrc" ,(local-file "configs/dunstrc"))
                     ("i3/config" ,(local-file "configs/i3-config"))
                     ("i3status/config" ,(local-file "configs/i3status-config"))
                     ("polybar/config.ini" ,(local-file "configs/polybar.ini"))
                     ("polybar/launch" ,(local-file "configs/launch_polybar.sh"))
                     ("picom/picom.conf" ,(local-file "configs/picom.conf"))
                     ("rofi/config.rasi" ,(local-file "configs/rofi-config.rasi"))
                     ("rofi/theme.rasi" ,(local-file "configs/rofi-themes/black.rasi"))
		     ("starship.toml" ,(local-file "configs/starship.toml"))
                     ("git/config" ,(local-file "configs/git-config"))
                     ("git/ignore" ,(local-file "configs/git-ignore"))
                     ("wezterm/wezterm.lua" ,(local-file "configs/wezterm.lua"))
                     ("zellij/config.kdl" ,(local-file "configs/zellij-config.kdl"))))
   (simple-service 'extra-channels-service
                   home-channels-service-type
                   (list (channel
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
                          (url "https://gitlab.com/orang3/small-guix")
                          ;; Enable signature verification:
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
             (aliases
              '(("docker-compose" . "docker compose")
                                        ;("ls" . "lsd"))
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
