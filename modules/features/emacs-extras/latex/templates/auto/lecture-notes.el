;; -*- lexical-binding: t; -*-

(TeX-add-style-hook
 "lecture-notes"
 (lambda ()
   (TeX-add-to-alist 'LaTeX-provided-class-options
                     '(("article" "")))
   (TeX-add-to-alist 'LaTeX-provided-package-options
                     '(("mathtools" "") ("physics" "") ("siunitx" "") ("mhchem" "") ("polyglossia" "") ("unicode-math" "")))
   (TeX-run-style-hooks
    "latex2e"
    "article"
    "art10"
    "mathtools"
    "physics"
    "siunitx"
    "mhchem"
    "polyglossia"
    "unicode-math")
   (LaTeX-add-polyglossia-langs
    '("greek" "mainlanguage" "")
    '("english" "otherlanguage" ""))
   (LaTeX-add-fontspec-newfontcmds
    "greekfont"
    "greekfontsf"
    "greekfonttt"))
 :latex)

