;; -*- lexical-binding: t; -*-
(setq initial-scratch-message ";;
;; ░█░█░█▀▀░█░░░█▀▀░█▀█░█▄█░█▀▀░░░▀█▀░█▀█░░░█▀▀░█▄█░█▀█░█▀▀░█▀▀
;; ░█▄█░█▀▀░█░░░█░░░█░█░█░█░█▀▀░░░░█░░█░█░░░█▀▀░█░█░█▀█░█░░░▀▀█
;; ░▀░▀░▀▀▀░▀▀▀░▀▀▀░▀▀▀░▀░▀░▀▀▀░░░░▀░░▀▀▀░░░▀▀▀░▀░▀░▀░▀░▀▀▀░▀▀▀
;;
")

(setq display-line-numbers-type 'relative)
(add-hook 'prog-mode-hook 'display-line-numbers-mode)
(add-hook 'dired-mode-hook 'dired-hide-details-mode)
(add-hook 'text-mode-hook 'display-line-numbers-mode)
(add-hook 'org-mode-hook 'org-indent-mode)
(setq native-comp-deferred-compilation t)
(setq org-hide-emphasis-markers t)
(setq inhibit-startup-screen t)
(menu-bar-mode 0)
(tool-bar-mode 0)
(scroll-bar-mode 0)
(setq make-backup-files nil)
(global-hl-line-mode 1)
(recentf-mode 1)
(electric-pair-mode 1)
(electric-indent-mode 1)
(which-key-mode 1)
(savehist-mode 1)
(setq pixel-scroll-mode 1)
(defalias 'yes-or-no-p 'y-or-n-p)
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

(use-package evil
  :after undo-tree
  :config
  (evil-mode 1))

(use-package anzu
:config
(global-anzu-mode 1))

(use-package evil-anzu
:after evil anzu)

(use-package undo-tree
  :config
  (global-undo-tree-mode 1)
  (setq undo-tree-history-directory-alist '(("." . "~/.emacs.d/undo"))))
(setq evil-undo-system 'undo-tree)

(use-package evil-nerd-commenter
  :after evil
  :general("C-c ;" 'evilnc-comment-or-uncomment-lines))

(use-package doom-themes
  :config
  (load-theme 'doom-one t))

(use-package doom-modeline
  :init (doom-modeline-mode 1)
  :config
  (setq inhibit-compacting-font-caches t)
  (setq doom-modeline-height 30)
  (setq doom-modeline-project-detection 'auto))

(use-package nerd-icons)

(use-package nerd-icons-dired
  :after nerd-icons
  :hook (dired-mode . nerd-icons-dired-mode))

(use-package nerd-icons-corfu
  :after corfu nerd-icons
  :config
  (add-to-list 'corfu-margin-formatters #'nerd-icons-corfu-formatter))

(use-package rainbow-delimiters
  :hook
  (prog-mode . rainbow-delimiters-mode))

(use-package projectile
   :after evil
   :config
   (evil-global-set-key 'normal (kbd "<SPC>p") 'projectile-command-map)
   (projectile-mode 1))

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
      corfu-quit-no-match t))

(use-package cape
  :after yasnippet-capf orderless
  :init
  (add-hook 'completion-at-point-functions #'cape-file)
  (add-hook 'completion-at-point-functions #'cape-elisp-block)
  (add-hook 'completion-at-point-functions #'cape-history)
  :config
  (with-eval-after-load 'eglot
	(setq completion-category-defaults nil))
  (defun sb/eglot-capf-with-yasnippet ()
	(setq-local completion-at-point-functions
				(list
				 (cape-capf-super
				  #'eglot-completion-at-point
				  #'yasnippet-capf))))
  (add-hook 'eglot-managed-mode-hook #'sb/eglot-capf-with-yasnippet)
  (advice-add 'eglot-completion-at-point :around #'cape-wrap-buster))

(use-package eldoc-box
  :config
  (if (display-graphic-p) (add-hook 'eglot-managed-mode-hook #'eldoc-box-mouse-mode)))

(use-package orderless
  :after corfu
  :custom
  (completion-styles '(orderless basic))
  (completion-category-defaults nil)
  (completion-category-overrides '((file (styles partial-completion)))))

(use-package yasnippet
  :config
  (yas-reload-all)
  :hook
  (prog-mode-hook . yas-minor-mode)
  (org-mode . yas-minor-mode))

(use-package yasnippet-snippets)

(use-package yasnippet-capf
  :init
  (defun my/yasnippet-capf-h ()
    (add-to-list 'completion-at-point-functions #'yasnippet-capf))
  :hook
  (prog-mode . my/yasnippet-capf-h)
  (org-mode . my/yasnippet-capf-h)
  (eglot-managed-mode . my/yasnippet-capf-h))

(use-package marginalia
  :after vertico
  :init
  (marginalia-mode))

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

(use-package toc-org
  :hook (org-mode . toc-org-mode))

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
  (setq denote-directory (expand-file-name "/mnt/hdd/denote/"))
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

(use-package ein
  :commands (ein:run
			 ein:login))

(use-package eat
  :commands
  (eat)
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

(use-package flycheck
  :ensure t
  :config
  (add-hook 'after-init-hook #'global-flycheck-mode))

(use-package dape
  :preface
  ;; By default dape shares the same keybinding prefix as `gud'
  ;; If you do not want to use any prefix, set it to nil.
  ;; (setq dape-key-prefix "\C-x\C-a")

  :hook
  (kill-emacs . dape-breakpoint-save)
  (after-init . dape-breakpoint-load)

  :custom
  (dape-breakpoint-global-mode +1)
  (dape-buffer-window-arrangement 'right)
  (dape-cwd-function #'projectile-project-root)

  :config
  (add-hook 'dape-display-source-hook #'pulse-momentary-highlight-one-line)
  (add-hook 'dape-start-hook (lambda () (save-some-buffers t t)))
  (add-hook 'dape-compile-hook #'kill-buffer))

(use-package neotree
  :config
  (setq neo-theme 'nerd-icons)
  :general
  (:states 'normal :prefix "<SPC>e"
		   "e" 'neotree-toggle
		   "d" 'neotree-dir))
