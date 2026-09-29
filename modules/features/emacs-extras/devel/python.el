;; -*- lexical-binding: t; -*-

;; basedpyright isn't one of eglot's built-in defaults, so register it
(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs
               '((python-mode python-ts-mode) . ("basedpyright-langserver" "--stdio"))))

;; Format on save with ruff
(use-package ruff-format
  :ensure t
  :hook ((python-mode python-ts-mode) . ruff-format-on-save-mode))

;; dape ships a built-in "debugpy" template; installing debugpy is
;; all that's needed for M-x dape RET debugpy to work
