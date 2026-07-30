# Zsh-only interactive helpers and local overlays.

dotfiles_command() {
  command -v "$1" 2>/dev/null
}

dotfiles_fd() {
  if dotfiles_command fd >/dev/null; then
    print -r -- fd
  elif dotfiles_command fdfind >/dev/null; then
    print -r -- fdfind
  else
    return 1
  fi
}

dotfiles_bat() {
  if dotfiles_command bat >/dev/null; then
    print -r -- bat
  elif dotfiles_command batcat >/dev/null; then
    print -r -- batcat
  else
    return 1
  fi
}

dotfiles_ls() {
  if dotfiles_command eza >/dev/null; then
    print -r -- eza
  else
    print -r -- ls
  fi
}

mkcd() {
  (( $# == 1 )) || {
    print -u2 'usage: mkcd <directory>'
    return 2
  }
  mkdir -p -- "$1" && builtin cd -- "$1"
}

ff() {
  local query=${1:-}
  local fd_bin
  fd_bin=$(dotfiles_fd 2>/dev/null) || fd_bin=""

  if [[ -n "$fd_bin" ]]; then
    command "$fd_bin" --type f --hidden --exclude .git -- "$query" .
  else
    find . -type f -not -path '*/.git/*' -name "*${query}*"
  fi
}

fcd() {
  local fd_bin directories selected
  fd_bin=$(dotfiles_fd 2>/dev/null) || fd_bin=""

  if [[ -n "$fd_bin" ]]; then
    directories=$(command "$fd_bin" --type d --hidden --exclude .git .)
  else
    directories=$(find . -type d -not -path '*/.git/*')
  fi

  if command -v fzf >/dev/null 2>&1 && [[ -t 0 ]]; then
    selected=$(print -r -- "$directories" | fzf --prompt='directory> ') || return
  else
    selected=$(print -r -- "$directories" | sed -n '1p')
  fi

  [[ -n "$selected" ]] && builtin cd -- "$selected"
}

rgi() {
  (( $# >= 1 )) || {
    print -u2 'usage: rgi <pattern> [path]'
    return 2
  }
  command -v rg >/dev/null 2>&1 || {
    print -u2 'ripgrep is not installed'
    return 10
  }
  rg --line-number --hidden --glob '!.git' -- "$@"
}

pspick() {
  if command -v fzf >/dev/null 2>&1 && [[ -t 0 ]]; then
    ps -eo pid,user,stat,etime,command \
      | sed 1d \
      | fzf --header='PID USER STAT ELAPSED COMMAND'
  else
    ps -eo pid,user,stat,etime,command
  fi
}

extract() {
  (( $# == 1 )) || {
    print -u2 'usage: extract <archive>'
    return 2
  }
  [[ -f "$1" ]] || return 2

  case "$1" in
    (*.tar.gz|*.tgz) tar -xzf "$1" ;;
    (*.tar.bz2|*.tbz2) tar -xjf "$1" ;;
    (*.tar.xz|*.txz) tar -xJf "$1" ;;
    (*.tar) tar -xf "$1" ;;
    (*.zip) unzip "$1" ;;
    (*.gz) gunzip "$1" ;;
    (*.bz2) bunzip2 "$1" ;;
    (*.xz) unxz "$1" ;;
    (*)
      print -u2 "unsupported archive: $1"
      return 2
      ;;
  esac
}

typeset -g _dotfiles_config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles"

[[ -r "$_dotfiles_config_dir/local.env" ]] \
  && source "$_dotfiles_config_dir/local.env"
[[ -r "$_dotfiles_config_dir/shell.local" ]] \
  && source "$_dotfiles_config_dir/shell.local"

if [[ "${DOTFILES_SHELL_EFFECTIVE_MODE:-normal}" != minimal \
  && -n "${DOTFILES_ROOT:-}" \
  && -r "$_dotfiles_config_dir/capabilities" ]]; then
  while IFS= read -r _dotfiles_capability; do
    case "$_dotfiles_capability" in
      (""|\#*) continue ;;
      (*[!A-Za-z0-9_-]*) continue ;;
    esac

    _dotfiles_capability_file="$DOTFILES_ROOT/capabilities/$_dotfiles_capability/shell.sh"
    [[ -r "$_dotfiles_capability_file" ]] \
      && source "$_dotfiles_capability_file"
  done < "$_dotfiles_config_dir/capabilities"
fi

unset _dotfiles_config_dir _dotfiles_capability _dotfiles_capability_file
