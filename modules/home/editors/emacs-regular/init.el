;;; init.el --- Regular Emacs profile managed by Nix -*- lexical-binding: t; -*-

(require 'cl-lib)
(require 'seq)
(require 'use-package)

(setq use-package-always-ensure nil
      use-package-expand-minimally t
      read-process-output-max (* 1024 1024)
      ring-bell-function 'ignore
      sentence-end-double-space nil
      confirm-kill-emacs 'y-or-n-p)

(defconst regular-emacs/profile-name "regular")
(defconst regular-emacs/cache-dir (expand-file-name "var/" user-emacs-directory))
(defconst regular-emacs/doom-dir (expand-file-name "~/.doom.d/"))
(defconst regular-emacs/treesit-grammar-dir "@treesitGrammars@")

(dolist (dir (list regular-emacs/cache-dir
                   (expand-file-name "auto-save/" regular-emacs/cache-dir)
                   (expand-file-name "backups/" regular-emacs/cache-dir)))
  (make-directory dir t))

(setq custom-file (expand-file-name "custom.el" user-emacs-directory)
      auto-save-list-file-prefix (expand-file-name "auto-save/sessions-" regular-emacs/cache-dir)
      backup-directory-alist `(("." . ,(expand-file-name "backups/" regular-emacs/cache-dir)))
      create-lockfiles nil)

(when (file-exists-p custom-file)
  (load custom-file t t))

(let ((secrets-file (expand-file-name "secrets.el" regular-emacs/doom-dir)))
  (when (file-exists-p secrets-file)
    (load secrets-file t t)))

(defconst regular-emacs/system-type
  (if (file-exists-p (expand-file-name "~/.work-system")) 'work 'personal))

(defun regular-emacs/system-case (work-value personal-value)
  "Return WORK-VALUE on work systems, otherwise PERSONAL-VALUE."
  (if (eq regular-emacs/system-type 'work) work-value personal-value))

(defvar regular-emacs/org-directory-personal
  (expand-file-name "~/Library/Mobile Documents/com~apple~CloudDocs/org"))
(defvar regular-emacs/org-directory-work (expand-file-name "~/tasks/work"))

(defun regular-emacs/org-file (dir name)
  "Return NAME inside DIR without checking that it exists."
  (expand-file-name name (file-name-as-directory dir)))

(defun regular-emacs/org-files-in (dir)
  "Return Org files directly inside DIR, or nil if DIR is absent."
  (when (file-directory-p dir)
    (directory-files dir t "\\.org\\'" t)))

(defun regular-emacs/open-init-file ()
  "Open this profile's init.el."
  (interactive)
  (find-file (expand-file-name "init.el" user-emacs-directory)))

(defun regular-emacs/open-doom-config ()
  "Open the still-default Doom config.el."
  (interactive)
  (find-file (expand-file-name "config.el" regular-emacs/doom-dir)))

(setq-default indent-tabs-mode nil
              tab-width 2
              fill-column 100)

(pixel-scroll-precision-mode 1)
(global-auto-revert-mode 1)
(savehist-mode 1)
(recentf-mode 1)
(electric-pair-mode 1)
(delete-selection-mode 1)
(repeat-mode 1)

(add-hook 'prog-mode-hook #'display-line-numbers-mode)
(add-hook 'conf-mode-hook #'display-line-numbers-mode)
(add-hook 'text-mode-hook #'visual-line-mode)

(when (display-graphic-p)
  (set-face-attribute 'default nil :family "FiraCode Nerd Font" :height 120 :weight 'semi-light)
  (set-face-attribute 'fixed-pitch nil :family "FiraCode Nerd Font" :height 120 :weight 'semi-light)
  (set-face-attribute 'variable-pitch nil :family "Fira Sans" :height 130))

(when (eq system-type 'darwin)
  (setq mac-command-modifier 'meta
        mac-option-modifier 'super
        ns-use-proxy-icon nil))

(when (fboundp 'keymap-global-set)
  (keymap-global-set "C-c e i" #'regular-emacs/open-init-file)
  (keymap-global-set "C-c e d" #'regular-emacs/open-doom-config))

(require 'server)
(setq server-name regular-emacs/profile-name)
(unless (or (daemonp) (server-running-p))
  (server-start))

(use-package doom-themes
  :config
  (setq doom-themes-enable-bold t
        doom-themes-enable-italic t)
  (load-theme 'doom-one t)
  (when (fboundp 'doom-themes-visual-bell-config)
    (doom-themes-visual-bell-config))
  (when (fboundp 'doom-themes-org-config)
    (doom-themes-org-config)))

(use-package doom-modeline
  :custom
  (doom-modeline-height 28)
  (doom-modeline-buffer-file-name-style 'truncate-upto-project)
  :config
  (doom-modeline-mode 1))

(use-package which-key
  :custom
  (which-key-idle-delay 0.4)
  :config
  (which-key-mode 1))

(use-package vertico
  :config
  (vertico-mode 1))

(use-package orderless
  :custom
  (completion-styles '(orderless basic))
  (completion-category-defaults nil)
  (completion-category-overrides '((file (styles partial-completion)))))

(use-package marginalia
  :config
  (marginalia-mode 1))

(use-package consult
  :bind (("C-s" . consult-line)
         ("C-x b" . consult-buffer)
         ("C-c h" . consult-history)
         ("C-c m" . consult-mode-command)
         ("C-c k" . consult-ripgrep)))

(use-package corfu
  :custom
  (corfu-auto t)
  (corfu-cycle t)
  (corfu-preselect 'prompt)
  (tab-always-indent 'complete)
  :config
  (global-corfu-mode 1))

(use-package nerd-icons-corfu
  :after corfu
  :config
  (add-to-list 'corfu-margin-formatters #'nerd-icons-corfu-formatter))

(setq evil-want-integration t
      evil-want-keybinding nil
      evil-want-C-u-scroll t
      evil-respect-visual-line-mode t
      evil-undo-system 'undo-redo)

(use-package evil
  :init
  (setq evil-want-fine-undo t)
  :config
  (evil-mode 1)
  (evil-define-key '(normal visual) 'global (kbd "go") #'xref-find-definitions-other-window)
  (evil-define-key '(normal visual) 'global (kbd "gO") #'xref-find-references))

(use-package evil-collection
  :after evil
  :config
  (evil-collection-init))

(use-package key-chord
  :after evil
  :config
  (key-chord-mode 1)
  (key-chord-define-global "jf" #'evil-normal-state))

(use-package smartparens
  :hook ((prog-mode text-mode markdown-mode) . smartparens-mode)
  :config
  (require 'smartparens-config))

(use-package yasnippet
  :config
  (let ((doom-snippets (expand-file-name "snippets" regular-emacs/doom-dir)))
    (when (file-directory-p doom-snippets)
      (add-to-list 'yas-snippet-dirs doom-snippets t)))
  (yas-global-mode 1))

(use-package projectile
  :bind-keymap
  ("C-c p" . projectile-command-map)
  :custom
  (projectile-completion-system 'default)
  (projectile-enable-caching t)
  :config
  (projectile-mode 1))

(use-package magit
  :commands (magit-status magit-dispatch)
  :bind (("C-x g" . magit-status)))

(use-package direnv
  :config
  (direnv-mode 1))

(defvar treesit-extra-load-path nil)
(when (file-directory-p regular-emacs/treesit-grammar-dir)
  (add-to-list 'treesit-extra-load-path regular-emacs/treesit-grammar-dir))
(setq treesit-font-lock-level 4)

(use-package treesit-auto
  :custom
  (treesit-auto-install nil)
  :config
  (global-treesit-auto-mode 1))

(defun regular-emacs/lsp-deferred-if-local ()
  "Start LSP for local buffers only."
  (unless (file-remote-p default-directory)
    (lsp-deferred)))

(defun regular-emacs/lsp-completion-setup ()
  "Let Corfu use flex completion for LSP candidates."
  (setf (alist-get 'styles (alist-get 'lsp-capf completion-category-defaults)) '(flex)))

(use-package lsp-mode
  :commands (lsp lsp-deferred)
  :init
  (dolist (hook '(bash-ts-mode-hook
                  c-mode-hook
                  c++-mode-hook
                  c-ts-mode-hook
                  c++-ts-mode-hook
                  js-mode-hook
                  js-ts-mode-hook
                  hcl-mode-hook
                  json-mode-hook
                  json-ts-mode-hook
                  nix-mode-hook
                  python-mode-hook
                  python-ts-mode-hook
                  rust-mode-hook
                  rust-ts-mode-hook
                  rustic-mode-hook
                  sh-mode-hook
                  tsx-ts-mode-hook
                  tuareg-mode-hook
                  typescript-mode-hook
                  terraform-mode-hook
                  typescript-ts-mode-hook
                  yaml-mode-hook
                  yaml-ts-mode-hook))
    (add-hook hook #'regular-emacs/lsp-deferred-if-local))
  :hook
  (lsp-completion-mode . regular-emacs/lsp-completion-setup)
  :custom
  (lsp-keymap-prefix "C-c l")
  (lsp-completion-provider :none)
  (lsp-headerline-breadcrumb-enable t)
  (lsp-enable-symbol-highlighting t))

(use-package lsp-ui
  :after lsp-mode
  :custom
  (lsp-ui-doc-show-with-mouse t)
  (lsp-ui-peek-enable t)
  (lsp-ui-sideline-show-code-actions t))

(setq sh-basic-offset 2)
(add-hook 'sh-mode-hook
          (lambda ()
            (setq-local evil-shift-width sh-basic-offset)))

(defun regular-emacs/preferred-mode (preferred fallback)
  "Use PREFERRED mode when available, otherwise FALLBACK."
  (if (fboundp preferred) preferred fallback))

(use-package nix-mode
  :mode ("\\.nix\\'" . nix-mode))

(use-package markdown-mode
  :mode (("README\\.md\\'" . gfm-mode)
         ("\\.md\\'" . markdown-mode)
         ("\\.markdown\\'" . markdown-mode))
  :hook (markdown-mode . (lambda () (setq-local fill-column 110))))

(use-package yaml-mode
  :mode ("\\.ya?ml\\'" . yaml-mode))

(use-package json-mode
  :mode ("\\.json\\'" . json-mode))

(use-package typescript-mode
  :defer t)
(dolist (entry `(("\\.ts\\'" . ,(regular-emacs/preferred-mode 'typescript-ts-mode 'typescript-mode))
                 ("\\.tsx\\'" . ,(regular-emacs/preferred-mode 'tsx-ts-mode 'typescript-mode))))
  (add-to-list 'auto-mode-alist entry))

(use-package web-mode
  :mode (("\\.html?\\'" . web-mode)
         ("\\.tera\\'" . web-mode)
         ("\\.j2\\'" . web-mode)
         ("\\.jinja2?\\'" . web-mode)
         ("\\.svelte\\'" . web-mode)
         ("\\.vue\\'" . web-mode)))

(when (fboundp 'json-ts-mode)
  (add-to-list 'auto-mode-alist '("\\.jsonc\\'" . json-ts-mode)))

(use-package rustic
  :mode ("\\.rs\\'" . rustic-mode)
  :custom
  (rustic-lsp-client 'lsp-mode)
  (rustic-format-on-save nil))

(use-package rust-mode
  :defer t)

(use-package tuareg
  :mode (("\\.ml\\'" . tuareg-mode)
         ("\\.mli\\'" . tuareg-mode)))

(use-package dune
  :after tuareg)

(use-package racket-mode
  :mode ("\\.rkt[dl]?\\'" . racket-mode))

(use-package jq-mode
  :mode ("\\.jq\\'" . jq-mode))

(use-package jsonnet-mode
  :mode (("\\.jsonnet\\'" . jsonnet-mode)
         ("\\.libsonnet\\'" . jsonnet-mode)))

(use-package hcl-mode
  :mode ("\\.hcl\\'" . hcl-mode))

(use-package terraform-mode
  :mode (("\\.tf\\'" . terraform-mode)
         ("\\.tfvars\\'" . terraform-mode))
  :custom
  (terraform-format-on-save nil)
  (terraform-indent-level 2))

(use-package graphviz-dot-mode
  :mode (("\\.dot\\'" . graphviz-dot-mode)
         ("\\.gv\\'" . graphviz-dot-mode))
  :custom
  (graphviz-dot-indent-width 4)
  (graphviz-dot-preview-extension "svg"))

(use-package mermaid-mode
  :mode (("\\.mmd\\'" . mermaid-mode)
         ("\\.mermaid\\'" . mermaid-mode)))

(use-package nushell-mode
  :mode ("\\.nu\\'" . nushell-mode))

(use-package llvm-mode
  :mode (("\\.ll\\'" . llvm-mode)
         ("\\.mir\\'" . llvm-mode))
  :custom
  (llvm-mode-indent-offset 2)
  (llvm-mode-label-offset 2))

(use-package ron-mode
  :mode ("\\.ron\\'" . ron-mode))

(use-package apheleia
  :commands (apheleia-format-buffer apheleia-mode)
  :bind (("C-c f" . apheleia-format-buffer)))

(setq epg-pinentry-mode 'loopback
      epa-file-select-keys nil
      epa-file-encrypt-to nil
      epa-file-cache-passphrase-for-symmetric-encryption t)

(use-package org
  :ensure nil
  :mode ("\\.org\\'" . org-mode)
  :custom
  (org-directory (regular-emacs/system-case regular-emacs/org-directory-work
                                            regular-emacs/org-directory-personal))
  (org-extend-today-until 3)
  (org-hide-emphasis-markers t)
  (org-startup-indented t)
  (org-pretty-entities t)
  (org-agenda-skip-scheduled-if-done t)
  (org-tags-column -100)
  (org-log-done 'time)
  (org-ellipsis " ▾ ")
  (org-todo-keywords '((sequence "TODO(t)" "INPROGRESS(i)" "WAITING(w)" "|" "DONE(d)" "CANCELLED(c)")
                       (sequence "QUESTION(q)" "|" "YES(y!)" "NO(n!)" "COMMENT(c@)")))
  (org-todo-keyword-faces '(("TODO" . org-todo)
                            ("WAITING" . warning)
                            ("INPROGRESS" . success)
                            ("DONE" . org-done)
                            ("CANCELLED" . error)
                            ("QUESTION" . font-lock-keyword-face)
                            ("YES" . success)
                            ("NO" . error)
                            ("COMMENT" . font-lock-comment-face)))
  :config
  (setq org-agenda-files (append (regular-emacs/org-files-in regular-emacs/org-directory-personal)
                                 (regular-emacs/org-files-in regular-emacs/org-directory-work)))
  (let* ((work-todo (regular-emacs/org-file regular-emacs/org-directory-work "inbox.org"))
         (work-notes (regular-emacs/org-file regular-emacs/org-directory-work "notes.org"))
         (personal-file (regular-emacs/org-file regular-emacs/org-directory-personal "personal.org"))
         (capture-todo (regular-emacs/system-case work-todo personal-file))
         (capture-notes (regular-emacs/system-case work-notes personal-file)))
    (setq org-capture-templates
          `(("t" "Todo" entry (file+headline ,capture-todo "Inbox")
             "* TODO %?\n%U\n%a" :prepend t)
            ("n" "Note" entry (file+headline ,capture-notes "Inbox")
             "* %u %?\n%i\n%a" :prepend t)
            ("T" "Personal todo" entry (file+headline ,personal-file "Inbox")
             "* TODO %?\n%i\n%a" :prepend t))))
  (org-babel-do-load-languages
   'org-babel-load-languages
   '((emacs-lisp . t)
     (shell . t))))

(use-package org-modern
  :after org
  :hook (org-mode . org-modern-mode))

(use-package org-journal
  :after org
  :custom
  (org-journal-encrypt-journal t)
  (org-journal-dir (expand-file-name "~/Documents/journal/"))
  (org-journal-file-type 'daily))

(use-package org-roam
  :after org
  :custom
  (org-roam-directory (expand-file-name "roam" org-directory))
  :config
  (when (file-directory-p org-roam-directory)
    (org-roam-db-autosync-mode 1)))

(use-package gptel
  :commands (gptel gptel-send))

(provide 'init)
;;; init.el ends here
