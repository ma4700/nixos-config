{ self, inputs, ... }: {

  # nmtui is built on newt, which can only use the 16 ANSI colour names; the
  # actual shades come from the terminal palette, from theme.nix (black = base00,
  # gray = base04, lightgray = base06, white = base07, brown = base09 amber).
  flake.nixosModules.nmtui-theme = { lib, ... }: {
    environment.sessionVariables.NEWT_COLORS = lib.concatStringsSep " " [
      "root=lightgray,black"
      "roottext=gray,black"
      "border=gray,black"
      "window=lightgray,black"
      "shadow=black,black"
      "title=brown,black"
      "button=black,lightgray"
      "actbutton=white,gray"
      "compactbutton=lightgray,black"
      "checkbox=lightgray,black"
      "actcheckbox=black,lightgray"
      "entry=lightgray,black"
      "disentry=gray,black"
      "label=lightgray,black"
      "listbox=lightgray,black"
      "actlistbox=black,lightgray"
      "sellistbox=white,black"
      "actsellistbox=black,lightgray"
      "textbox=lightgray,black"
      "acttextbox=black,lightgray"
      "helpline=gray,black"
      "emptyscale=lightgray,gray"
      "fullscale=black,lightgray"
    ];
  };

}
