;; -*- lexical-binding: t; -*-

(add-to-list 'auto-mode-alist '("\\.tex\\'" . LaTeX-mode))

;; do not append newline to snippet files!
(add-hook 'snippet-mode-hook (lambda () (setq-local require-final-newline nil)))

(use-package  tex
  :ensure auctex

  :hook ((LaTeX-mode . visual-line-mode)
	 (LaTeX-mode . TeX-fold-mode)
	 (LaTeX-mode . outline-minor-mode)
	 (LaTeX-mode . prettify-symbols-mode)
	 (LaTeX-mode . reftex-mode))
  :custom
  (TeX-auto-save t)
  (TeX-parse-self t)
  (TeX-PDF-mode t)
  (TeX-source-correlate-mode t)
  (TeX-source-correlate-start-server t)
  (reftex-plug-into-AUCTeX t)
  :config
  (add-to-list 'TeX-command-list
	       '("LatexMk-live" "latexmk -pvc -view=none -synctex=1 -xelatex %s" TeX-run-TeX nil t))
  (setq TeX-view-program-selection '((output-pdf "Zathura")))
  (setq TeX-view-program-list '(("Zathura" ("zathura --synctex-forward %n:0:%b -x \"emacsclient +%{line} %{input}\" %o")))))

(use-package cdlatex
  :ensure t
  :hook (LaTeX-mode . turn-on-cdlatex))

(use-package yasnippet
  :ensure t
  :init (yas-global-mode 1)
  :custom (yas-snippet-dirs '("~/.config/emacs/snippets")))



;; cdlatex-mode's own TAB binding shadows yas-expand, so let TAB try a
;; snippet first and fall back to cdlatex's normal jump if none fires
(defun cdlatex-in-yas-field ()
  (when-let* ((_ (overlayp yas--active-field-overlay))
              (end (overlay-end yas--active-field-overlay)))
    (if (>= (point) end)
        (let ((s (thing-at-point 'sexp)))
          (unless (and s (assoc (substring-no-properties s)
                                 cdlatex-command-alist-comb))
            (or (yas-expand) (yas-next-field-or-maybe-expand))
            t))
      (let (cdlatex-tab-hook minp)
        (setq minp (min (save-excursion (cdlatex-tab) (point))
                         (overlay-end yas--active-field-overlay)))
        (goto-char minp) t))))

(defun yas-next-field-or-cdlatex ()
  (interactive)
  (if (or (bound-and-true-p cdlatex-mode)
          (bound-and-true-p org-cdlatex-mode))
      (cdlatex-tab)
    (yas-next-field-or-maybe-expand)))

(with-eval-after-load 'cdlatex
  (add-hook 'cdlatex-tab-hook #'yas-expand)
  (add-hook 'cdlatex-tab-hook #'cdlatex-in-yas-field))

(with-eval-after-load 'yasnippet
  (setq yas-triggers-in-field t)
  (define-key yas-keymap (kbd "<tab>") #'yas-next-field-or-cdlatex)
  (define-key yas-keymap (kbd "TAB") #'yas-next-field-or-cdlatex))
;; -------------------------------------------------


(use-package autoinsert
  :ensure nil
  :hook (LaTeX-mode . auto-insert)
  :custom
  (auto-insert-query nil)
  :config
  (add-to-list 'auto-insert-alist
	       '("\\.tex\\'" . "~/.config/emacs/templates/lecture-notes.tex")))

;; example of a second template, manually inserted through a function
;; (defun my/insert-problem-set-template ()
;;   (interactive)
;;   (insert-file-contents "~/.config/emacs/templates/problem-set.tex"))

(defun my/yas-try-expanding-auto-snippets ()
  (when (bound-and-true-p yas-minor-mode)
    (let ((yas-buffer-local-condition ''(require-snippet-condition . auto )))
      (yas-expand))))
(add-hook 'post-self-insert-hook #'my/yas-try-expanding-auto-snippets)
