;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
(setq user-full-name "Jordan Moore"
      user-mail-address "lockbox@struct.foo")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-unicode-font' -- for unicode glyphs
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;
;;(setq doom-font (font-spec :family "Fira Code" :size 12 :weight 'semi-light)
;;      doom-variable-pitch-font (font-spec :family "Fira Sans" :size 13))
;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

;; Notes config variables
(defgroup lockbox/notes-group nil
  "lockbox notes config group."
  :group 'emacs)

;; Global notes are stored here, including all org etc.
(defcustom lockbox/notes-directory (expand-file-name "~/d/notes")
  "Path to lockbox notes directory."
  :type 'directory
  :group 'lockbox/notes-group
  )

;; Absolute path to the lockbox roam notes directory.
(setq lockbox/notes-notes-dir (expand-file-name "notes" lockbox/notes-directory))
;; Absolute path to the lockbox roam projects directory.
(setq lockbox/notes-projects-dir (expand-file-name "projects" lockbox/notes-directory))
;; Absolute path to the lockbox roam dailies directory.
(setq lockbox/notes-daily-dir (expand-file-name "daily" lockbox/notes-directory))
;; "Absolute path to the lockbox roam comms directory.
(setq lockbox/notes-comms-dir (expand-file-name "comms" lockbox/notes-directory))

;; List of paths to search for org content.
;;
;; We do not search daily logs, as things get copied *into* the dailies
;; as they are completed
(setq lockbox/org-file-directories
      (mapcar
       ;; foreach directory in the inner list, add the `*.org.gpg` wildcard path
       (lambda (dir) (concat dir "/*.org.gpg"))
       (list lockbox/notes-directory
             lockbox/notes-daily-dir
             lockbox/notes-projects-dir
             lockbox/notes-comms-dir)))

;; only define `hash-table-contains-p' if it isn't already present
(unless (fboundp 'hash-table-contains-p)
  (defsubst hash-table-contains-p (key table)
    "Return non-nil if TABLE has an element with KEY."
    (declare (side-effect-free t))
    (let ((missing '#:missing))
      (not (eq (gethash key table missing) missing)))))

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory lockbox/notes-directory)


;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `after!' block, otherwise Doom's defaults may override your settings. E.g.
;;
;;   (after! PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look up their documentation).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
                                        ;(setq doom-theme 'doom-outrun-electric)
(setq doom-theme 'doom-oceanic-next)
                                        ;(setq doom-theme 'doom-material-dark) ;ayu-dark)
;; TODO: add tomorrow-night-bright: https://github.com/ChrisKempson/Tomorrow-Theme

(global-hl-line-mode +1)
(show-paren-mode 1)
(setq show-paren-delay 0)

;; don't display line numbers
(setq display-line-numbers-type nil)

;; don't confirm exit
(setq confirm-kill-emacs nil)

;; keep backups etc.
(setq auto-save-default t)

;; CTRL+K removes entire line when at the beginning
(setq kill-whole-line t)

;; Move between windows plz
(windmove-default-keybindings)

;; Prevents some cases of Emacs flickering.
;;(add-to-list 'default-frame-alist '(inhibit-double-buffering . t))

;; wordcount in markdown, gfm and org mode
(setq doom-modeline-enable-word-count t)

;; emacs redo
(after! undo-fu
  (map! :map undo-fu-mode-map "C-?" #'undo-fu-only-redo))

;; options for numpydoc
(after! numpydoc
  (map! "C-c C-n" #'numpydoc-generate))
(setq numpydoc-insert-examples-block nil)

;;
;; org config, largely copied from <https://github.com/james-stoup/emacs-org-mode-tutorial>
;;
(after! org
  ;; The whole notes repo should get checked for agenda
  (setq org-agenda-files lockbox/org-file-directories)

  ;; When a TODO is set to a done state, record a timestamp
  (setq org-log-done 'time)

  ;; TODO states
  (setq org-todo-keywords
        '((sequence "TODO(t)" "PLANNING(p)" "IN-PROGRESS(i@/!)" "VERIFYING(v!)" "BLOCKED(b@)"  "|" "DONE(d!)" "OBE(o@!)" "WONT-DO(w@/!)" )
          ))

  ;; TODO colors
  (setq org-todo-keyword-faces
        '(
          ("TODO" . (:foreground "GoldenRod" :weight bold))
          ("PLANNING" . (:foreground "DeepPink" :weight bold))
          ("IN-PROGRESS" . (:foreground "Cyan" :weight bold))
          ("VERIFYING" . (:foreground "DarkOrange" :weight bold))
          ("BLOCKED" . (:foreground "Red" :weight bold))
          ("DONE" . (:foreground "LimeGreen" :weight bold))
          ("OBE" . (:foreground "LimeGreen" :weight bold))
          ("WONT-DO" . (:foreground "LimeGreen" :weight bold))
          ))

  ;; custom org-capture templates
  (setq org-capture-templates
        '(
          ("t" "Todo"
           entry (file+headline "~/d/notes/todo.org.gpg" "Tasks")
           "* TODO [#B] %?\n:Created: %T\n "
           :empty-lines 0)
          ("m" "Meeting"
           entry (file+datetree "~/d/notes/meetings.org.gpg")
           "* %? :meeting:%^g \n:Created: %T\n** Attendees\n*** \n** Notes\n** Action Items\n*** TODO [#A] "
           :tree-type week
           :clock-in t
           :clock-resume t
           :empty-lines 0)
          ))
  )

;;
;; org gpg config
;;
(after! org
  ;; path to gpg bin to use
  (setq epg-program "~/.guix-home/profile/bin/gpg")
  ;; enable org-crypt + magic gpg layer
  (org-crypt-use-before-save-magic)
  (setq org-tags-exclude-from-inheritance '("crypt"))

  ;; disable company mode in org mode
  (add-hook! 'org-mode-hook (lambda () (company-mode -1)))

  ;; gpg key to use for encryption
  (setq org-crypt-key "lockbox@struct.foo"))

;;
;; setup org-roam
;;
;; Commentary: The structure of every org-roam / org is different for each user,
;; and this represents the current iteration of my setup:
;;
;; ```
;; <org-directory>/
;;     - todo.org (misc TODO)
;;     - projects/ (project captures + gathered content)
;;     - daily/ (daily journal + task log)
;;     - notes/ (generic captures / ideas / notes)
;;     - comms/ (captures sourced from email/irc etc.)
;; ```
;;
;; The actual use of which is cenetered around a few main tags:
;; - work
;; - idea
;; - note
;; - project
;; - communication tags:
;;     Should consist of 2 tags:
;;       - medium (eg. irc)
;;       - specific (eg. libera#gentoo)
;;
;;     This allows better sorting on accounts etc. Note that there should also
;;     be information about the context of the capture in the details
(after! org-roam
  (setq org-roam-directory lockbox/notes-directory)
  (setq org-roam-dailies-directory lockbox/notes-daily-dir)

  ;; shortcut to capture notes for today
  (map!
   "C-c n j" #'org-roam-dailies-capture-today
   "C-c n n" #'org-roam-capture)

  (setq org-roam-capture-templates
        '(("n" "note" entry "** %?"
           :target (file+head "notes/%<%Y%m%d%H%M%S>-${id}.org.gpg"
                              "#+TITLE: ${title}\n#+category: ${title}\n:note:%^G \n")
           :unnarrowed t)
          ("p" "project" plain (file "~/.doom.d/templates/project_template.org")
           :target (file+head "projects/%<%Y%m%d%H%M%S>-${id}.org.gpg"
                              "#+title: ${title}\n#+category: ${title}\n#+filetags: project")
           :unnarrowed t)
          ("m" "meeting" entry "* %? :meeting:%^G \n:Created: %T\n** Attendees\n*** \n** Notes\n** Action Items\n*** TODO [#A] "
           :target (file+head+olp "meetings.org.gpg" "#+title: Meetings\n#+category: meeting\n" ("Meetings"))
           :clock-in t
           :clock-resume t
           :empty-lines 0
           :unnarrowed t)
          ("r" "TOREAD" entry "** %?"
           :target (file+head "notes/%<%Y%m%d%H%M%S>-${id}.org.gpg"
                              "#+TITLE: ${title}\n#+category: ${title}\n%^G\n- tags :: \n- source :: <>\n\n* ${title}\n  ")
           :unnarrowed t)))
  )

;; when new files are added, this hook should be invoked to update the global
;; org-agenda file listing
(defun lockbox/refresh-notes-org-gpg ()
  ;; collect all files we care about before adding the list to org-agenda
  (let ((collected-files  (mapcar (lambda (dir)(file-expand-wildcards dir)) lockbox/org-file-directories))

        )
    ;; add all the files we just globbed to org-agenda
    (setq org-agenda-files (flatten-tree collected-files))))


;; On every node capture, add the file to the agenda tracker if it was
;; not already present
(defun lockbox/org-roam-node-agenda-addition-hook ()
  ;; Add file to the agenda list if the capture completed
  (unless org-note-abort
    ;; TODO: make sure we arent' adding dailies in here w the following
    ;; nicer / simple code, so for now we roll w the brute force approach
    (lockbox/refresh-notes-org-gpg)))
                                        ;(with-current-buffer (org-capture-get :buffer)
                                        ;  ;; only adds `buffer-file-name' to the list if it is not already
                                        ;  ;; present in `org-agenda-files'
                                        ;  (add-to-list 'org-agenda-files (buffer-file-name)))))

;; register the hook
(add-hook! 'org-capture-after-finalize-hook #'lockbox/org-roam-node-agenda-addition-hook)

;;
;; add encrypted files to agenda files
;;
(after! org-agenda  (lockbox/refresh-notes-org-gpg))


;;
;; Do not auto-save org / gpg things to disk
;;
(defun disable-auto-save-for-specific-files ()
  (when (and buffer-file-name
             (or (string-suffix-p ".org" buffer-file-name)
                 (string-suffix-p ".gpg" buffer-file-name)))
    ;; Disable auto-save
    (auto-save-mode -1)))

;; add hook to selectively auto-save
(add-hook 'find-file-hook 'disable-auto-save-for-specific-files)

;; enable docker mode on files ending with `Dockerfile`'
(add-to-list 'auto-mode-alist '("Dockerfile\\'" . dockerfile-mode))

;;
;; Make cursor show up initally in org-agenda
;;
;; Commentary: The cursor does in fact show up, only after issuing a movement
;; command in some cases, this is annoying.
;;
;; To overcome this we can use [advise](https://www.gnu.org/software/emacs/manual/html_node/elisp/Advising-Functions.html)
;; to the offending code and set the cursor definition appropriately (ty
;; @lawlist on SO).
;;
;; Related:
;; - [Similar Stack Overflow question](https://emacs.stackexchange.com/questions/78420/use-keyboard-in-org-calendar)
;; - [Offending commit](https://list.orgmode.org/87d36uip6p.fsf@gnu.org/)
;; - [Offending code](https://github.com/emacs-mirror/emacs/blob/94ed2df02fa1841095041c8c26ad243052638e22/lisp/org/org.el#L13758)
;;
(defun my/fix-no-initial-org-agenda-cursor (orig-fun &rest args)
  (when (equal (car args) '(setq cursor-type nil))
    (setcar args '(setq cursor-type 'bar)))
  (apply orig-fun args))

(advice-add 'org-eval-in-calendar :around #'my/fix-no-initial-org-agenda-cursor)


;; automatically copy completed tasks to daily log
;;
;; Commentary: Not sure this will actually work -- edit: it does not work
;; copied from https://systemcrafters.net/build-a-second-brain-in-emacs/5-org-roam-hacks/
(defun my/org-roam-copy-todo-to-today ()
  (interactive)
  (let ((org-refile-keep t) ;; Set this to nil to delete the original!
        (org-roam-dailies-capture-templates
         '(("t" "tasks" entry "%?"
            :if-new (file+head+olp "%<%Y-%m-%d>.org" "#+title: %<%Y-%m-%d>\n" ("Tasks")))))
        (org-after-refile-insert-hook #'save-buffer)
        today-file
        pos)
    (save-window-excursion
      (org-roam-dailies--capture (current-time) t)
      (setq today-file (buffer-file-name))
      (setq pos (point)))

    ;; Only refile if the target file is different than the current file
    (unless (equal (file-truename today-file)
                   (file-truename (buffer-file-name)))
      (org-refile nil nil (list "Tasks" today-file nil pos)))))

;; register the hook to copy task data to daily log when completed
(after! org
  (add-to-list 'org-after-todo-state-change-hook
               (lambda ()
                 (when (equal org-state "DONE")
                   (my/org-roam-copy-todo-to-today)))))
;;
;; lsp
;;
(after! lsp-mode
  (setq lsp-file-watch-threshold 5000
        lsp-headerline-breadcrumb-enable t)
  (dolist (dir '("[/\\\\]target"
                 "[/\\\\]docs/build"))
    (push dir lsp-file-watch-ignored-directories)))

(after! lsp-ui
  (setq lsp-ui-peek-enable t
        lsp-ui-doc-include-signature t
        lsp-ui-doc-max-height 45
        lsp-ui-doc-max-width 100
        lsp-ui-doc-enable t))

;;
;; rss config
;;
(after! elfeed
  ;; elfeed db gets stored in notes
  (setq elfeed-db-directory (concat (file-name-as-directory org-directory) "elfeed"))
  ;; by default show unreads from past while and the not insanely high volume stuff
  (setq elfeed-search-filter "@6-month-ago +unread -arxiv -tux")
  ;; update when the elfeed buffer is opened
  (add-hook! 'elfeed-search-mode-hook #'elfeed-update))

(use-package! arei)
(after! arei
  (setq! arei-client-sync-timeout 30))

;;
;; github copilot
(use-package! copilot
  :hook (prog-mode . copilot-mode)
  :bind (:map copilot-completion-map
              ("<tab>" . 'copilot-accept-completion)
              ("TAB" . 'copilot-accept-completion)
              ("C-TAB" . 'copilot-accept-completion-by-word)
              ("C-<tab>" . 'copilot-accept-completion-by-word)
              ("C-n" . 'copilot-next-completion)
              ("C-p" . 'copilot-previous-completion))

  :config
  (add-to-list 'copilot-indentation-alist '(prog-mode . 2))
  (add-to-list 'copilot-indentation-alist '(org-mode . 2))
  (add-to-list 'copilot-indentation-alist '(text-mode . 2))
  (add-to-list 'copilot-indentation-alist '(closure-mode . 2))
  (add-to-list 'copilot-indentation-alist '(scheme-mode . 2))
  (add-to-list 'copilot-indentation-alist '(emacs-lisp-mode . 2)))
(after! copilot
  (setq! copilot-indent-offset-warning-disable t))

(use-package! claude-code-ide
  :bind ("C-c C-'" . claude-code-ide-menu)
  :config
  ;; enable emacs MCP tools
  (claude-code-ide-emacs-tools-setup)
  :custom
  (claude-code-ide-cli-path "/home/lockbox/p/zealot/prefix/bin/claude"))
