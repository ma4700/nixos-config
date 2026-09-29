{ self, inputs, ... }: {
  flake.homeManagerModules.bash = { ... }: {
    programs.bash = {
      enable = true;

      initExtra = ''
        __prompt_git_branch() {
          local branch
          branch=$(git symbolic-ref --short HEAD 2>/dev/null) || return
          printf ' (%s)' "$branch"
        }

        PS1='\[\e[38;2;112;112;112m\]\w\[\e[38;2;180;150;90m\]$(__prompt_git_branch)\[\e[38;2;208;208;208m\] \$\[\e[0m\] '
      '';
    };
  };

}
