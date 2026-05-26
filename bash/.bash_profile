# Bash login-shell entrypoint.
# Source the shared environment first, then interactive shell setup.

DOTFILES_ROOT="${DOTFILES_ROOT:-$HOME/dotfiles}"

if [ -r "$DOTFILES_ROOT/bash/.profile" ]; then
    . "$DOTFILES_ROOT/bash/.profile"
fi

case $- in
    *i*)
        if [ -r "$DOTFILES_ROOT/bash/.bashrc" ]; then
            . "$DOTFILES_ROOT/bash/.bashrc"
        fi
        ;;
esac