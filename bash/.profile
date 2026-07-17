# POSIX login-shell environment for Bash and compatible shells.

if [ -r "$HOME/.bash_env" ]; then
  . "$HOME/.bash_env"
elif [ -n "${DOTFILES_ROOT:-}" ] && [ -r "$DOTFILES_ROOT/bash/.bash_env" ]; then
  . "$DOTFILES_ROOT/bash/.bash_env"
fi
