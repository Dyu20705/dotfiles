# POSIX login-shell environment for Bash and compatible shells.

DOTFILES_ROOT="${DOTFILES_ROOT:-$HOME/dotfiles}"

if [ -r "$DOTFILES_ROOT/bash/.bash_env" ]; then
    . "$DOTFILES_ROOT/bash/.bash_env"
fi