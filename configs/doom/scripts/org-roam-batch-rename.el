;;; org-roam-rename-notes.el --- Rename org-roam notes to timestamp-id format

;;; Commentary:
;; This script renames all org-roam notes to the format:
;; YYYYMMDDHHMMSS-{id}.org.gpg
;; where the timestamp is the current time when the script runs
;; and the id is extracted from the file's :ID: property

;;; Code:

(require 'org-roam)

(defun org-roam-rename-notes-to-timestamp-format ()
  "Rename all org-roam notes to timestamp-id format."
  (interactive)
  (let ((rename-count 0)
        (skip-count 0)
        (error-count 0)
        (rename-log '()))

    ;; Ensure org-roam database is up to date
    (org-roam-db-sync)

    ;; Iterate over all org-roam nodes
    (dolist (node (org-roam-node-list))
      (let* ((id (org-roam-node-id node))
             (file (org-roam-node-file node))
             (dir (file-name-directory file))
             (old-basename (file-name-nondirectory file))
             (timestamp (format-time-string "%Y%m%d%H%M%S"))
             (new-basename (format "%s-%s.org.gpg" timestamp id))
             (new-file (expand-file-name new-basename dir)))

        (condition-case err
            (cond
             ;; Skip if file doesn't exist
             ((not (file-exists-p file))
              (setq skip-count (1+ skip-count))
              (push (format "SKIP: File not found: %s" file) rename-log))

             ;; Skip if already in correct format (ends with .org.gpg and has similar structure)
             ((string-match-p (format "^[0-9]\\{14\\}-%s\\.org\\.gpg$" (regexp-quote id)) old-basename)
              (setq skip-count (1+ skip-count))
              (push (format "SKIP: Already formatted: %s" old-basename) rename-log))

             ;; Skip if target file already exists
             ((file-exists-p new-file)
              (setq skip-count (1+ skip-count))
              (push (format "SKIP: Target exists: %s -> %s" old-basename new-basename) rename-log))

             ;; Perform the rename
             (t
              ;; Close any buffers visiting this file
              (when-let ((buf (find-buffer-visiting file)))
                (with-current-buffer buf
                  (save-buffer)
                  (kill-buffer)))

              ;; Rename the file
              (rename-file file new-file)

              ;; Update org-roam database with new file location
              (org-roam-db-update-file new-file)

              (setq rename-count (1+ rename-count))
              (push (format "RENAMED: %s -> %s" old-basename new-basename) rename-log)

              ;; If there are any associated files (like images), you might want to handle them here
              ))

          ;; Handle errors
          (error
           (setq error-count (1+ error-count))
           (push (format "ERROR: %s: %s" old-basename (error-message-string err)) rename-log)))))

    ;; Sync database after all renames
    (org-roam-db-sync)

    ;; Display results
    (with-current-buffer (get-buffer-create "*Org-Roam Rename Log*")
      (erase-buffer)
      (insert (format "=== Org-Roam Notes Rename Complete ===\n\n"))
      (insert (format "Total nodes processed: %d\n" (length (org-roam-node-list))))
      (insert (format "Files renamed: %d\n" rename-count))
      (insert (format "Files skipped: %d\n" skip-count))
      (insert (format "Errors: %d\n\n" error-count))
      (insert "=== Detailed Log ===\n\n")
      (dolist (entry (reverse rename-log))
        (insert entry "\n"))
      (goto-char (point-min))
      (display-buffer (current-buffer)))

    (message "Rename complete: %d renamed, %d skipped, %d errors"
             rename-count skip-count error-count)))

(defun org-roam-rename-notes-with-file-timestamp ()
  "Rename org-roam notes using file modification time as timestamp."
  (interactive)
  (let ((rename-count 0)
        (skip-count 0)
        (error-count 0)
        (rename-log '()))

    ;; Ensure org-roam database is up to date
    (org-roam-db-sync)

    ;; Iterate over all org-roam nodes
    (dolist (node (org-roam-node-list))
      (let* ((id (org-roam-node-id node))
             (file (org-roam-node-file node))
             (dir (file-name-directory file))
             (old-basename (file-name-nondirectory file))
             ;; Use file modification time instead of current time
             (file-time (nth 5 (file-attributes file)))
             (timestamp (format-time-string "%Y%m%d%H%M%S" file-time))
             (new-basename (format "%s-%s.org.gpg" timestamp id))
             (new-file (expand-file-name new-basename dir)))

        (condition-case err
            (cond
             ;; Skip if file doesn't exist
             ((not (file-exists-p file))
              (setq skip-count (1+ skip-count))
              (push (format "SKIP: File not found: %s" file) rename-log))

             ;; Skip if already in correct format
             ((string-match-p (format "^[0-9]\\{14\\}-%s\\.org\\.gpg$" (regexp-quote id)) old-basename)
              (setq skip-count (1+ skip-count))
              (push (format "SKIP: Already formatted: %s" old-basename) rename-log))

             ;; Skip if target file already exists
             ((file-exists-p new-file)
              (setq skip-count (1+ skip-count))
              (push (format "SKIP: Target exists: %s -> %s" old-basename new-basename) rename-log))

             ;; Perform the rename
             (t
              ;; Close any buffers visiting this file
              (when-let ((buf (find-buffer-visiting file)))
                (with-current-buffer buf
                  (save-buffer)
                  (kill-buffer)))

              ;; Rename the file
              (rename-file file new-file)

              ;; Update org-roam database with new file location
              (org-roam-db-update-file new-file)

              (setq rename-count (1+ rename-count))
              (push (format "RENAMED: %s -> %s" old-basename new-basename) rename-log)))

          ;; Handle errors
          (error
           (setq error-count (1+ error-count))
           (push (format "ERROR: %s: %s" old-basename (error-message-string err)) rename-log)))))

    ;; Sync database after all renames
    (org-roam-db-sync)

    ;; Display results
    (with-current-buffer (get-buffer-create "*Org-Roam Rename Log*")
      (erase-buffer)
      (insert (format "=== Org-Roam Notes Rename Complete ===\n\n"))
      (insert (format "Total nodes processed: %d\n" (length (org-roam-node-list))))
      (insert (format "Files renamed: %d\n" rename-count))
      (insert (format "Files skipped: %d\n" skip-count))
      (insert (format "Errors: %d\n\n" error-count))
      (insert "=== Detailed Log ===\n\n")
      (dolist (entry (reverse rename-log))
        (insert entry "\n"))
      (goto-char (point-min))
      (display-buffer (current-buffer)))

    (message "Rename complete: %d renamed, %d skipped, %d errors"
             rename-count skip-count error-count)))

(defun org-roam-rename-notes-dry-run ()
  "Perform a dry run to preview what files would be renamed."
  (interactive)
  (let ((would-rename 0)
        (would-skip 0)
        (preview-log '()))

    ;; Ensure org-roam database is up to date
    (org-roam-db-sync)

    ;; Iterate over all org-roam nodes
    (dolist (node (org-roam-node-list))
      (let* ((id (org-roam-node-id node))
             (file (org-roam-node-file node))
             (dir (file-name-directory file))
             (old-basename (file-name-nondirectory file))
             (timestamp (format-time-string "%Y%m%d%H%M%S"))
             (new-basename (format "%s-%s.org.gpg" timestamp id))
             (new-file (expand-file-name new-basename dir)))

        (cond
         ;; Skip if file doesn't exist
         ((not (file-exists-p file))
          (setq would-skip (1+ would-skip))
          (push (format "WOULD SKIP: File not found: %s" file) preview-log))

         ;; Skip if already in correct format
         ((string-match-p (format "^[0-9]\\{14\\}-%s\\.org\\.gpg$" (regexp-quote id)) old-basename)
          (setq would-skip (1+ would-skip))
          (push (format "WOULD SKIP: Already formatted: %s" old-basename) preview-log))

         ;; Skip if target file already exists
         ((file-exists-p new-file)
          (setq would-skip (1+ would-skip))
          (push (format "WOULD SKIP: Target exists: %s -> %s" old-basename new-basename) preview-log))

         ;; Would rename
         (t
          (setq would-rename (1+ would-rename))
          (push (format "WOULD RENAME: %s -> %s" old-basename new-basename) preview-log)))))

    ;; Display preview
    (with-current-buffer (get-buffer-create "*Org-Roam Rename Preview*")
      (erase-buffer)
      (insert (format "=== Org-Roam Notes Rename DRY RUN ===\n\n"))
      (insert (format "Total nodes: %d\n" (length (org-roam-node-list))))
      (insert (format "Would rename: %d\n" would-rename))
      (insert (format "Would skip: %d\n\n" would-skip))
      (insert "=== Preview ===\n\n")
      (dolist (entry (reverse preview-log))
        (insert entry "\n"))
      (goto-char (point-min))
      (display-buffer (current-buffer)))

    (message "Dry run complete: %d would be renamed, %d would be skipped"
             would-rename would-skip)))

(provide 'org-roam-rename-notes)
;;; org-roam-rename-notes.el ends here
