# Bash login-shell entrypoint.

if [ -r "$HOME/.profile" ]; then
  # shellcheck source=/dev/null
  . "$HOME/.profile"
elif [ -n "${DOTFILES_ROOT:-}" ] && [ -r "$DOTFILES_ROOT/bash/.profile" ]; then
  # shellcheck source=/dev/null
  . "$DOTFILES_ROOT/bash/.profile"
fi

case $- in
  *i*)
    if [ -r "$HOME/.bashrc" ]; then
      # shellcheck source=/dev/null
      . "$HOME/.bashrc"
    elif [ -n "${DOTFILES_ROOT:-}" ] && [ -r "$DOTFILES_ROOT/bash/.bashrc" ]; then
      # shellcheck source=/dev/null
      . "$DOTFILES_ROOT/bash/.bashrc"
    fi
    ;;
esac
