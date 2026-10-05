# Zsh configuration for the personal terminal workflow.

setopt EXTENDED_HISTORY INC_APPEND_HISTORY HIST_IGNORE_DUPS
setopt HIST_FIND_NO_DUPS HIST_IGNORE_SPACE HIST_SAVE_NO_DUPS
typeset -U path PATH

HISTSIZE=50000
SAVEHIST=50000
HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"
mkdir -p "${HISTFILE:h}"

typeset -g DOTFILES_ROOT="${DOTFILES_ROOT:-${${(%):-%N}:A:h:h}}"
export DOTFILES_ROOT

DOTFILES_SHELL_MODE=${DOTFILES_SHELL_MODE:-normal}
case "$DOTFILES_SHELL_MODE" in
  minimal|normal|full) ;;
  *) DOTFILES_SHELL_MODE=normal ;;
esac

DOTFILES_SHELL_REMOTE=0
DOTFILES_SHELL_IN_TMUX=0
[[ -n "${CI:-}" || -n "${SSH_CONNECTION:-}" || -n "${SSH_TTY:-}" ]] \
  && DOTFILES_SHELL_REMOTE=1
[[ -n "${TMUX:-}" ]] && DOTFILES_SHELL_IN_TMUX=1

DOTFILES_SHELL_EFFECTIVE_MODE="$DOTFILES_SHELL_MODE"
if [[ "$DOTFILES_SHELL_MODE" == normal && "$DOTFILES_SHELL_REMOTE" -eq 1 ]]; then
  DOTFILES_SHELL_EFFECTIVE_MODE=minimal
fi

export DOTFILES_SHELL_MODE DOTFILES_SHELL_REMOTE
export DOTFILES_SHELL_IN_TMUX DOTFILES_SHELL_EFFECTIVE_MODE

path=("$HOME/.local/bin" $path)
[[ -d "$HOME/.cargo/bin" ]] && path=("$HOME/.cargo/bin" $path)
[[ -d "$HOME/.deno/bin" ]] && path=("$HOME/.deno/bin" $path)
[[ -d "$HOME/.npm-global/bin" ]] && path=("$HOME/.npm-global/bin" $path)
export EDITOR=${EDITOR:-nvim}
export VISUAL=${VISUAL:-nvim}
export LESS=${LESS:--R}

if [[ -r "$DOTFILES_ROOT/zsh/common.zsh" ]]; then
  source "$DOTFILES_ROOT/zsh/common.zsh"
fi

alias ..='cd ..'
alias ...='cd ../..'
alias vi='nvim'
alias vim='nvim'
alias gs='git status'
alias gd='git diff'
alias gl='git log --oneline --decorate --graph'
alias reload='exec zsh'

if command -v eza >/dev/null 2>&1; then
  alias ll='eza -la'
  alias la='eza -a'
else
  alias ll='ls -l'
  alias la='ls -la'
fi

if [[ "$DOTFILES_SHELL_EFFECTIVE_MODE" == minimal ]]; then
  PROMPT='%F{green}%n%f:%F{blue}%~%f %F{yellow}❯%f '
else
  if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
  else
    PROMPT='%F{green}%n%f:%F{blue}%~%f %F{yellow}❯%f '
  fi

  command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"
  command -v direnv >/dev/null 2>&1 && eval "$(direnv hook zsh)"

  if [[ "$DOTFILES_SHELL_EFFECTIVE_MODE" == full ]] \
    && command -v atuin >/dev/null 2>&1; then
    eval "$(atuin init zsh)"
  fi
fi

if [[ "${DOTFILES_SKIP_COMPLETION:-0}" != 1 && ( -t 0 || -t 1 ) ]]; then
  fpath=("$HOME/.local/share/zsh/site-functions" $fpath)
  autoload -Uz compinit
  zcompdump="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump-$ZSH_VERSION"
  mkdir -p "${zcompdump:h}"
  compinit -d "$zcompdump"
fi

bindkey -e
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward

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

# >>> juliaup initialize >>>

# !! Contents within this block are managed by juliaup !!

path=('/home/duy/.juliaup/bin' $path)
export PATH
# Tab completion for juliaup and julia channel selection
[ -f "/home/duy/.julia/juliaup/completions/zsh.zsh" ] && source "/home/duy/.julia/juliaup/completions/zsh.zsh"

# <<< juliaup initialize <<<
