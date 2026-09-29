;; -*- lexical-binding: t; -*-

;; clangd is one of eglot's built-in defaults for c-mode/c++-mode, so no
;; eglot-server-programs entry is needed here (unlike basedpyright).
;; It needs a compile_commands.json in the project root which PlatformIO
;; generates automatically on build.

(use-package platformio-mode
  :ensure t
  :hook ((c-mode c-ts-mode c++-mode c++-ts-mode) . platformio-conditionally-enable))

;; dape ships built-in "gdb" templates, installing gdb (done in cpp.nix)
;; is enough for M-x dape RET gdb on a plain (non-PlatformIO) C/C++
;; build. PlatformIO's own "pio debug" flow (on-target Arduino
;; debugging, board-dependent) runs through platformio-mode's own
;; commands, not through dape.
