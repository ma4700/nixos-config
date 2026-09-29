```text
flake.nix                    inputs, then import-tree ./modules (that's all)
modules/
├── parts.nix                flake-parts systems
├── theme.nix                one palette -> flake.theme / flake.themeNoHash
├── base/                    plumbing every host needs, nothing opt-in
│   ├── nixpkgs.nix          perSystem pkgs, overlays, unfree allow-list
│   ├── home-manager.nix     home-manager as a NixOS module + flake.homeManagerModules
│   ├── impermanence.nix     root rollback and the /persist mechanism
│   ├── audio.nix            PipeWire + WirePlumber
│   └── bluetooth.nix        BlueZ + the flake.bluetoothEnabled flag
├── extra/                   small fixes with no real config surface
│   ├── keyd.nix             caps lock as control
│   ├── nmtui-theme.nix      nmtui colours from the palette
│   └── grub-theme.nix       flat GRUB theme from the palette
├── features/                things a host or a user opts into
│   ├── bash.nix             themed prompt, enables home-manager's bash
│   ├── git.nix              per-user git identity
│   ├── kitty.nix            kitty, wrapped, palette colours
│   ├── niri.nix             niri with its settings baked in (myNiri)
│   ├── noctalia/            noctalia shell + its exported settings
│   ├── hyprland.nix         Hyprland + hypridle
│   ├── quickshell/          hand-written QML shell + qs-bt-agent.c
│   ├── wallpaper/
│   ├── emacs/               Emacs build + init.el
│   └── emacs-extras/
│       ├── latex/           AUCTeX, CDLaTeX, snippets, templates, zathurarc
│       └── devel/           eglot, tree-sitter, corfu, dape, direnv; Python + C/C++
└── hosts/
    └── bomber/              configuration, hardware, disko, users, install script
```
