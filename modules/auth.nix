{ programs, config, pkgs, lib, ...}:
{
  # ssh
  programs.ssh = {
    enable = true;
    addKeysToAgent = "confirm 30m";
    hashKnownHosts = true;
    compression = true;

    matchBlocks = {
      "github.com" = {
        hostname = "github.com";
        user = "lockbox";
        identityFile = "~/.ssh/id_devkey";
      };
    };
  };

  services.ssh-agent.enable = false;

  services.gpg-agent = {
    enable = true;

    pinentryPackage = pkgs.pinentry-curses;

    extraConfig = ''
      allow-emacs-pinentry
      allow-loopback-pinentry
    '';
  };

  # gpg
  programs.gpg = {
    enable = true;

    scdaemonSettings = {
      disable-ccid = true;
      reader-port = "Yubico Yubi";
    };

    package = pkgs.gnupg.override {
        pcsclite = pkgs.pcsclite.overrideAttrs (old: {
          postPatch = old.postPatch + (lib.optionalString (!(lib.strings.hasInfix ''--replace-fail "libpcsclite_real.so.1"'' old.postPatch)) ''
            substituteInPlace src/libredirect.c src/spy/libpcscspy.c \
              --replace-fail "libpcsclite_real.so.1" "$lib/lib/libpcsclite_real.so.1"
          '');
        });
      };

    settings = {
      use-agent = true;

      # Assume that command line arguments are given as UTF8 strings.
      charset = "utf-8";

      # when outputting certificates, view user IDs distinctly from keys:
      fixed-list-mode = true;

      # long keyids are more collision-resistant than short keyids (it's trivial to make a key
      # with any desired short keyid)
      # NOTE: this breaks kmail gnupg support!
      keyid-format = "0xlong";

      # when multiple digests are supported by all recipients, choose the strongest one:
      personal-digest-preferences = "SHA512 SHA384 SHA256 SHA224";

      # when multiple ciphers are supported by all recipients, choose the strongest one:
      personal-cipher-preferences = "AES256 AES192 AES";

      # preferences chosen for new keys should prioritize stronger algorithms:
      default-preference-list = "SHA512 SHA384 SHA256 SHA224 AES256 AES192 AES CAST5 BZIP2 ZLIB ZIP Uncompressed";

      # You should always know at a glance which User IDs GPG thinks are legitimately bound to
      # the keys in the keyring:
      verify-options = "show-uid-validity";
      list-options = "show-uid-validity";


      # include an unambiguous indicator of which key made a signature:
      # (see http://thread.gmane.org/gmane.mail.notmuch.general/3721/focus=7234)
      # (and http://www.ietf.org/mail-archive/web/openpgp/current/msg00405.html)
      sig-notation = "issuer-fpr@notations.openpgp.fifthhorseman.net=%g";

      # when making an OpenPGP certification, use a stronger digest than the deafult SHA1
      cert-digest-algo = "SHA512";
      s2k-cipher-algo = "AES256";
      s2k-digest-algo = "SHA512";

      # defualt to keys.openpgp.org as keyserver
      keyserver = "keys.openpgp.org";
    };
  };

}
