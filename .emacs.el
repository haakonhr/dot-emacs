;;; -*- mode: emacs-lisp -*-

;; Set the *Message* log to something higher

(setq message-log-max 8192)

;; Bootstrap the load-path, autoloads and el-get

(require 'autoloads)
(require 'initsplit)

(require 'recentf)
(setq recentf-auto-cleanup 'never)

(setq gnus-home-directory "~/Library/Mail/Gnus/") ; override gnus.el

;; Read in the Mac's global environment settings.

(defun read-mac-environment ()
  (let ((plist (expand-file-name "~/.MacOSX/environment.plist")))
    (when (file-readable-p plist)
      (let ((dict (cdr (assq 'dict (cdar (xml-parse-file plist))))))
        (while dict
          (when (and (listp (car dict)) (eq 'key (caar dict)))
            (setenv (car (cddr (car dict)))
                    (car (cddr (car (cddr dict))))))
          (setq dict (cdr dict))))
      (setq exec-path nil)
      (mapc #'(lambda (path) (add-to-list 'exec-path path))
            (nreverse (split-string (getenv "PATH") ":"))))))

(read-mac-environment)

;;;_* customizations

(load "~/.emacs.d/settings")

;;;_ + variables

;; '(initsplit-customizations-alist
;;   (quote
;;    (("\\`\\(canlock\\|eudc\\|gnus\\|nn[a-z]+\\|mm\\|message\\|\\(send-?\\|smtp\\|check-\\)?mail\\|spam\\|starttls\\|sc\\)-" "~/Library/Emacs/.gnus.el" nil nil)
;;     ("\\`\\(\\(org\\(2blog/wp\\)?\\|calendar\\|diary\\)-\\|mark-holidays-in-calendar\\'\\)" "~/Library/Emacs/.org.el" nil nil)
;;     ("\\`erc-nickserv-passwords\\'" "~/Library/Emacs/.passwd" nil nil))))
;; '(initsplit-pretty-print t)

;;;_ + disabled commands

(put 'downcase-region  'disabled nil)   ; Let upcasing work
(put 'erase-buffer     'disabled nil)
(put 'eval-expression  'disabled nil)   ; Let ESC-ESC work
(put 'narrow-to-page   'disabled nil)   ; Let narrowing work
(put 'narrow-to-region 'disabled nil)   ; Let narrowing work
(put 'set-goal-column  'disabled nil)
(put 'upcase-region    'disabled nil)   ; Let downcasing work

;;;_* packages

;;;_ + direct loads

(mapc #'(lambda (name) (load name t))
      '(
        "archive-region"
        "bookmark+"
        "browse-kill-ring+"
        "diminish"
        "edit-server"
        "escreen"
        "modeline-posn"
        "page-ext"
        "per-window-point"
        "pp-c-l"
        "session"
        "yasnippet"

        ".passwd"
        ".org"
        ".gnus"
        ))

;;;_ + language-specific

(mapc #'load
      (mapcar #'file-name-sans-extension
              (directory-files
               (expand-file-name "lang" user-emacs-directory) t "\\.el$" t)))

;;;_ + Drew Adams

(require 'compile-)
(setq compilation-message-face nil)
(eval-after-load "compile"
  '(require 'compile+))

(require 'diff-mode-)

(eval-after-load "hl-line"
  '(require 'hl-line+))

(eval-after-load "grep"
  '(progn
     (require 'grep+)
     (require 'grep-ed)))

(eval-after-load "info"
  '(progn
     (require 'easy-mmode)
     (require 'info+)))

;;;_ + anything

(autoload 'descbinds-anything "descbinds-anything" nil t)
(fset 'describe-bindings 'descbinds-anything)

(eval-after-load "anything"
  '(progn
     (require 'anything-match-plugin)
     (define-key anything-map [(alt ?v)] 'anything-previous-page)))

;;;_ + bbdb

(when (load "bbdb-autoloads" t)
  (bbdb-insinuate-w3)

  (eval-after-load "bbdb"
    '(progn
       (require 'bbdb-to-outlook)
       (require 'bbdb-pgp))))

;;;_ + css-mode

(add-to-list 'auto-mode-alist '("\\.css$" . css-mode))

;;;_ + dired-x

(defvar dired-delete-file-orig (symbol-function 'dired-delete-file))

;; Trash files instead of deleting them
(defun dired-delete-file (file &optional recursive)
  (if (string-match ":" dired-directory)
      (funcall dired-delete-file-orig)
    (if recursive
        (call-process "/Users/johnw/bin/del" nil nil nil "-fr" file)
      (call-process "/Users/johnw/bin/del" nil nil nil file))))

(defvar dired-omit-regexp-orig (symbol-function 'dired-omit-regexp))

;; Omit files that Git would ignore
(defun dired-omit-regexp ()
  (let ((file (expand-file-name ".git"))
        parent-dir)
    (while (and (not (file-exists-p file))
                (progn
                  (setq parent-dir
                        (file-name-directory
                         (directory-file-name
                          (file-name-directory file))))
                  ;; Give up if we are already at the root dir.
                  (not (string= (file-name-directory file)
                                parent-dir))))
      ;; Move up to the parent dir and try again.
      (setq file (expand-file-name ".git" parent-dir)))
    ;; If we found a change log in a parent, use that.
    (if (file-exists-p file)
        (let ((regexp (funcall dired-omit-regexp-orig))
              (omitted-files (shell-command-to-string "git clean -d -x -n")))
          (if (= 0 (length omitted-files))
              regexp
            (concat
             regexp
             (if (> (length regexp) 0)
                 "\\|" "")
             "\\("
             (mapconcat
              #'(lambda (str)
                  (concat "^"
                          (regexp-quote
                           (substring str 13
                                      (if (= ?/ (aref str (1- (length str))))
                                          (1- (length str))
                                        nil)))
                          "$"))
              (split-string omitted-files "\n" t)
              "\\|")
             "\\)")))
      (funcall dired-omit-regexp-orig))))

(eval-after-load "dired"
  '(progn
     (setq dired-use-ls-dired t)

     (define-key dired-mode-map [?l] 'dired-up-directory)
     (define-key dired-mode-map [tab] 'other-window)))

;;;_ + erc

(defun irc ()
  (interactive)
  (erc :server "irc.freenode.net" :port 6667 :nick "johnw" :password
       (cdr (assoc "johnw" (cadr (assq 'freenode erc-nickserv-passwords)))))
  (erc :server "irc.oftc.net" :port 6667 :nick "johnw"))

(defun im ()
  (interactive)
  (erc :server "localhost" :port 6667 :nick "johnw" :password
       (cdr (assoc "johnw" (cadr (assq 'BitlBee erc-nickserv-passwords))))))

(defun erc-tiny-frame ()
  (interactive)
  (with-selected-frame
      (make-frame '((width                . 80)
                    (height               . 22)
                    (left-fringe          . 0)
                    (right-fringe         . 0)
                    (vertical-scroll-bars . nil)
                    (unsplittable         . t)
                    (has-modeline-p       . nil)
                    (background-color     . "grey80")
                    (minibuffer           . nil)))
    (switch-to-buffer "#emacs")
    (set (make-local-variable 'mode-line-format) nil)))

(defcustom erc-priority-people-regexp ".*"
  "Regexp that matches BitlBee users you want active notification for."
  :type 'regexp
  :group 'erc)

(defcustom erc-growl-noise-regexp
  "\\(Logging in:\\|Signing off\\|You're now away\\|Welcome back\\)"
  "Regexp that matches BitlBee users you want active notification for."
  :type 'regexp
  :group 'erc)

(require 'alert)

;; Unless the user has recently typed in the ERC buffer, highlight the fringe
(alert-add-rule :status   '(buried visible idle)
                :severity '(moderate high urgent)
                :mode     'erc-mode
                :predicate
                #'(lambda (info)
                    (string-match (concat "\\`[^&]" erc-priority-people-regexp
                                          "@BitlBee\\'")
                                  (erc-format-target-and/or-network)))
                :persistent
                #'(lambda (info)
                    ;; If the buffer is buried, or the user has been idle for
                    ;; `alert-reveal-idle-time' seconds, make this alert
                    ;; persistent.  Normally, alerts become persistent after
                    ;; `alert-persist-idle-time' seconds.
                    (memq (plist-get info :status) '(buried idle)))
                :style 'fringe
                :continue t)

;; If the ERC buffer is not visible, tell the user through Growl 
(alert-add-rule :status 'buried
                :mode   'erc-mode
                :predicate
                #'(lambda (info)
                    (let ((message (plist-get info :message))
                          (erc-message (plist-get info :data)))
                      (and erc-message
                           (not (or (string-match "^\\** *Users on #" message)
                                    (string-match erc-growl-noise-regexp
                                                  message))))))
                :style 'growl
                :append t)

(alert-add-rule :mode 'erc-mode :style 'ignore :append t)

(defun my-erc-hook (&optional match-type nick message)
  "Shows a growl notification, when user's nick was mentioned.
If the buffer is currently not visible, makes it sticky."
  (alert (or message (buffer-string)) :severity 'high 
         :title (concat "ERC: " (or nick (buffer-name)))
         :data message))

(add-hook 'erc-text-matched-hook 'my-erc-hook)
(add-hook 'erc-insert-modify-hook 'my-erc-hook)

;;;_ + escreen

(escreen-install)

(define-key escreen-map "\\" 'toggle-input-method)

(defvar escreen-e21-mode-line-string "[0]")
(defun escreen-e21-mode-line-update ()
  (setq escreen-e21-mode-line-string
        (format "[%d]" escreen-current-screen-number))
  (force-mode-line-update))

(let ((point (or
              ;; GNU Emacs 21.3.50 or later
              (memq 'mode-line-position mode-line-format)
              ;; GNU Emacs 21.3.1
              (memq 'mode-line-buffer-identification mode-line-format)))
      (escreen-mode-line-elm '(t (" " escreen-e21-mode-line-string))))
  (when (null (member escreen-mode-line-elm mode-line-format))
    (setcdr point (cons escreen-mode-line-elm (cdr point)))))

(add-hook 'escreen-goto-screen-hook 'escreen-e21-mode-line-update)

;;;_  + eshell

(defun eshell-spawn-external-command (beg end)
   "Parse and expand any history references in current input."
   (save-excursion
     (goto-char end)
     (when (looking-back "&!" beg)
       (delete-region (match-beginning 0) (match-end 0))
       (goto-char beg)
       (insert "spawn "))))

(add-hook 'eshell-expand-input-functions 'eshell-spawn-external-command)

(defun ss (server)
  (interactive "sServer: ")
  (call-process "spawn" nil nil nil "ss" server))

(eval-after-load "em-unix"
  '(unintern 'eshell/rm))

;;;_ + git

(defun commit-after-save ()
  (let ((file (file-name-nondirectory (buffer-file-name))))
    (message "Committing changes to Git...")
    (if (call-process "git" nil nil nil "add" file)
        (if (call-process "git" nil nil nil "commit" "-m"
                          (concat "changes to " file))
            (message "Committed changes to %s" file)))))

(setenv "GIT_PAGER" "")

(add-hook 'magit-log-edit-mode-hook
          (function
           (lambda ()
             (set-fill-column 72)
             (column-number-mode t)
             (column-marker-1 72)
             (flyspell-mode)
             (orgstruct++-mode))))

(eval-after-load "magit"
  '(progn
     (require 'magit-topgit)
     (require 'rebase-mode)))

;;;_ + ido

(defun ido-smart-select-text ()
  "Select the current completed item.  Do NOT descend into directories."
  (interactive)
  (when (and (or (not ido-require-match)
                 (if (memq ido-require-match
                           '(confirm confirm-after-completion))
                     (if (or (eq ido-cur-item 'dir)
                             (eq last-command this-command))
                         t
                       (setq ido-show-confirm-message t)
                       nil))
                 (ido-existing-item-p))
             (not ido-incomplete-regexp))
    (when ido-current-directory
      (setq ido-exit 'takeprompt)
      (unless (and ido-text (= 0 (length ido-text)))
        (let ((match (ido-name (car ido-matches))))
          (throw 'ido
                 (setq ido-selected
                       (if match
                           (replace-regexp-in-string "/\\'" "" match)
                         ido-text)
                       ido-text ido-selected
                       ido-final-text ido-text)))))
    (exit-minibuffer)))

(add-hook 'ido-minibuffer-setup-hook
          (lambda ()
            (define-key ido-file-completion-map "\C-m"
              'ido-smart-select-text)))

;;;_ + modeline-posn

(size-indication-mode)

;;;_ + mule

(prefer-coding-system 'utf-8)
(set-terminal-coding-system 'utf-8)
(setq x-select-request-type '(UTF8_STRING COMPOUND_TEXT TEXT STRING))

(defun normalize-file ()
  (interactive)
  (goto-char (point-min))
  (delete-trailing-whitespace)
  (set-buffer-file-coding-system 'unix)
  (save-excursion
    (goto-char (point-min))
    (while (re-search-forward "\r$" nil t)
      (replace-match "")))
  (set-buffer-file-coding-system 'utf-8)
  (untabify (point-min) (point-max))
  (let ((require-final-newline t))
    (save-buffer)))

;;;_ * nroff-mode

(defun update-nroff-timestamp ()
  (save-excursion
    (goto-char (point-min))
    (when (re-search-forward "^\\.Dd ")
      (let ((stamp (format-time-string "%B %e, %Y")))
        (unless (looking-at stamp)
          (delete-region (point) (line-end-position))
          (insert stamp)
          (let (after-save-hook)
            (save-buffer)))))))

(add-hook 'nroff-mode-hook
          (function
           (lambda ()
             (add-hook 'after-save-hook 'update-nroff-timestamp nil t))))

;;;_ + org-mode

(defun jump-to-org-agenda ()
  (interactive)
  (unless (featurep 'org-agenda)
    (load ".org"))
  (let ((buf (get-buffer "*Org Agenda*"))
        wind)
    (if buf
        (if (setq wind (get-buffer-window buf))
            (when (called-interactively-p 'any)
              (select-window wind)
              (org-fit-window-to-buffer))
          (if (called-interactively-p 'any)
              (progn
                (select-window (display-buffer buf t t))
                (org-fit-window-to-buffer))
            (with-selected-window (display-buffer buf)
              (org-fit-window-to-buffer))))
      (call-interactively 'org-agenda-list))))

(run-with-idle-timer 300 t 'jump-to-org-agenda)

;;;_ + per-window-point

(pwp-mode)

;;;_ + pp-c-l

(pretty-control-l-mode 1)

;;;_ * puppet-mode

(add-to-list 'auto-mode-alist '("\\.pp$" . puppet-mode))

;;;_ + session

(defun save-information ()
  (dolist (func kill-emacs-hook)
    (unless (memq func '(exit-gnus-on-exit server-force-stop))
      (funcall func)))
  (unless (eq 'listen (process-status server-process))
    (server-start)))

(run-with-idle-timer 300 t 'save-information)

;;;_ + vc

(eval-after-load "vc-hooks"
  '(defun vc-default-mode-line-string (backend file)
     "Return string for placement in modeline by `vc-mode-line' for FILE.
Format:

  \"BACKEND-REV\"        if the file is up-to-date
  \"BACKEND:REV\"        if the file is edited (or locked by the calling user)
  \"BACKEND:LOCKER:REV\" if the file is locked by somebody else
  \"BACKEND@REV\"        if the file was locally added
  \"BACKEND!REV\"        if the file contains conflicts or was removed
  \"BACKEND?REV\"        if the file is under VC, but is missing

This function assumes that the file is registered."
     (let* ((backend-name (symbol-name backend))
            (state   (vc-state file backend))
            (state-echo nil)
            (rev     (vc-working-revision file backend)))
       (if (with-temp-buffer
             (when (= 0 (call-process "git" nil (current-buffer) nil
                                      "stash" "list"))
               (goto-char (point-min))
               (not (eobp))))
           (setq rev (propertize rev 'face 'custom-invalid))
         (if (with-temp-buffer
               (when (= 0 (call-process "git" nil (current-buffer) nil
                                        "ls-files" "--modified"))
                 (goto-char (point-min))
                 (not (eobp))))
             (setq rev (propertize rev 'face 'bold))))
       (propertize
        (cond ((or (eq state 'up-to-date)
                   (eq state 'needs-update))
               (setq state-echo "Up to date file")
               (concat backend-name "-" rev))
              ((stringp state)
               (setq state-echo (concat "File locked by" state))
               (concat backend-name ":" state ":" rev))
              ((eq state 'added)
               (setq state-echo "Locally added file")
               (concat backend-name "@" rev))
              ((eq state 'conflict)
               (setq state-echo "File contains conflicts after the last merge")
               (concat backend-name "!" rev))
              ((eq state 'removed)
               (setq state-echo "File removed from the VC system")
               (concat backend-name "!" rev))
              ((eq state 'missing)
               (setq state-echo "File tracked by the VC system, but missing from the file system")
               (concat backend-name "?" rev))
              (t
               ;; Not just for the 'edited state, but also a fallback
               ;; for all other states.  Think about different symbols
               ;; for 'needs-update and 'needs-merge.
               (setq state-echo "Locally modified file")
               (concat backend-name ":" rev)))
        'help-echo (concat state-echo " under the " backend-name
                           " version control system")))))

;;;_ + vkill

(eval-after-load "vkill"
  '(setq vkill-show-all-processes t))


;;;_ + w3m

(setq w3m-command "/opt/local/bin/w3m")

;;;_ + whitespace

(remove-hook 'find-file-hooks 'whitespace-buffer)
(remove-hook 'kill-buffer-hook 'whitespace-buffer)

(add-hook 'find-file-hooks 'maybe-turn-on-whitespace t)

(defun maybe-turn-on-whitespace ()
  "Depending on the file, maybe turn on `whitespace-mode'."
  (let ((file (expand-file-name ".clean"))
        parent-dir)
    (while (and (not (file-exists-p file))
                (progn
                  (setq parent-dir
                        (file-name-directory
                         (directory-file-name
                          (file-name-directory file))))
                  ;; Give up if we are already at the root dir.
                  (not (string= (file-name-directory file)
                                parent-dir))))
      ;; Move up to the parent dir and try again.
      (setq file (expand-file-name ".clean" parent-dir)))
    ;; If we found a change log in a parent, use that.
    (when (and (file-exists-p file)
               (not (file-exists-p ".noclean"))
               (not (and buffer-file-name
                         (string-match "\\.texi$" buffer-file-name))))
      (add-hook 'write-contents-hooks
                #'(lambda ()
                    (ignore (whitespace-cleanup))) nil t)
      (whitespace-cleanup))))

;;;_ + yasnippet

(yas/initialize)
(yas/load-directory (expand-file-name "snippets/" user-emacs-directory))

;;;_ + diminish (this must come last)

(diminish 'abbrev-mode)
(diminish 'auto-fill-function)
(ignore-errors
  (diminish 'yas/minor-mode))

(defadvice dired-omit-startup (after diminish-dired-omit activate)
  "Make sure to remove \"Omit\" from the modeline."
  (diminish 'dired-omit-mode))

(eval-after-load "dot-mode"
  '(diminish 'dot-mode))
(eval-after-load "filladapt"
  '(diminish 'filladapt-mode))
(eval-after-load "winner"
  '(ignore-errors (diminish 'winner-mode)))

;;;_* keybindings

;;;_ + global

(define-key global-map [(control meta backspace)] 'backward-kill-sexp)
(define-key global-map [(control meta delete)]    'backward-kill-sexp)

(define-key global-map [(meta ?/)] 'dabbrev-expand)
(define-key global-map [(meta ??)] 'anything-dabbrev-expand)

(defun smart-beginning-of-line (&optional arg)
  (interactive "p")
  (let ((here (point)))
    (beginning-of-line-text arg)
    (if (= here (point))
        (beginning-of-line arg))))

;;(define-key global-map [(control ?.)] 'smart-beginning-of-line)
(define-key global-map [(control ?.)] 'ace-jump-mode)

(defun tidy-xml-buffer ()
  (interactive)
  (save-excursion
    (call-process-region (point-min) (point-max) "tidy" t t nil
                         "-xml" "-i" "-wrap" "0" "-omit" "-q")))

(define-key global-map [(control shift ?h)] 'tidy-xml-buffer)

(defun isearch-backward-other-window ()
  (interactive)
  (split-window-vertically)
  (call-interactively 'isearch-backward))

(define-key global-map [(control meta ?r)] 'isearch-backward-other-window)

(defun isearch-forward-other-window ()
  (interactive)
  (split-window-vertically)
  (call-interactively 'isearch-forward))

(define-key global-map [(control meta ?s)] 'isearch-forward-other-window)

(defun collapse-or-expand ()
  (interactive)
  (if (> (length (window-list)) 1)
      (delete-other-windows)
    (bury-buffer)))

(define-key global-map [(control ?z)] 'collapse-or-expand)

(defun delete-indentation-forward ()
  (interactive)
  (delete-indentation t))

(define-key global-map [(meta ?n)] 'ignore)
(define-key global-map [(meta ?p)] 'ignore)

(define-key global-map [(meta ?j)] 'delete-indentation-forward)
(define-key global-map [(meta ?J)] 'delete-indentation)

(define-prefix-command 'lisp-find-map)
(define-key global-map [(control ?h) ?e] 'lisp-find-map)
(define-key lisp-find-map [?a] 'apropos)
(define-key lisp-find-map [?e] 'view-echo-area-messages)
(define-key lisp-find-map [?f] 'find-function)
(define-key lisp-find-map [?i] 'info-apropos)
(define-key lisp-find-map [?v] 'find-variable)
(define-key lisp-find-map [?k] 'find-function-on-key)

(defun gnus-level-1 ()
  (interactive)
  (gnus 1))

(define-key global-map [(meta ?B)] 'bbdb)
(define-key global-map [(meta ?C)] 'jump-to-org-agenda)
(define-key global-map [(meta ?G)] 'gnus-level-1)
(define-key global-map [(meta ?m)] 'org-smart-capture)
(define-key global-map [(meta ?M)] 'org-inline-note)
(define-key global-map [(meta ?N)] 'winner-redo)
(define-key global-map [(meta ?P)] 'winner-undo)
(define-key global-map [(meta ?T)] 'gtags-find-with-grep)
;;(define-key global-map [(meta ?T)] 'tags-search)

(define-key global-map [(meta ?:)] 'pp-eval-expression)
(define-key global-map [(meta ?\')] 'insert-pair)
(define-key global-map [(meta ?\")] 'insert-pair)

(defun align-code (beg end &optional arg)
  (interactive "rP")
  (if (null arg)
      (align beg end)
    (let ((end-mark (copy-marker end)))
      (indent-region beg end-mark nil)
      (align beg end-mark))))

(define-key global-map [(meta ?\[)] 'align-code)
(define-key global-map [(meta ?`)]  'other-frame)
(define-key global-map [(alt ?`)]   'other-frame)

(defun mark-line (&optional arg)
  (interactive "p")
  (beginning-of-line)
  (let ((here (point)))
    (dotimes (i arg)
      (end-of-line))
    (set-mark (point))
    (goto-char here)))

(defun mark-sentence (&optional arg)
  (interactive "P")
  (backward-sentence)
  (mark-end-of-sentence arg))

(define-key global-map [(meta shift ?w)] 'mark-word)
(define-key global-map [(meta shift ?l)] 'mark-line)
(define-key global-map [(meta shift ?s)] 'mark-sentence)
(define-key global-map [(meta shift ?x)] 'mark-sexp)
(define-key global-map [(meta shift ?h)] 'mark-paragraph)
(define-key global-map [(meta shift ?d)] 'mark-defun)

(define-key global-map [(control return)] 'other-window)

(define-key global-map [f9] 'gud-cont)
(define-key global-map [f10] 'gud-next)
(define-key global-map [f11] 'gud-step)
(define-key global-map [(shift f11)] 'gud-finish)

(define-key global-map [(alt ?v)] 'scroll-down)
(define-key global-map [(meta ?v)] 'yank)

(define-key global-map [(alt tab)]
  #'(lambda ()
      (interactive)
      (call-interactively (key-binding (kbd "M-TAB")))))

;;;_ + ctl-x

(defun ido-bookmark-jump (bookmark &optional display-func)
  (interactive
   (list
    (ido-completing-read "Jump to bookmark: "
                         (mapcar #'car bookmark-alist)
                         nil 0 nil 'bookmark-history)))
  (unless bookmark
    (error "No bookmark specified"))
  (bookmark-maybe-historicize-string bookmark)
  (bookmark--jump-via bookmark (or display-func 'switch-to-buffer)))

(define-key ctl-x-map [?B] 'ido-bookmark-jump)
(define-key ctl-x-map [?r ?b] 'ido-bookmark-jump)

(define-key ctl-x-map [?d] 'delete-whitespace-rectangle)
(define-key ctl-x-map [?g] 'magit-status)

(defun my-gnus-compose-mail ()
  (interactive)
  (call-interactively 'compose-mail))

(define-key ctl-x-map [?m] 'my-gnus-compose-mail)

(define-key ctl-x-map [?t] 'toggle-truncate-lines)

(defun unfill-paragraph (arg)
  (interactive "*p")
  (let (beg end)
    (forward-paragraph arg)
    (setq end (copy-marker (- (point) 2)))
    (backward-paragraph arg)
    (if (eolp)
        (forward-char))
    (setq beg (point-marker))
    (when (> (count-lines beg end) 1)
      (while (< (point) end)
        (goto-char (line-end-position))
        (let ((sent-end (memq (char-before) '(?. ?\; ?! ??))))
          (delete-indentation 1)
          (if sent-end
              (insert ? )))
        (end-of-line))
      (save-excursion
        (goto-char beg)
        (while (re-search-forward "[^.;!?:]\\([ \t][ \t]+\\)" end t)
          (replace-match " " nil nil nil 1))))))

(defun unfill-region (beg end)
  (interactive "r")
  (setq end (copy-marker end))
  (save-excursion
    (goto-char beg)
    (while (< (point) end)
      (unfill-paragraph 1)
      (forward-paragraph))))

(defun refill-paragraph (arg)
  (interactive "*P")
  (let ((fun (if (memq major-mode '(c-mode c++-mode))
                 'c-fill-paragraph
               (or fill-paragraph-function
                   'fill-paragraph)))
        (width (if (numberp arg) arg))
        prefix beg end)
    (forward-paragraph 1)
    (setq end (copy-marker (- (point) 2)))
    (forward-line -1)
    (let ((b (point)))
      (skip-chars-forward "^A-Za-z0-9`'\"(")
      (setq prefix (buffer-substring-no-properties b (point))))
    (backward-paragraph 1)
    (if (eolp)
        (forward-char))
    (setq beg (point-marker))
    (delete-horizontal-space)
    (while (< (point) end)
      (delete-indentation 1)
      (end-of-line))
    (let ((fill-column (or width fill-column))
          (fill-prefix prefix))
      (if prefix
          (setq fill-column
                (- fill-column (* 2 (length prefix)))))
      (funcall fun nil)
      (goto-char beg)
      (insert prefix)
      (funcall fun nil))
    (goto-char (+ end 2))))

(define-key ctl-x-map [(meta ?q)] 'refill-paragraph)
(define-key mode-specific-map [(meta ?q)] 'unfill-paragraph)

(if (functionp 'ibuffer)
    (define-key ctl-x-map [(control ?b)] 'ibuffer)
  (define-key ctl-x-map [(control ?b)] 'list-buffers))

(defun duplicate-line ()
  "Duplicate the line containing point."
  (interactive)
  (save-excursion
    (let (line-text)
      (goto-char (line-beginning-position))
      (let ((beg (point)))
        (goto-char (line-end-position))
        (setq line-text (buffer-substring beg (point))))
      (if (eobp)
          (insert ?\n)
        (forward-line))
      (open-line 1)
      (insert line-text))))

(define-key ctl-x-map [(control ?d)] 'duplicate-line)
(define-key ctl-x-map [(control ?z)] 'eshell-toggle)
(define-key ctl-x-map [(meta ?z)] 'shell-toggle)

;;;_ + mode-specific

(define-key mode-specific-map [tab] 'ff-find-other-file)

(define-key mode-specific-map [space] 'just-one-space)
(define-key mode-specific-map [? ] 'just-one-space)

;; inspired by Erik Naggum's `recursive-edit-with-single-window'
(defmacro recursive-edit-preserving-window-config (body)
  "*Return a command that enters a recursive edit after executing BODY.
 Upon exiting the recursive edit (with\\[exit-recursive-edit] (exit)
 or \\[abort-recursive-edit] (abort)), restore window configuration
 in current frame."
  `(lambda ()
     "See the documentation for `recursive-edit-preserving-window-config'."
     (interactive)
     (save-window-excursion
       ,body
       (recursive-edit))))

(define-key mode-specific-map [?0]
  (recursive-edit-preserving-window-config (delete-window)))
(define-key mode-specific-map [?1]
  (recursive-edit-preserving-window-config
   (if (one-window-p 'ignore-minibuffer)
       (error "Current window is the only window in its frame")
     (delete-other-windows))))

(define-key mode-specific-map [?a] 'org-agenda)

(defun find-grep-in-project (command-args)
  (interactive
   (progn
     (list (read-shell-command "Run find (like this): "
                               '("git ls-files -z | xargs -0 egrep -nH -e " . 41)
                               'grep-find-history))))
  (when command-args
    (let ((null-device nil))		; see grep
      (grep command-args))))

(define-prefix-command 'my-grep-map)
(define-key mode-specific-map [?b] 'my-grep-map)
(define-key mode-specific-map [?b ?a] 'anything-do-grep)
(define-key mode-specific-map [?b ?b] 'anything-occur)
(define-key mode-specific-map [?b ?d] 'find-grep-dired)
(define-key mode-specific-map [?b ?f] 'find-grep)
(define-key mode-specific-map [?b ?F] 'anything-for-files)
(define-key mode-specific-map [?b ?g] 'grep)
(define-key mode-specific-map [?b ?n] 'find-name-dired)
(define-key mode-specific-map [?b ?o] 'occur)
(define-key mode-specific-map [?b ?p] 'find-grep-in-project)
(define-key mode-specific-map [?b ?r] 'rgrep)

(define-key global-map [(meta ?s) ?a] 'anything-do-grep)
(define-key global-map [(meta ?s) ?b] 'anything-occur)
(define-key global-map [(meta ?s) ?d] 'find-grep-dired)
(define-key global-map [(meta ?s) ?f] 'find-grep)
(define-key global-map [(meta ?s) ?F] 'anything-for-files)
(define-key global-map [(meta ?s) ?g] 'grep)
(define-key global-map [(meta ?s) ?n] 'find-name-dired)
(define-key global-map [(meta ?s) ?p] 'find-grep-in-project)
(define-key global-map [(meta ?s) ?r] 'rgrep)

(define-key mode-specific-map [?c] 'compile)
(define-key mode-specific-map [?C] 'indirect-region)

(defun delete-current-line (&optional arg)
  (interactive "p")
  (let ((here (point)))
    (beginning-of-line)
    (kill-line arg)
    (goto-char here)))

(define-key mode-specific-map [?d] 'delete-current-line)

(defun do-eval-buffer ()
  (interactive)
  (call-interactively 'eval-buffer)
  (message "Buffer has been evaluated"))

(defun scratch ()
  (interactive)
  (switch-to-buffer-other-window (get-buffer-create "*scratch*"))
  ;;(lisp-interaction-mode)
  (text-mode)
  (goto-char (point-min))
  (when (looking-at ";")
    (forward-line 4)
    (delete-region (point-min) (point)))
  (goto-char (point-max)))

(defun find-which (name)
  (interactive "sCommand name: ")
  (find-file-other-window
   (substring (shell-command-to-string (format "which %s" name)) 0 -1)))

(define-key global-map [(control ?h) ?e ?a] 'anything-apropos)
(define-key mode-specific-map [?e ?a] 'anything-apropos)
(define-key mode-specific-map [?e ?b] 'do-eval-buffer)
(define-key mode-specific-map [?e ?c] 'cancel-debug-on-entry)
(define-key mode-specific-map [?e ?d] 'debug-on-entry)
(define-key mode-specific-map [?e ?f] 'emacs-lisp-byte-compile-and-load)
(define-key mode-specific-map [?e ?r] 'eval-region)
(define-key mode-specific-map [?e ?l] 'find-library)
(define-key mode-specific-map [?e ?s] 'scratch)
(define-key mode-specific-map [?e ?v] 'edit-variable)
(define-key mode-specific-map [?e ?w] 'find-which)
(define-key mode-specific-map [?e ?e] 'toggle-debug-on-error)
(define-key mode-specific-map [?e ?E] 'elint-current-buffer)
(define-key mode-specific-map [?e ?z] 'byte-recompile-directory)

(define-key mode-specific-map [?f] 'flush-lines)
(define-key mode-specific-map [?g] 'goto-line)

(define-key mode-specific-map [?i ?b] 'flyspell-buffer)
(define-key mode-specific-map [?i ?c] 'ispell-comments-and-strings)
(define-key mode-specific-map [?i ?d] 'ispell-change-dictionary)
(define-key mode-specific-map [?i ?f] 'flyspell-mode)
(define-key mode-specific-map [?i ?k] 'ispell-kill-ispell)
(define-key mode-specific-map [?i ?m] 'ispell-message)
(define-key mode-specific-map [?i ?r] 'ispell-region)

(define-key mode-specific-map [?j] 'dired-jump)
(define-key mode-specific-map [?J] 'dired-jump-other-window)

(defun dired-double-jump (first-dir second-dir)
  (interactive
   (list (ido-read-directory-name "First directory: "
                                  (expand-file-name "~/") "~/dl")
         (ido-read-directory-name "Second directory: "
                                  (expand-file-name "~/") "~/dl")))
  (dired first-dir)
  (dired-other-window second-dir))

(define-key mode-specific-map [?J] 'dired-double-jump)

(define-key mode-specific-map [(control ?j)] 'dired-jump)
(define-key mode-specific-map [?k] 'keep-lines)

(defun my-ledger-start-entry (&optional arg)
  (interactive "p")
  (find-file-other-window "~/Documents/Accounts/ledger.dat")
  (goto-char (point-max))
  (skip-syntax-backward " ")
  (if (looking-at "\n\n")
      (goto-char (point-max))
    (delete-region (point) (point-max))
    (insert ?\n)
    (insert ?\n))
  (insert (format-time-string "%Y/%m/%d ")))

(define-key mode-specific-map [?L] 'my-ledger-start-entry)

(defun emacs-min ()
  (interactive)
  (set-frame-parameter (selected-frame) 'fullscreen nil)
  (set-frame-parameter (selected-frame) 'top 26)
  (set-frame-parameter (selected-frame) 'left
                       (- (x-display-pixel-width) 937))
  (set-frame-parameter (selected-frame) 'width 100)
  (set-frame-parameter (selected-frame) 'height 100))

(defun emacs-max ()
  (interactive)
  (if t
      (set-frame-parameter (selected-frame) 'fullscreen 'fullboth)
    (set-frame-parameter (selected-frame) 'top 26)
    (set-frame-parameter (selected-frame) 'left 2)
    (set-frame-parameter (selected-frame) 'width
                         (floor (/ (float (x-display-pixel-width)) 9.15)))
    (set-frame-parameter (selected-frame) 'height 100)))

(defun emacs-toggle-size ()
  (interactive)
  (if (> (cdr (assq 'width (frame-parameters))) 100)
      (emacs-min)
    (emacs-max)))

(define-key mode-specific-map [?m] 'emacs-toggle-size)

(defcustom user-initials nil
  "*Initials of this user."
  :set
  #'(lambda (symbol value)
      (if (fboundp 'font-lock-add-keywords)
          (mapc
           #'(lambda (mode)
               (font-lock-add-keywords
                mode (list (list (concat "\\<\\(" value " [^:\n]+\\):")
                                 1 font-lock-warning-face t))))
           '(c-mode c++-mode emacs-lisp-mode lisp-mode
                    python-mode perl-mode java-mode groovy-mode)))
      (set symbol value))
  :type 'string
  :group 'mail)

(defun insert-user-timestamp ()
  "Insert a quick timestamp using the value of `user-initials'."
  (interactive)
  (insert (format "%s (%s): " user-initials
                  (format-time-string "%Y-%m-%d" (current-time)))))

(define-key mode-specific-map [?n] 'insert-user-timestamp)
(define-key mode-specific-map [?o] 'customize-option)
(define-key mode-specific-map [?O] 'customize-group)

(defvar printf-index 0)

(defun insert-counting-printf (arg)
  (interactive "P")
  (if arg
      (setq printf-index 0))
  (insert (format "printf(\"step %d..\\n\");\n"
                  (setq printf-index (1+ printf-index))))
  (forward-line -1)
  (indent-according-to-mode)
  (forward-line))

(define-key mode-specific-map [?p] 'insert-counting-printf)

(define-key mode-specific-map [?q] 'fill-region)
(define-key mode-specific-map [?r] 'replace-regexp)
(define-key mode-specific-map [?s] 'replace-string)

(define-key mode-specific-map [?S] 'org-store-link)
(define-key mode-specific-map [?l] 'org-insert-link)

;;(define-key mode-specific-map [?t ?g] 'gtags-find-with-grep)
;;(define-key mode-specific-map [?t ?r] 'gtags-find-rtag)
;;(define-key mode-specific-map [?t ?s] 'gtags-find-symbol)
;;(define-key mode-specific-map [?t ?t] 'gtags-find-tag)
;;(define-key mode-specific-map [?t ?v] 'gtags-visit-rootdir)
(define-key mode-specific-map [?t ?%] 'tags>-query-replace)
(define-key mode-specific-map [?t ?a] 'tags-apropos)
(define-key mode-specific-map [?t ?e] 'tags-search)
(define-key mode-specific-map [?t ?v] 'visit-tags-table)

(define-key mode-specific-map [?u] 'rename-uniquely)
(define-key mode-specific-map [?v] 'ffap)

(defun view-clipboard ()
  (interactive)
  (delete-other-windows)
  (switch-to-buffer "*Clipboard*")
  (let ((inhibit-read-only t))
    (erase-buffer)
    (clipboard-yank)
    (goto-char (point-min))
    (html-mode)
    (view-mode)))

(define-key mode-specific-map [?V] 'view-clipboard)
(define-key mode-specific-map [?z] 'clean-buffer-list)

(define-key mode-specific-map [?, ?c] 'howm-create)
(define-key mode-specific-map [?, ?g] 'howm-list-grep)

(define-key mode-specific-map [?\[] 'align-regexp)
(define-key mode-specific-map [?=]  'count-matches)
(define-key mode-specific-map [?\;] 'comment-or-uncomment-region)

;;;_ + breadcrumb

(define-key global-map [(alt ?m)] 'bc-set)
(define-key global-map [(alt ?p)] 'bc-previous)
(define-key global-map [(alt ?n)] 'bc-next)
(define-key global-map [(alt ?u)] 'bc-local-previous)
(define-key global-map [(alt ?d)] 'bc-local-next)
(define-key global-map [(alt ?g)] 'bc-goto-current)
(define-key global-map [(alt ?l)] 'bc-list)

;;;_ + footnote

(eval-after-load "footnote"
  '(define-key footnote-mode-map "#" 'redo-footnotes))

;;;_ + isearch-mode

(eval-after-load "isearch"
  '(progn
     (define-key isearch-mode-map [(control ?c)] 'isearch-toggle-case-fold)
     (define-key isearch-mode-map [(control ?t)] 'isearch-toggle-regexp)
     (define-key isearch-mode-map [(control ?^)] 'isearch-edit-string)
     (define-key isearch-mode-map [(control ?i)] 'isearch-complete)))

;;;_ + mail-mode

(eval-after-load "sendmail"
  '(progn
     (define-key mail-mode-map [tab] 'mail-complete)
     (define-key mail-mode-map [(control ?i)] 'mail-complete)))

;;;_* startup

(unless (null window-system)
  (add-hook 'after-init-hook 'emacs-min)

  (add-hook 'after-init-hook 'session-initialize t)
  (add-hook 'after-init-hook 'server-start t)
  (add-hook 'after-init-hook 'edit-server-start t)

  (add-hook 'after-init-hook
            (lambda ()
              (org-agenda-list)
              (org-fit-agenda-window)
              (org-resolve-clocks)) t))

(provide 'dot-emacs-el)

;; .emacs.el ends here
