# Git tooling.
{ pkgs, linkConfig, ... }:

{
  home.packages = with pkgs; [
    git
    git-lfs
    delta
    lazygit
  ];

  # ~/.config/git/config and ~/.config/git/ignore (global gitignore).
  xdg.configFile."git".source = linkConfig "git";

  home.shellAliases = {
    lg = "lazygit";
    g = "git";

    # Status / add
    ga = "git add";
    gaa = "git add --all";
    gs = "git status";
    gss = "git status -s";
    gsb = "git status -sb";

    # Commit
    gc = "git commit -v";
    gcmsg = "git commit -m";
    gcam = "git commit -a -m";
    gam = "git commit --amend";
    gamn = "git commit --amend --no-edit";

    # Branches
    gb = "git branch";
    gba = "git branch -a";
    gbd = "git branch -d";
    gbD = "git branch -D";
    gsw = "git switch";
    gswc = "git switch -c";
    gco = "git checkout";
    gcb = "git checkout -b";

    # Pull / push (git_current_branch is defined below)
    gl = "git pull";
    gp = "git push";
    gpf = "git push --force-with-lease";
    ggpull = ''git pull origin "$(git_current_branch)"'';
    ggpush = ''git push origin "$(git_current_branch)"'';
    gpsup = ''git push --set-upstream origin "$(git_current_branch)"'';

    # Log
    glog = "git log --oneline --decorate --graph";
    gloga = "git log --oneline --decorate --graph --all";
    glo = ''git log --pretty="format:%C(auto)%h %C(green)%an %C(blue)%ar %C(auto)%d %s"'';

    # Stash
    gst = "git stash";
    gstp = "git stash pop";
    gstd = "git stash drop";
    gstl = "git stash list";
  };

  programs.zsh.initContent = ''
    git_current_branch() { git -C "''${1:-.}" rev-parse --abbrev-ref HEAD 2> /dev/null; }
  '';
}
