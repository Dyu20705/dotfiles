# Workflow aliases for interactive Bash shells only.

if [ -n "${DOTFILES_ROOT:-}" ] && [ -r "$DOTFILES_ROOT/shell/common.sh" ]; then
  # shellcheck source=/dev/null
  . "$DOTFILES_ROOT/shell/common.sh"
fi

alias ..='cd ..'
alias ...='cd ../..'

if command -v eza >/dev/null 2>&1; then
  alias ll='eza -la'
  alias la='eza -a'
  alias l='eza'
else
  alias ll='ls -alF'
  alias la='ls -A'
  alias l='ls -CF'
fi
