let
  theme = {
    base00 = "#0d0d0d"; # bg
    base01 = "#1a1a1a";
    base02 = "#2a2a2a"; # selection / active pill
    base03 = "#404040"; # dim / empty
    base04 = "#707070"; # comments, secondary text
    base05 = "#a0a0a0"; # mid fg
    base06 = "#d0d0d0"; # default fg
    base07 = "#eaeaea"; # bright fg
    base08 = "#8a8a8a";
    base09 = "#b4965a"; # amber accent
    base0A = "#404040";
    base0B = "#707070";
    base0C = "#a0a0a0";
    base0D = "#d0d0d0";
    base0E = "#eaeaea";
    base0F = "#b4965a";

    # status colours, outside the monochrome palette
    red = "#d05a5a";    # critical / errors
    green = "#7fb069";  # charging / ok
    yellow = "#d9b84a"; # warning

    # extra terminal colours
    blue = "#6f8db0";
    magenta = "#a07aa6";
    cyan = "#6ba3a3";
    brightRed = "#e07f7f";
    brightGreen = "#9cc987";
    brightBlue = "#8fadd0";
    brightMagenta = "#bd97c3";
    brightCyan = "#8cc0c0";
  };

  stripHash = str:
    if builtins.substring 0 1 str == "#"
    then builtins.substring 1 (builtins.stringLength str - 1) str
    else str;

  themeNoHash = builtins.mapAttrs (_: v: stripHash v) theme;
in {
  flake = {
    inherit theme themeNoHash;
  };
}
