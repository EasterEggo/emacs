;init.el -*- lexical-binding: t; -*- 
(setq inhibit-startup-screen t)
(global-display-line-numbers-mode 1)
(menu-bar-mode 0)
(tool-bar-mode 0)
(scroll-bar-mode 0)
(setq make-backup-files nil)
(recentf-mode 1)
(electric-pair-mode 1)
(electric-indent-mode 1)
(which-key-mode 1)
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

(use-package rg)

(use-package doom-themes
  :demand t
  :config
  (setq doom-themes-enable-bold t
        doom-themes-enable-italic t)
  (load-theme 'doom-gruvbox 1)
  (doom-themes-visual-bell-config)
  (doom-themes-neotree-config)
  (doom-themes-org-config))

(use-package doom-modeline
  :ensure t
  :init (doom-modeline-mode 1))

(use-package nerd-icons
  :after doom-modeline
  :ensure t)

(use-package rainbow-delimiters
  :config
  (add-hook 'prog-mode-hook #'rainbow-delimiters-mode))

(use-package evil
  :hook (elpaca-after-init-hook . evil-mode))
(use-package evil-nerd-commenter
  :after evil
  :general(:states 'normal
				   "<SPC>;" 'evilnc-comment-or-uncomment-lines))

(use-package vertico
  :commands (execute-extended-command)
  :general
  (:states 'normal :prefix "<SPC>"
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
  :general
  (:states 'normal :prefix "<SPC>"
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
  (corfu-quit-no-match 'separator)
  (corfu-cycle t)
  (corfu-preselect 'prompt)   
  :init
  (global-corfu-mode))
(use-package cape
  :after corfu
  :init
  ;(add-hook 'completion-at-point-functions #'cape-dabbrev)
  (add-hook 'completion-at-point-functions #'cape-file)
  (add-hook 'completion-at-point-functions #'cape-elisp-block)
  (add-hook 'completion-at-point-functions #'cape-history)
  ;; ...
  )

(use-package orderless
  :after corfu
  :custom
  (completion-styles '(orderless basic))
  (completion-category-defaults nil)
  (completion-category-overrides '((file (styles partial-completion)))))

(use-package savehist
  :after vertico
  :init
  (savehist-mode))

(use-package marginalia
  :after vertico
  :init
  (marginalia-mode))

(use-package dashboard
  :config
  (setq dashboard-display-icons-p t)
  (setq dashboard-icon-type 'nerd-icons)
  (setq dashboard-set-heading-icons t)
  (setq dashboard-set-file-icons t)
  (setq dashboard-projects-backend 'projectile)
  (setq dashboard-items '((recents   . 5)
                          (bookmarks . 5)
                          (projects  . 5)
                          (agenda    . 5)
                          (registers . 5)))
  (add-hook 'elpaca-after-init-hook #'dashboard-insert-startupify-lists)
  (add-hook 'elpaca-after-init-hook #'dashboard-initialize)
  (dashboard-setup-startup-hook))
(setq initial-buffer-choice (lambda () (get-buffer-create dashboard-buffer-name)))
(use-package transient)
(use-package magit
  :after transient
  :general(:states 'normal :prefix "<SPC>g"
				   "g" 'magit
				   "p" 'magit-push
				   "P" 'magit-pull
				   "c" 'magit-commit
				   "i" 'magit-init
				   "s" 'magit-stage
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
  (term-mode . centaur-tabs-local-mode)
  (calendar-mode . centaur-tabs-local-mode)
  (org-agenda-mode . centaur-tabs-local-mode)
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
    (if (and (not test?)                             ;; for check lsp-server-present?
             (not (file-remote-p default-directory)) ;; see lsp-resolve-final-command, it would add extra shell wrapper
             lsp-use-plists
             (not (functionp 'json-rpc-connection))  ;; native json-rpc
             (executable-find "emacs-lsp-booster"))
        (progn
          (when-let ((command-from-exec-path (executable-find (car orig-result))))  ;; resolve command from exec-path (in case not found in $PATH)
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
(use-package lsp-ui :after lsp-mode :commands lsp-ui-mode)

(use-package org-roam
  :ensure t
  :custom
  (org-roam-directory (file-truename "~/Documents/org"))
  :general (:states 'normal :prefix "<SPC>o"
		 "n l" 'org-roam-buffer-toggle
         "f" 'org-roam-node-find
         "ng" 'org-roam-graph
         "i" 'org-roam-node-insert
         "nc" 'org-roam-capture
         "j" 'org-roam-dailies-capture-today)
  :config
  (org-roam-db-autosync-mode)
  ;; If using org-roam-protocol
  (require 'org-roam-protocol))
(use-package org-roam-ui
  :ensure
  (:host github :repo "org-roam/org-roam-ui" :branch "main" :files ("*.el" "out"))
  :after org-roam
  :commands org-roam-ui-open
  :config
  (setq org-roam-ui-sync-theme t
        org-roam-ui-follow t
        org-roam-ui-update-on-save t
        org-roam-ui-open-on-start t))
(setq org-agenda-files '("~/Documents/agenda.org"))
