;; -*- lexical-binding: t; -*-
;(setenv "LSP_USE_PLISTS" "true")
;(add-to-list 'initial-frame-alist '(background-color . "#1d1f21"))
;(custom-theme-set-faces
; 'user
; '(variable-pitch ((t (:family "aporetic-sans-normal" :height 130 :weight regular))))
; '(fixed-pitch ((t ( :family "aporetic-serif-mono" :height 130)))))
(setq inhibit-x-resources t) (setq-default inhibit-redisplay t) (add-hook 'window-setup-hook (lambda () (setq-default inhibit-redisplay nil) (redisplay)) 100) 
(setq package-enable-at-startup nil)
