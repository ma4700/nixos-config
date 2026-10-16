;; -*- lexical-binding: t; -*-

(TeX-add-style-hook
 "short-lab-report"
 (lambda ()
   (TeX-add-to-alist 'LaTeX-provided-class-options
                     '(("article" "11pt" "a4paper")))
   (TeX-add-to-alist 'LaTeX-provided-package-options
                     '(("geometry" "a4paper" "margin=2.5cm" "headheight=14pt") ("mathtools" "") ("physics" "") ("siunitx" "") ("mhchem" "version=4") ("booktabs" "") ("array" "") ("float" "") ("graphicx" "") ("xcolor" "") ("caption" "") ("parskip" "") ("fancyhdr" "") ("polyglossia" "") ("unicode-math" "") ("hyperref" "")))
   (add-to-list 'LaTeX-verbatim-macros-with-braces-local "href")
   (add-to-list 'LaTeX-verbatim-macros-with-braces-local "hyperimage")
   (add-to-list 'LaTeX-verbatim-macros-with-braces-local "hyperbaseurl")
   (add-to-list 'LaTeX-verbatim-macros-with-braces-local "nolinkurl")
   (add-to-list 'LaTeX-verbatim-macros-with-braces-local "url")
   (add-to-list 'LaTeX-verbatim-macros-with-braces-local "path")
   (add-to-list 'LaTeX-verbatim-macros-with-delims-local "path")
   (TeX-run-style-hooks
    "latex2e"
    "article"
    "art11"
    "geometry"
    "mathtools"
    "physics"
    "siunitx"
    "mhchem"
    "booktabs"
    "array"
    "float"
    "graphicx"
    "xcolor"
    "caption"
    "parskip"
    "fancyhdr"
    "polyglossia"
    "unicode-math"
    "hyperref")
   (TeX-add-symbols
    '("labsummaryrows")
    '("labcompare" ["Text"] "Text" "Text" "Text" "Text")
    '("labstep" "Text")
    '("labsummaryrow" 8)
    '("labcompareblock" 7)
    '("labpercent" 1)
    '("labvalue" 2)
    '("labpart" 1)
    '("labstepheading" 1)
    "labcourse"
    "labno"
    "labtitle"
    "labauthors"
    "labid"
    "labbench"
    "labdate"
    "labsummary")
   (LaTeX-add-labels
    "step:1")
   (LaTeX-add-environments
    '("improve"))
   (LaTeX-add-counters
    "labstep")
   (LaTeX-add-polyglossia-langs
    '("greek" "mainlanguage" "")
    '("english" "otherlanguage" ""))
   (LaTeX-add-fontspec-newfontcmds
    "greekfont"))
 :latex)

