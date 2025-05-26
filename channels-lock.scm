(list (channel
       (name 'guix)
       (url "https://git.guix.gnu.org/git/guix.git")
       (branch "master")
       (commit
        "409bbd801428b90701f625c38e6b5840f12a187b")
       (introduction
        (make-channel-introduction
         "9edb3f66fd807b096b48283debdcddccfea34bad"
         (openpgp-fingerprint
          "BBB0 2DDF 2CEA F6A8 0D1D  E643 A2A0 6DF2 A33A 54FA"))))
      (channel
       (name 'small-guix)
       (url "https://codeberg.org/fishinthecalculator/small-guix.git")
       (branch "master")
       (commit
        "8231a1bb9f3f134a25474175864a68e95473dc85")
       (introduction
        (make-channel-introduction
         "f260da13666cd41ae3202270784e61e062a3999c"
         (openpgp-fingerprint
          "8D10 60B9 6BB8 292E 829B  7249 AED4 1CC1 93B7 01E2"))))
      (channel
       (name 'nonguix)
       (url "https://gitlab.com/nonguix/nonguix")
       (branch "master")
       (commit
        "595c2155a61ef7e552269cb1c569a33e3ec32bb2")
       (introduction
        (make-channel-introduction
         "897c1a470da759236cc11798f4e0a5f7d4d59fbc"
         (openpgp-fingerprint
          "2A39 3FFF 68F4 EF7A 3D29  12AF 6F51 20A0 22FB B2D5")))))
