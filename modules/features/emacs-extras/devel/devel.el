;; -*- lexical-binding: t; -*-

;; Language servers via the built-in client
(use-package eglot
  :hook ((python-mode python-ts-mode
          c-mode c-ts-mode
          c++-mode c++-ts-mode) . eglot-ensure)
  :bind (:map eglot-mode-map
              ("C-c r" . eglot-rename)
              ("C-c a" . eglot-code-actions))
  :config
  (setq eglot-autoshutdown t))

;; Tree-sitter
(use-package treesit-auto
  :ensure t
  :custom
  (treesit-auto-install 'prompt)
  :config
  (global-treesit-auto-mode))

;; In-buffer completion popup
(use-package corfu
  :ensure t
  :custom
  (corfu-auto t)
  (corfu-auto-delay 0.2)
  (corfu-auto-prefix 2)
  :init
  (global-corfu-mode))

(use-package cape
  :ensure t
  :init
  (add-to-list 'completion-at-point-functions #'cape-dabbrev)
  (add-to-list 'completion-at-point-functions #'cape-file))

;; Diagnostics (flymake itself is built in, this just turns it on everywhere)
(use-package flymake
  :hook (prog-mode . flymake-mode))

;; Debugging (DAP client; Python needs debugpy, C++ needs gdb/lldb-dap, added per-language)
(use-package dape
  :ensure t)

;; Per-project environments, activates each project's .envrc automatically
(use-package envrc
  :ensure t
  :init
  (envrc-global-mode))
