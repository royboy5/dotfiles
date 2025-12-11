# Create a new directory and enter it
function mkcd() {
  mkdir -p "$1" && cd "$1"
}

# Extract any archive
function extract() {
  if [ -f $1 ] ; then
    case $1 in
      *.tar.bz2)    tar xjf $1    ;;
      *.tar.gz)     tar xzf $1    ;;
      *.bz2)        bunzip2 $1    ;;
      *.rar)        unrar e $1    ;;
      *.gz)         gunzip $1     ;;
      *.tar)        tar xf $1     ;;
      *.tbz2)       tar xjf $1    ;;
      *.tgz)        tar xzf $1    ;;
      *.zip)        unzip $1      ;;
      *.Z)          uncompress $1 ;;
      *.7z)         7z x $1       ;;
      *)            echo "'$1' cannot be extracted via extract()" ;;
    esac
  else  
    echo "'$1' is not a valid file"
  fi
}

# Outputs the name of the current branch
# Usage example: git pull origin $(git_current_branch)
# Using '--quiet' with 'symbolic-ref' will not cause a fatal error (128) if
# it's not a symbolic ref, but in a Git repo.
function git_current_branch() {
  local ref
  ref=$(__git_prompt_git symbolic-ref --quiet HEAD 2> /dev/null)
  local ret=$?
  if [[ $ret != 0 ]]; then
    [[ $ret == 128 ]] && return  # no git repo.
    ref=$(__git_prompt_git rev-parse --short HEAD 2> /dev/null) || return
  fi
  echo ${ref#refs/heads/}
}
