;;; zola-mode/zola-mode.el -*- lexical-binding: t; -*-

(require 'web-mode)
(require 'markdown-mode)

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.html\\.tera\\'" . tera-mode))
(add-to-list 'auto-mode-alist '("\\.md\\.tera\\'" . tera-mode))

(defvar tera-font-lock-keywords
  `((,(regexp-opt '("{{" "}}" "{%" "%}" "{#" "#}") 'symbols) . 'font-lock-preprocessor-face)
    (,(regexp-opt '("set" "if" "endif" "for" "endfor" "block" "endblock" "include") 'symbols) . 'font-lock-keyword-face)
    (,(regexp-opt '("lower" "capitalize" "reverse" "trim") 'symbols) . 'font-lock-builtin-face)))

(defun tera-customize-font-lock ()
  "customize font-lock rules for tera templates."
  (font-lock-add-keywords nil tera-font-lock-keywords))

(defun tera-setup-indentation ()
  "custom indentation for the base language."
  (cond
   ((derived-mode-p 'web-mode)
    (setq web-mode-markup-indent-offset 2)
    (setq web-mode-code-indent-offset 2)
    (setq web-mode-css-indent-offset 2))
   ((derived-mode-p 'markdown-mode)
    (setq markdown-indent-on-enter nil))))

;;;###autoload
(define-derived-mode tera-mode fundamental-mode "Tera"
  "major mode for editing tera template files."
  ;; detect base language and switch to it
  (cond
   ((string-match-p "\\.html\\.tera\\'" (buffer-file-name))
    (web-mode)
    (tera-customize-font-lock))
   ((string-match-p "\\.md\\.tera\\'" (buffer-file-name))
    (markdown-mode)
    (tera-customize-font-lock)))
  ;; customize indentation
  (tera-setup-indentation)
  ;; set template delimiters for comments
  (setq comment-start "{#")
  (setq comment-end "#}"))

(provide 'tera-mode)
