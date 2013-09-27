;;; helm-filelist.el --- helm interface for locate.
;;; Code:

(eval-when-compile (require 'cl))
(require 'helm)

(defgroup helm-filelist nil
  "Filelist related Applications and libraries for Helm."
  :group 'helm)

(defcustom helm-filelist-source-file "~/tmp/all.filelist"
  "Default source file of filelist to grep."
  :group 'helm-filelist
  :type 'string)

(defcustom helm-filelist-command nil
  "Executed command to grep filelist."
  :group 'helm-filelist
  :type 'string)

(defvar helm-generic-files-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map helm-map)
    (define-key map (kbd "C-]")     'helm-ff-run-toggle-basename)
    (define-key map (kbd "C-s")     'helm-ff-run-grep)
    (define-key map (kbd "M-g s")   'helm-ff-run-grep)
    (define-key map (kbd "M-g z")   'helm-ff-run-zgrep)
    (define-key map (kbd "M-g p")   'helm-ff-run-pdfgrep)
    (define-key map (kbd "M-D")     'helm-ff-run-delete-file)
    (define-key map (kbd "C-=")     'helm-ff-run-ediff-file)
    (define-key map (kbd "C-c =")   'helm-ff-run-ediff-merge-file)
    (define-key map (kbd "C-c o")   'helm-ff-run-switch-other-window)
    (define-key map (kbd "M-i")     'helm-ff-properties-persistent)
    (define-key map (kbd "C-c C-x") 'helm-ff-run-open-file-externally)
    (define-key map (kbd "C-c X")   'helm-ff-run-open-file-with-default-tool)
    (define-key map (kbd "M-.")     'helm-ff-run-etags)
    (define-key map (kbd "C-w")     'helm-yank-text-at-point)
    (define-key map (kbd "C-c ?")   'helm-generic-file-help)
    map)
  "Generic Keymap for files.")


(defun helm-c-filelist-init ()
  "Initialize async grep process for `helm-c-source-filelist'."
  (let ((helm-filelist-command "") (ret nil))
    ;; make filelist command
    (dolist (pattern (split-string helm-pattern))
      (if (equal helm-filelist-command "")
          (setq helm-filelist-command (concat "grep -i -E \"" pattern "\" " helm-filelist-source-file "|"))
        (setq helm-filelist-command (concat helm-filelist-command "grep -i -E \"" pattern "\"|"))
        )
      )
    (setq helm-filelist-command (replace-regexp-in-string "|+$" "" helm-filelist-command))
    ;; execute maked command
    (setq ret (start-process-shell-command
               "filelist-grep-process" helm-buffer helm-filelist-command
               )
          )
    ;; show infomation 
    (set-process-sentinel
     (get-process "filelist-grep-process")
     #'(lambda (process event)
         (if (string= event "finished\n")
             (with-helm-window
               (setq mode-line-format
                     '(" " mode-line-buffer-identification " "
                       (line-number-mode "%l") " "
                       (:eval (propertize
                               (format "[Grep Process Finish- (%s results)]"
                                       (max (1- (count-lines
                                                 (point-min) (point-max))) 0))
                               'face 'helm-grep-finish))))
               (force-mode-line-update))
           (helm-log "Error: Grep %s"
                     (replace-regexp-in-string "\n" "" event)))))
    ret
    )
  )

(defvar helm-c-source-filelist
  `((name . "Filelist")
    (candidates-process . helm-c-filelist-init)
    (type . file)
    (requires-pattern . 3)
    (history . ,'helm-file-name-history)
    (keymap . ,helm-generic-files-map)
    (help-message . helm-generic-file-help-message)
    (candidate-number-limit . 100)
    (mode-line . helm-generic-file-mode-line-string)
    (delayed))
  "Find files matching the current input pattern with grep from source file.")

(defun helm-c-filelist-read-file-name (prompt &optional init)
  (helm :sources
        '((name . "Filelist")
          (candidates-process . helm-c-filelist-init)
          (action . identity)
          (requires-pattern . 3)
          (candidate-number-limit . 100)
          (mode-line . helm-generic-file-mode-line-string)
          (delayed))
        :prompt prompt
        :input init
        :buffer "*helm filelist rfn*"))

(defun helm-find-filelist (&optional initial-input default)
  (helm :sources 'helm-c-source-filelist
        :buffer "*helm find filelist*"
        :input initial-input
        :default default)
  )

;;;###autoload
(defun helm-filelist (arg)
  "Preconfigured `helm' for grep filelist."
  (interactive "P")
  (setq helm-ff-default-directory default-directory)
  (helm-find-filelist arg))

(provide 'helm-filelist)

;; Local Variables:
;; byte-compile-warnings: (not cl-functions obsolete)
;; coding: utf-8
;; indent-tabs-mode: nil
;; End:
;;; helm-filelist.el ends here
