# Bash interactive shell runtime.
# Keep login/environment setup in .profile/.bash_profile and interactive-only
# logic here so noninteractive shells stay clean.

if [ -z "${DOTFILES_ROOT:-}" ]; then
  _dotfiles_source=${BASH_SOURCE[0]}
  if command -v realpath >/dev/null 2>&1; then
    _dotfiles_source=$(realpath "$_dotfiles_source")
  elif command -v python3 >/dev/null 2>&1; then
    _dotfiles_source=$(python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$_dotfiles_source")
  elif command -v readlink >/dev/null 2>&1 && [ -L "$_dotfiles_source" ]; then
    _dotfiles_target=$(readlink "$_dotfiles_source")
    case "$_dotfiles_target" in
      /*) _dotfiles_source=$_dotfiles_target ;;
      *) _dotfiles_source="$(dirname "$_dotfiles_source")/$_dotfiles_target" ;;
    esac
    unset _dotfiles_target
  fi
  DOTFILES_ROOT=$(cd "$(dirname "$_dotfiles_source")/.." 2>/dev/null && pwd) || DOTFILES_ROOT=$HOME
  unset _dotfiles_source
fi
export DOTFILES_ROOT

if [ -r "$DOTFILES_ROOT/bash/.bash_env" ]; then
  . "$DOTFILES_ROOT/bash/.bash_env"
fi

case $- in
  *i*) ;;
  *) return ;;
esac

HISTCONTROL=ignoreboth
shopt -s histappend checkwinsize
HISTSIZE=50000
HISTFILESIZE=50000

DOTFILES_SHELL_REMOTE=0
DOTFILES_SHELL_IN_TMUX=0
if [ -n "${CI:-}" ] || [ -n "${SSH_CONNECTION:-}" ] || [ -n "${SSH_TTY:-}" ]; then
  DOTFILES_SHELL_REMOTE=1
fi
if [ -n "${TMUX:-}" ]; then
  DOTFILES_SHELL_IN_TMUX=1
fi

DOTFILES_SHELL_EFFECTIVE_MODE=${DOTFILES_SHELL_MODE:-normal}
case "$DOTFILES_SHELL_EFFECTIVE_MODE" in
  minimal|full) ;;
  *)
    if [ "$DOTFILES_SHELL_REMOTE" -eq 1 ]; then
      DOTFILES_SHELL_EFFECTIVE_MODE=minimal
    else
      DOTFILES_SHELL_EFFECTIVE_MODE=normal
    fi
    ;;
esac
export DOTFILES_SHELL_REMOTE DOTFILES_SHELL_IN_TMUX DOTFILES_SHELL_EFFECTIVE_MODE

if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
  debian_chroot=$(cat /etc/debian_chroot)
fi

color_prompt=
case "${TERM:-}" in
  xterm-color|*-256color) color_prompt=yes ;;
esac

if [ "$color_prompt" = yes ]; then
  PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
  PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt

case "${TERM:-}" in
  xterm*|rxvt*) PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1" ;;
esac

if [ "$DOTFILES_SHELL_EFFECTIVE_MODE" != minimal ]; then
  if [ -r "$HOME/.bash_aliases" ]; then
    . "$HOME/.bash_aliases"
  elif [ -r "$DOTFILES_ROOT/bash/.bash_aliases" ]; then
    . "$DOTFILES_ROOT/bash/.bash_aliases"
  fi

  if [ -r /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -r /etc/bash_completion ]; then
    . /etc/bash_completion
  fi

  if [ -r "$HOME/.fzf.bash" ]; then
    . "$HOME/.fzf.bash"
  fi
fi

# Cargo is optional and must never make a fresh shell noisy.
if [ "$DOTFILES_SHELL_EFFECTIVE_MODE" != minimal ] && [ -r "$HOME/.cargo/env" ]; then
  . "$HOME/.cargo/env"
fi

dotfiles-shell-diagnostics() {
  printf 'shell=%s\n' bash
  printf 'interactive=%s\n' yes
  printf 'login=%s\n' "$(shopt -q login_shell && printf yes || printf no)"
  printf 'remote=%s\n' "$DOTFILES_SHELL_REMOTE"
  printf 'in_tmux=%s\n' "$DOTFILES_SHELL_IN_TMUX"
  printf 'mode=%s\n' "$DOTFILES_SHELL_EFFECTIVE_MODE"
  printf 'root=%s\n' "$DOTFILES_ROOT"
  printf 'ssh_connection=%s\n' "${SSH_CONNECTION:-<unset>}"
  printf 'editor=%s\n' "${EDITOR:-<unset>}"
  printf 'visual=%s\n' "${VISUAL:-<unset>}"
  printf 'path=%s\n' "$PATH"
  printf 'git=%s\n' "$(command -v git 2>/dev/null || printf '<missing>')"
  printf 'nvim=%s\n' "$(command -v nvim 2>/dev/null || printf '<missing>')"
  printf 'tmux_bin=%s\n' "$(command -v tmux 2>/dev/null || printf '<missing>')"
}
