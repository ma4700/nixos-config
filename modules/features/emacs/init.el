;; -*- lexical-binding: t; -*-

(use-package emacs
  :init
  (setq inhibit-startup-message t
        make-backup-files nil
        ring-bell-function 'ignore
        use-short-answers t
        display-line-numbers-type 'relative

        ;; sane editing defaults
        indent-tabs-mode nil
        tab-width 4
        require-final-newline t
        sentence-end-double-space nil

        ;; stop scattering clutter files everywhere
        auto-save-default nil
        create-lockfiles nil

        ;; ui noise reduction
        use-dialog-box nil
        frame-resize-pixelwise t)

  ;; --- THEME ---
  (add-to-list 'default-frame-alist `(background-color . ,(my/c 'base00)))
  (add-to-list 'default-frame-alist `(foreground-color . ,(my/c 'base06)))
  (add-to-list 'default-frame-alist `(cursor-color     . ,(my/c 'base06)))

  (menu-bar-mode -1)
  (tool-bar-mode -1)
  (scroll-bar-mode -1)
  (global-display-line-numbers-mode t)
  (global-font-lock-mode 1)

  (custom-set-faces
   `(default              ((t (:background ,(my/c 'base00) :foreground ,(my/c 'base06)))))
   `(cursor               ((t (:background ,(my/c 'base06)))))
   `(fringe               ((t (:background ,(my/c 'base00)))))
   `(region               ((t (:background ,(my/c 'base02)))))
   `(mode-line            ((t (:background ,(my/c 'base01) :foreground ,(my/c 'base06)
                                :box (:line-width (1 . 4) :color ,(my/c 'base01))))))
   `(mode-line-inactive   ((t (:background ,(my/c 'base00) :foreground ,(my/c 'base03)
                                :box (:line-width (1 . 4) :color ,(my/c 'base00))))))
   `(line-number          ((t (:foreground ,(my/c 'base03) :background ,(my/c 'base00)))))
   `(line-number-current-line ((t (:foreground ,(my/c 'base06) :background ,(my/c 'base00)))))

   ;; syntax highlighting grayscale
   `(font-lock-comment-face        ((t (:foreground ,(my/c 'base04) :italic t))))
   `(font-lock-string-face         ((t (:foreground ,(my/c 'base05)))))
   `(font-lock-keyword-face        ((t (:foreground ,(my/c 'base06) :bold t))))
   `(font-lock-function-name-face  ((t (:foreground ,(my/c 'base07) :bold t))))
   `(font-lock-variable-name-face  ((t (:foreground ,(my/c 'base06)))))
   `(font-lock-type-face           ((t (:foreground ,(my/c 'base06)))))
   `(font-lock-constant-face       ((t (:foreground ,(my/c 'base06)))))))

(defun my/position-bar ()
  "Thin bar for the mode line showing which part of the buffer is visible."
  (let* ((width 12)
         (win (or (get-buffer-window (current-buffer)) (selected-window)))
         (total (max 1 (- (point-max) (point-min))))
         (start (/ (float (- (window-start win) (point-min))) total))
         (end (/ (float (- (window-end win t) (point-min))) total))
         (from (min (1- width) (floor (* start width))))
         (to (max (1+ from) (min width (ceiling (* end width)))))
         (bar ""))
    (dotimes (i width)
      (setq bar (concat bar
                        (if (and (>= i from) (< i to))
                            (propertize "━" 'face `(:foreground ,(my/c 'base06)))
                          (propertize "─" 'face `(:foreground ,(my/c 'base03)))))))
    bar))

;; --- MODE LINE ---
(defun my/ml-face (str &rest props)
  "Propertize STR with PROPS in the selected window only, so inactive ones stay dim."
  (if (mode-line-window-selected-p) (apply #'propertize str props) str))

(defun my/ml-left ()
  (concat
   " "
   (cond (buffer-read-only (my/ml-face "■" 'face `(:foreground ,(my/c 'base05))))
         ((buffer-modified-p) (my/ml-face "●" 'face `(:foreground ,(my/c 'base09))))
         (t (my/ml-face "○" 'face `(:foreground ,(my/c 'base03)))))
   "  "
   (my/ml-face (buffer-name) 'face `(:foreground ,(my/c 'base07) :weight bold))
   (when vc-mode
     (concat "  "
             (my/ml-face (replace-regexp-in-string "\\`[[:space:]]*[[:alpha:]]+[-:@]" "" vc-mode)
                         'face `(:foreground ,(my/c 'base09)))))))

(defun my/ml-right ()
  (concat
   (my/ml-face (format-mode-line mode-name) 'face `(:foreground ,(my/c 'base05)))
   "   "
   (my/ml-face (format-mode-line "%l:%c") 'face `(:foreground ,(my/c 'base05)))
   "   "
   (my/position-bar)
   " "
   (format "%3s" (format-mode-line "%p"))
   " "))

(setq-default
 mode-line-format
 '((:eval (my/ml-left))
   (:eval (let ((right (my/ml-right)))
            (concat (propertize " " 'display
                                `((space :align-to (- right ,(string-width right)))))
                    right)))))

(use-package no-littering
  :ensure t)

(defun my/save-and-close-client-frame ()
  "Prompt to save any modified buffer before closing frame"
  (interactive)
  (save-some-buffers)
  (delete-frame))

(global-set-key (kbd "C-x C-c") #'my/save-and-close-client-frame)

;;(use-package evil
;;  :ensure t
;;  :init
;;  (setq evil-want-integration t
;;        evil-want-keybinding nil)   ; let evil-collection manage keybindings instead
;;  :config
;;  (evil-mode 1))
;;
;;(use-package evil-collection
;;  :ensure t
;;  :after evil
;;  :config
;;  (evil-collection-init))          ; consistent evil bindings in dired, magit, etc.

(use-package avy
  :ensure t
  :bind ("M-j" . avy-goto-char-in-line))

(use-package vertico
  :ensure t
  :init (vertico-mode))

(use-package orderless :ensure t
  :custom (completion-styles '(orderless basic)))

(use-package marginalia
  :ensure t
  :init (marginalia-mode))

(use-package which-key
  :ensure t
  :init (which-key-mode))

(use-package magit
  :ensure t)

;; Syntax highlighting for different files
(use-package nix-mode
  :ensure t
  :mode "\\.nix\\'")
(use-package qml-mode
  :ensure t
  :mode "\\.qml\\'")
