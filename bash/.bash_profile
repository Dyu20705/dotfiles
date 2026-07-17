# Bash login-shell entrypoint.

if [ -r "$HOME/.profile" ]; then
  . "$HOME/.profile"
elif [ -n "${DOTFILES_ROOT:-}" ] && [ -r "$DOTFILES_ROOT/bash/.profile" ]; then
  . "$DOTFILES_ROOT/bash/.profile"
fi

case $- in
  *i*)
    if [ -r "$HOME/.bashrc" ]; then
      . "$HOME/.bashrc"
    elif [ -n "${DOTFILES_ROOT:-}" ] && [ -r "$DOTFILES_ROOT/bash/.bashrc" ]; then
      . "$DOTFILES_ROOT/bash/.bashrc"
    fi
    ;;
esac
