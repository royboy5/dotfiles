# bat
alias cat='bat --style=plain'

# exa
alias l='exa'
alias la='exa -a'
alias ll='exa -lah --group-directories-first'
alias ls='exa --color=auto'

# nvim 
alias vi="nvim"

# git
alias ga='git add'
alias gaa='git add --all'
alias gb='git branch'
alias gba='git branch -a'
alias gbd='git branch -d'
alias gbD='git branch -D'
alias gbnm='git branch --no-merged'
alias gbl='git blame -b -w'
alias gc='git commit -v'
alias gcam='git commit -a -m'
alias gcmsg='git commit -m'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gcf='git config --list'
alias gl='git pull'
alias ggpull='git pull origin "$(git_current_branch)"'
alias gp='git push'
alias ggpush='git push origin "$(git_current_branch)"'
alias ggsup='git branch --set-upstream-to=origin/$(git_current_branch)'
alias gpsup='git push --set-upstream origin $(git_current_branch)'
alias glog='git log --oneline --decorate --graph'
alias gloga='git log --oneline --decorate --graph --all'
alias gm='git merge'
alias gsb='git status -sb'
alias gss='git status -s'
alias gst='git status'
alias gf='git fetch'
