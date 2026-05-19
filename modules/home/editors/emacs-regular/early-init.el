;;; early-init.el --- Early startup for the regular Emacs profile -*- lexical-binding: t; -*-

;; Packages are supplied by the Nix-built Emacs wrapper for this profile.
(setq package-enable-at-startup nil)

;; Keep startup quiet and avoid work that will be redone by init.el.
(setq inhibit-startup-screen t
      inhibit-startup-message t
      inhibit-startup-echo-area-message user-login-name
      frame-inhibit-implied-resize t)

;; Defer expensive garbage collection until normal startup has completed.
(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.6)

(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold (* 128 1024 1024)
                  gc-cons-percentage 0.1)))

(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)

(provide 'early-init)
;;; early-init.el ends here
