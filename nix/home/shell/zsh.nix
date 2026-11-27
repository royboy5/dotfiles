# Zsh: options, history, plugins and general-purpose aliases/functions.
# Tool-specific aliases, env vars and PATH entries live in each topic's module
# (home.shellAliases / home.sessionVariables / home.sessionPath).
#
# The one config that is declared rather than linked from configs/: plugins
# need store paths, and other modules add aliases, env vars and PATH entries.
# The distro's /usr/bin/zsh stays the login shell and reads the files written here.
{
  config,
  lib,
  pkgs,
  dotfiles,
  ...
}:

{
  programs.zsh = {
    enable = true;

    # Keep everything in ~/.config/zsh (home-manager writes ~/.zshenv to point here).
    dotDir = "${config.xdg.configHome}/zsh";

    # zsh-autocomplete runs compinit itself and must load before it; see initContent.
    enableCompletion = false;

    autosuggestion.enable = true;
    syntaxHighlighting.enable = true; # home-manager loads it last

    history = {
      size = 10000;
      save = 10000;
      path = "${config.xdg.stateHome}/zsh/history";
      extended = true;
      expireDuplicatesFirst = true;
      ignoreDups = true;
      ignoreAllDups = true;
      ignoreSpace = true;
      findNoDups = true;
      saveNoDups = true;
      share = true;
    };

    initContent = lib.mkMerge [
      # Runs first in .zshrc, before completion setup.
      (lib.mkOrder 550 ''
        # zsh-autocomplete 26.08.04 writes its recent-dirs file here without
        # creating the folder first ("chpwd_recent_filehandler: no such file
        # or directory"). Fixed upstream after that release; drop this once
        # nixpkgs ships a newer one.
        [[ -d ${config.xdg.dataHome}/zsh ]] || mkdir -p ${config.xdg.dataHome}/zsh

        # zsh-autocomplete must load before anything else touches completion.
        source ${pkgs.zsh-autocomplete}/share/zsh-autocomplete/zsh-autocomplete.plugin.zsh
      '')

      ''
        setopt HIST_REDUCE_BLANKS HIST_VERIFY INC_APPEND_HISTORY
        setopt AUTO_CD

        alias -- -='cd -'

        mkcd() { mkdir -p "$1" && cd "$1"; }

        extract() {
          if [[ -f $1 ]]; then
            case $1 in
              *.tar.bz2) tar xjf "$1" ;;
              *.tar.gz)  tar xzf "$1" ;;
              *.bz2)     bunzip2 "$1" ;;
              *.rar)     unrar e "$1" ;;
              *.gz)      gunzip "$1" ;;
              *.tar)     tar xf "$1" ;;
              *.tbz2)    tar xjf "$1" ;;
              *.tgz)     tar xzf "$1" ;;
              *.zip)     unzip "$1" ;;
              *.Z)       uncompress "$1" ;;
              *.7z)      7z x "$1" ;;
              *)         echo "'$1' cannot be extracted via extract()" ;;
            esac
          else
            echo "'$1' is not a valid file"
          fi
        }
      ''

      # Last: per-machine settings, then zellij (which may replace this shell).
      (lib.mkOrder 1500 ''
        # Secrets and per-machine settings (not in the repo, never in Nix: the store
        # is world-readable). Sample: configs/zsh/local_env.zsh.sample
        [[ -f "$ZDOTDIR/local_env.zsh" ]] && source "$ZDOTDIR/local_env.zsh"

        # Zellij auto-start: on by default in interactive local shells outside
        # zellij. Opt out with ZELLIJ_AUTOSTART=0 in local_env.zsh (per machine)
        # or inline: `ZELLIJ_AUTOSTART=0 zsh`. `zsh -ic cmd` (editors reading
        # the environment) and shells without a terminal are skipped.
        if [[ -o interactive ]] && [[ -z "$ZSH_EXECUTION_STRING" ]] \
          && [[ -t 0 && -t 1 ]] && [[ "''${ZELLIJ_AUTOSTART:-1}" != 0 ]] \
          && [[ -z "$ZELLIJ" ]] && [[ -z "$SSH_CONNECTION" ]] \
          && command -v zellij &> /dev/null; then
          eval "$(zellij setup --generate-auto-start zsh)"
        fi
      '')
    ];
  };

  home.shellAliases = {
    # Safety
    cp = "cp -iv";
    mv = "mv -iv";
    rm = "rm -iv";

    # Navigation
    ".." = "cd ..";
    "..." = "cd ../..";
    "...." = "cd ../../..";
    dl = "cd ~/Downloads";
    dt = "cd ~/Desktop";
    src = "cd ~/src";
    dot = "cd ${dotfiles}";

    # Shell / Nix (nrs and ngc are per target: targets/*.nix)
    reload = "exec zsh";
    # Update the user/system packages (nix/flake.lock) to latest upstream; apply with nrs.
    nfu = "nix flake update --flake ${dotfiles}/nix";
    # Update the project dev shells (nix/shells/flake.lock).
    nus = "nix flake update --flake ${dotfiles}/nix/shells";
  };
}
