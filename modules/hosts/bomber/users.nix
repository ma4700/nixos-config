{ self, inputs, ... }: {
  flake.nixosModules.bomberUsers = { ... }: {
    users.users.root.hashedPasswordFile = "/persist/passwords/root";
    # ------ alice ----------------------
    users.users.alice = {
      isNormalUser = true;
      description = "alice";
      extraGroups = [ "networkmanager" "wheel" "dialout" ];
      uid = 1000;
      hashedPasswordFile = "/persist/passwords/alice";
    };

    environment.persistence."/persist".users.alice.directories = [
      "dots"
      "Documents"
      ".config/emacs/var" # no-littering
      ".config/noctalia"
      ".cache/noctalia"
      ".config/mozilla"
      ".local/share/direnv" # direnv's allow list
    ];

    home-manager.users.alice = {
      imports = [
        self.homeManagerModules.emacs
        self.homeManagerModules.bash
        self.homeManagerModules.git
        self.homeManagerModules.hyprland
        self.homeManagerModules.niri
      ] ++ (with self.homeManagerModules.emacs-extras; [
        latex
        devel
      ]);


      custom.git = {
        name = "Alex";
        email = "283427948+ma4700@users.noreply.github.com";
      };

      home.file.".hushlogin".text = "";
      home.stateVersion = "26.05";
    };

    # ------ bob ----------------------
    users.users.bob = {
      isNormalUser = true;
      description = "bob";
      extraGroups = [ "networkmanager" "wheel" "dialout" ];
      uid = 1001;
      hashedPasswordFile = "/persist/passwords/bob";
    };

    environment.persistence."/persist".users.bob.directories = [
      "dots"
      "Documents"
      ".config/emacs/var" # no-littering
      ".config/mozilla"
    ];

    home-manager.users.bob = {
      imports = [
        self.homeManagerModules.emacs
        self.homeManagerModules.emacs-extras.latex
        self.homeManagerModules.bash
        self.homeManagerModules.git
        self.homeManagerModules.hyprland
      ];


      custom.git = {
        name = "Alex";
        email = "283427948+ma4700@users.noreply.github.com";
      };

      home.file.".hushlogin".text = "";
      home.stateVersion = "26.05";
    };
  };
}
