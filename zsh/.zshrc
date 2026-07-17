# Zsh configuration for the dotfiles terminal workflow.

setopt EXTENDED_HISTORY
setopt INC_APPEND_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_SAVE_NO_DUPS

typeset -U path PATH

HISTSIZE=50000
SAVEHIST=50000
HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"
mkdir -p "${HISTFILE:h}"

# Resolve the repository from the real .zshrc location when it is symlinked.
typeset -g DOTFILES_ROOT="${DOTFILES_ROOT:-${${(%):-%N}:A:h:h}}"
export DOTFILES_ROOT

DOTFILES_SHELL_MODE=${DOTFILES_SHELL_MODE:-normal}
DOTFILES_SHELL_REMOTE=0
DOTFILES_SHELL_IN_TMUX=0

if [[ -n "${CI:-}" || -n "${SSH_CONNECTION:-}" || -n "${SSH_TTY:-}" ]]; then
  DOTFILES_SHELL_REMOTE=1
fi

if [[ -n "${TMUX:-}" ]]; then
  DOTFILES_SHELL_IN_TMUX=1
fi

DOTFILES_SHELL_EFFECTIVE_MODE="$DOTFILES_SHELL_MODE"
if [[ "$DOTFILES_SHELL_MODE" != minimal && "$DOTFILES_SHELL_MODE" != full && "$DOTFILES_SHELL_REMOTE" -eq 1 ]]; then
  DOTFILES_SHELL_EFFECTIVE_MODE=minimal
fi

export DOTFILES_SHELL_MODE DOTFILES_SHELL_REMOTE DOTFILES_SHELL_IN_TMUX DOTFILES_SHELL_EFFECTIVE_MODE

add_to_path() {
  [[ -d "$1" ]] && path=("$1" $path)
}

path_append() {
  [[ -d "$1" ]] && path+=($1)
}

add_to_path "$HOME/.local/bin"
add_to_path "$HOME/.cargo/bin"
add_to_path "$HOME/.npm-global/bin"
add_to_path "$HOME/.npm/bin"
add_to_path "$HOME/.fnm/bin"
add_to_path "/usr/local/go/bin"

export EDITOR=${EDITOR:-nvim}
export VISUAL=${VISUAL:-nvim}
export LESS=${LESS:--R}

# Do not force a locale that is not installed on a fresh system.
if command -v locale >/dev/null 2>&1 && locale -a 2>/dev/null | grep -qi '^en_US\.utf-?8$'; then
  export LANG=${LANG:-en_US.UTF-8}
  export LC_ALL=${LC_ALL:-en_US.UTF-8}
fi

alias ..='cd ..'
alias ...='cd ../..'

if command -v eza >/dev/null 2>&1; then
  alias ls='eza'
  alias la='eza -la'
  alias ll='eza -l'
elif command -v exa >/dev/null 2>&1; then
  alias ls='exa'
  alias la='exa -la'
  alias ll='exa -l'
else
  alias la='ls -la'
  alias ll='ls -l'
fi

alias vi='nvim'
alias vim='nvim'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log'
alias gs='git status'
alias gd='git diff'
alias reload='exec zsh'
alias sudo='sudo '

mkcd() {
  [[ $# -eq 1 ]] || { print -u2 'usage: mkcd <directory>'; return 2; }
  mkdir -p -- "$1" || return
  cd -- "$1" || return
}

edit() {
  [[ $# -ge 1 ]] || { print -u2 'usage: edit <pattern>'; return 2; }
  local file
  file=$(find . -type f -name "*$1*" -print -quit 2>/dev/null)
  [[ -n "$file" ]] && "$EDITOR" "$file"
}

is_minimal_shell() {
  [[ "$DOTFILES_SHELL_EFFECTIVE_MODE" == minimal ]]
}

is_full_shell() {
  [[ "$DOTFILES_SHELL_EFFECTIVE_MODE" == full ]]
}

if is_minimal_shell; then
  PROMPT='%F{green}%n%f:%F{blue}%~%f %F{yellow}❯%f '
else
  if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
  else
    __git_branch() {
      git rev-parse --abbrev-ref HEAD 2>/dev/null | sed 's/^/ (/' | sed 's/$/)/'
    }
    PROMPT='%F{green}%n%f:%F{blue}%~%f%F{cyan}$(__git_branch)%f %F{yellow}❯%f '
  fi

  command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"

  if command -v fzf >/dev/null 2>&1; then
    fzf_init="$(fzf --zsh 2>/dev/null || true)"
    [[ -n "$fzf_init" ]] && eval "$fzf_init"
    unset fzf_init
  fi

  command -v direnv >/dev/null 2>&1 && eval "$(direnv hook zsh)"
  if is_full_shell && command -v atuin >/dev/null 2>&1; then
    eval "$(atuin init zsh)"
  fi
fi

# Completion needs a real terminal. Headless validation and automation should
# still be able to load an interactive shell without compinit opening /dev/tty.
if [[ "${DOTFILES_SKIP_COMPLETION:-0}" != 1 && ( -t 0 || -t 1 ) ]]; then
  autoload -Uz compinit
  zcompdump_dir="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
  zcompdump_file="$zcompdump_dir/zcompdump-$ZSH_VERSION"
  mkdir -p "$zcompdump_dir"

  if [[ -f "$zcompdump_file" ]]; then
    compinit -d "$zcompdump_file" || {
      rm -f "$zcompdump_file"
      compinit -d "$zcompdump_file"
    }
  else
    compinit -d "$zcompdump_file"
  fi

  setopt COMPLETE_IN_WORD
  setopt MENU_COMPLETE
  zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
fi

bindkey -e
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward
bindkey '^[[3~' delete-char
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line

dotfiles-shell-diagnostics() {
  print "shell=zsh"
  print "remote=$DOTFILES_SHELL_REMOTE"
  print "in_tmux=$DOTFILES_SHELL_IN_TMUX"
  print "mode=$DOTFILES_SHELL_EFFECTIVE_MODE"
  print "root=$DOTFILES_ROOT"
  print "editor=${EDITOR:-<unset>}"
  print "git=$(command -v git 2>/dev/null || print '<missing>')"
  print "nvim=$(command -v nvim 2>/dev/null || print '<missing>')"
  print "tmux=$(command -v tmux 2>/dev/null || print '<missing>')"
}

if [[ -z "${DOTFILES_SHELL_CHECKED:-}" && "$DOTFILES_SHELL_EFFECTIVE_MODE" == full ]]; then
  missing=()
  for tool in git nvim tmux jq; do
    command -v "$tool" >/dev/null 2>&1 || missing+=("$tool")
  done
  (( ${#missing[@]} == 0 )) || print -u2 "Warning: missing tools: ${missing[*]}"
  export DOTFILES_SHELL_CHECKED=1
fi
