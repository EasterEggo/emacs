;init.el -*- lexical-binding: t; -*- 
(setq native-comp-deferred-compilation t)
(setq inhibit-startup-screen t)
(menu-bar-mode 0)
(tool-bar-mode 0)
(scroll-bar-mode 0)
(setq make-backup-files nil)
(recentf-mode 1)
(electric-pair-mode 1)
(electric-indent-mode 1)
(which-key-mode 1)
(savehist-mode 1)
(setq pixel-scroll-mode 1)
(setq electric-pair-pairs
      '(
        (?\" . ?\")
        (?\{ . ?\})))
(setq-default tab-width 4)
(setq-default tab-always-indent t)
(defvar elpaca-installer-version 0.11)
(defvar elpaca-directory (expand-file-name "elpaca/" user-emacs-directory))
(defvar elpaca-builds-directory (expand-file-name "builds/" elpaca-directory))
(defvar elpaca-repos-directory (expand-file-name "repos/" elpaca-directory))
(defvar elpaca-order '(elpaca :repo "https://github.com/progfolio/elpaca.git"
							  :ref nil :depth 1 :inherit ignore
                              :files (:defaults "elpaca-test.el" (:exclude "extensions"))
                              :build (:not elpaca--activate-package)))
(let* ((repo  (expand-file-name "elpaca/" elpaca-repos-directory))
       (build (expand-file-name "elpaca/" elpaca-builds-directory))
       (order (cdr elpaca-order))
	   (default-directory repo))
  (add-to-list 'load-path (if (file-exists-p build) build repo))
  (unless (file-exists-p repo)
    (make-directory repo t)
    (when (<= emacs-major-version 28) (require 'subr-x))
    (condition-case-unless-debug err
        (if-let* ((buffer (pop-to-buffer-same-window "*elpaca-bootstrap*"))
                  ((zerop (apply #'call-process `("git" nil ,buffer t "clone"
                                                  ,@(when-let* ((depth (plist-get order :depth)))
                                                      (list (format "--depth=%d" depth) "--no-single-branch"))
                                                  ,(plist-get order :repo) ,repo))))
                  ((zerop (call-process "git" nil buffer t "checkout"
                                        (or (plist-get order :ref) "--"))))
                  (emacs (concat invocation-directory invocation-name))
                  ((zerop (call-process emacs nil buffer nil "-Q" "-L" "." "--batch"
                                        "--eval" "(byte-recompile-directory \".\" 0 'force)")))
                  ((require 'elpaca))
                  ((elpaca-generate-autoloads "elpaca" repo)))
            (progn (message "%s" (buffer-string)) (kill-buffer buffer))
          (error "%s" (with-current-buffer buffer (buffer-string))))
      ((error) (warn "%s" err) (delete-directory repo 'recursive))))
  (unless (require 'elpaca-autoloads nil t)
    (require 'elpaca)
    (elpaca-generate-autoloads "elpaca" repo)
    (let ((load-source-file-function nil)) (load "./elpaca-autoloads"))))
(add-hook 'after-init-hook #'elpaca-process-queues)
(elpaca `(,@elpaca-order))

(elpaca elpaca-use-package
  (elpaca-use-package-mode))
(setq use-package-always-ensure t)

(use-package general
  :ensure (:wait t))

;(use-package modus-themes
;  :config
;  (load-theme 'modus-vivendi t))
(use-package ef-themes
  :init
  (mapc #'disable-theme custom-enabled-themes)
  (load-theme 'ef-dream t))
(use-package doom-modeline
  :init (doom-modeline-mode 1))

(use-package nerd-icons
  :after doom-modeline)

(use-package rainbow-delimiters
  :hook
  (prog-mode . rainbow-delimiters-mode))

(use-package evil
  :config
  (evil-mode 1))

(use-package undo-tree
  :config
  (global-undo-tree-mode 1))
(setq evil-undo-system 'undo-tree)

(use-package evil-nerd-commenter
  :after evil
  :general(:states 'normal
				   "<SPC>;" 'evilnc-comment-or-uncomment-lines))

(use-package vertico
  :general (:states 'normal :prefix "<SPC>"
					"." 'find-file
					"<SPC>" 'execute-extended-command)
  :custom
  (vertico-cycle t)
  :init
  (vertico-mode))

(use-package vertico-directory
  :after vertico
  :ensure nil
  :bind (:map vertico-map
              ("RET" . vertico-directory-enter)
              ("DEL" . vertico-directory-delete-char)
              ("M-DEL" . vertico-directory-delete-word))
  :hook (rfn-eshadow-update-overlay . vertico-directory-tidy))
(use-package consult
  :general (:states 'normal :prefix "<SPC>"
					"sd" 'consult-find
					"sg" 'consult-ripgrep
					"sr" 'consult-recent-file
					"sB" 'consult-bookmark
					"sb" 'consult-buffer
					"st" 'consult-theme
					"sl" 'consult-line))

(use-package projectile
  :after evil
  :config
  (evil-global-set-key 'normal (kbd "<SPC>p") 'projectile-command-map)
  (projectile-mode 1))

(use-package corfu
  :after evil
  :custom
  (corfu-auto t)
  (corfu-cycle t)
  (corfu-preselect 'prompt)   
  :init
  (global-corfu-mode)
  :config
  (setq corfu-auto t
      corfu-auto-delay  0.1
      corfu-auto-prefix 0.1
      corfu-quit-no-match t)
  (add-hook 'corfu-mode-hook
			(lambda ()
              (setq-local completion-styles '(basic)
                          completion-category-overrides nil
                          completion-category-defaults nil))))
(use-package cape
  :after corfu
  :init
  (add-hook 'completion-at-point-functions #'cape-file)
  (add-hook 'completion-at-point-functions #'cape-elisp-block)
  (add-hook 'completion-at-point-functions #'cape-history))

(use-package orderless
  :after corfu
  :custom
  (completion-styles '(orderless basic))
  (completion-category-defaults nil)
  (completion-category-overrides '((file (styles partial-completion)))))

(use-package marginalia
  :after vertico
  :init
  (marginalia-mode))

(use-package dashboard
  :config
  (setq dashboard-startup-banner '("~/emacs/defaultConfig/.emacs.config/dash.txt"))
  (setq dashboard-display-icons-p t)
  (setq dashboard-center-content t)
  (setq dashboard-vertically-center-content t)
  (setq dashboard-icon-type 'nerd-icons)
  (setq dashboard-set-heading-icons t)
  (setq dashboard-startupify-list '(dashboard-insert-banner
									dashboard-insert-navigator
									dashboard-insert-items
									dashboard-insert-init-info
									dashboard-insert-newline
									dashboard-insert-footer))
  (setq dashboard-set-file-icons t)
  (setq dashboard-projects-backend 'projectile)
  (setq dashboard-items '((recents   . 5)
                          (bookmarks . 5)
                          (projects  . 5)
                          (agenda    . 5)))
  (add-hook 'elpaca-after-init-hook #'dashboard-insert-startupify-lists)
  (add-hook 'elpaca-after-init-hook #'dashboard-initialize)
  (dashboard-setup-startup-hook))
  (setq initial-buffer-choice (lambda () (get-buffer-create dashboard-buffer-name)))
(use-package transient)
(use-package magit
  :after transient
  :general(:states 'normal
				   :prefix "<SPC>g"
				   "g" 'magit
				   "p" 'magit-push
				   "P" 'magit-pull
				   "c" 'magit-commit
				   "i" 'magit-init
				   "s" 'magit-stage
				   "u" 'magit-unstage-files
				   "U" 'magit-unstage-all
				   "r" 'magit-remote
				   "o" 'magit-checkout
				   "b" 'magit-branch
				   "C" 'magit-clone))
(use-package diff-hl
  :defer t
  :init
  (global-diff-hl-mode)
  (add-hook 'magit-post-refresh-hook 'diff-hl-magit-post-refresh))
(use-package centaur-tabs
  :hook
  (dashboard-mode . centaur-tabs-local-mode)
  (eat-mode . centaur-tabs-local-mode)
  (term-mode . centaur-tabs-local-mode)
  (calendar-mode . centaur-tabs-local-mode)
  (org-agenda-mode . centaur-tabs-local-mode)
  (elfeed-show-mode . centaur-tabs-local-mode)
  (dired-mode . centaur-tabs-local-mode)
  :config
  (setq centaur-tabs-set-icons t)
  (setq centaur-tabs-icon-type 'nerd-icons)
  (setq centaur-tabs-set-modified-marker t)
  (setq centaur-tabs-height 32)
  (centaur-tabs-mode t))
(defun lsp-booster--advice-json-parse (old-fn &rest args)
  "Try to parse bytecode instead of json."
  (or
   (when (equal (following-char) ?#)
     (let ((bytecode (read (current-buffer))))
       (when (byte-code-function-p bytecode)
         (funcall bytecode))))
   (apply old-fn args)))
(advice-add (if (progn (require 'json)
                       (fboundp 'json-parse-buffer))
                'json-parse-buffer
              'json-read)
            :around
            #'lsp-booster--advice-json-parse)
(defun lsp-booster--advice-final-command (old-fn cmd &optional test?)
  "Prepend emacs-lsp-booster command to lsp CMD."
  (let ((orig-result (funcall old-fn cmd test?)))
    (if (and (not test?)                             
             (not (file-remote-p default-directory))
             lsp-use-plists
             (not (functionp 'json-rpc-connection))
             (executable-find "emacs-lsp-booster"))
        (progn
          (when-let ((command-from-exec-path (executable-find (car orig-result))))
            (setcar orig-result command-from-exec-path))
          (message "Using emacs-lsp-booster for %s!" orig-result)
          (cons "emacs-lsp-booster" orig-result))
      orig-result)))
(advice-add 'lsp-resolve-final-command :around #'lsp-booster--advice-final-command)
(use-package lsp-mode
  :hook
  (c-mode . lsp)
  (lsp-mode . lsp-enable-which-key-integration)
  (lsp-mode . lsp-ui-mode)
  :config
  (evil-define-key 'normal lsp-mode-map (kbd "<SPC>c") lsp-command-map))
(use-package lsp-ui :commands lsp-ui-mode)

(use-package denote
  :general(:states 'normal :prefix "<SPC>o"
				   "a" 'org-agenda
				   "n" 'denote
				   "r" 'denote-rename-file
				   "l" 'denote-link
				   "qc" 'denote-query-contents-link
				   "qf" 'denote-query-filenames-link
				   "b" 'denote-backlinks
				   "d" 'denote-dired
				   "g" 'denote-grep)
  :config
  (setq denote-directory (expand-file-name "~/Documents/denote"))
  (denote-rename-buffer-mode 1))
(use-package denote-journal
  :commands ( denote-journal-new-entry
              denote-journal-new-or-existing-entry
              denote-journal-link-or-create-entry)
  :general (:states 'normal :prefix "<SPC>oj"
					"j" 'denote-journal-new-entry
					"e" 'denote-journal-new-or-existing-entry
					"l" 'denote-journal-link-or-create-entry)
  :config
  (add-hook 'calendar-mode-hook #'denote-journal-calendar-mode)
  (setq denote-journal-directory
        (expand-file-name "journal" denote-directory))
  (setq denote-journal-keyword "journal")
  (setq denote-journal-title-format 'day-date-month-year))
(use-package consult-denote
  :commands (consult-denote-find
			 consult-denote-grep)
  :general
  (:states 'normal :prefix "<SPC>of"
		   "f" 'consult-denote-find
		   "g" 'consult-denote-grep)
  :config
  (consult-denote-mode 1))
(setq org-agenda-files '(
	  "~/Documents/orgAgenda/habits.org"
	  "~/Documents/orgAgenda/personal.org"
	  "~/Documents/orgAgenda/habits.org"))

(add-hook 'prog-mode-hook 'display-line-numbers-mode)
(add-hook 'text-mode-hook 'display-line-numbers-mode)
(add-hook 'org-mode-hook 'org-indent-mode)
(setq org-hide-emphasis-markers t)
(use-package ein
  :commands (ein:run
			 ein:login))
(use-package pdf-tools
  :commands (pdf-loader-install)
  :config
  (pdf-loader-install)
  (add-hook 'pdf-view-mode-hook (lambda() (display-line-numbers-mode -1))))
(add-hook 'dired-mode-hook 'dired-hide-details-mode)
(use-package nerd-icons-dired
  :hook (dired-mode . nerd-icons-dired-mode))

(use-package elfeed
  :general (:states 'normal
					"<SPC>ff" 'elfeed
					"<SPC>fu" 'elfeed-update))
(use-package elfeed-org
  :config
  (elfeed-org)
  (setq rmh-elfeed-org-files (list "~/Documents/feeds.org")))
(use-package eat
  :ensure
  '(:type git
       :host codeberg
       :repo "akib/emacs-eat"
       :files ("*.el" ("term" "term/*.el") "*.texi"
               "*.ti" ("terminfo/e" "terminfo/e/*")
               ("terminfo/65" "terminfo/65/*")
               ("integration" "integration/*")
               (:exclude ".dir-locals.el" "*-tests.el")))

  :general (:states 'normal
					"<SPC>t" 'eat-other-window)
  :config
  (add-hook 'eshell-load-hook 'eat-eshell-mode)
  (add-hook 'eshell-load-hook 'eat-eshell-visual-command-mode))
