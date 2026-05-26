# Bash interactive shell runtime.
# Keep login/environment setup in .profile/.bash_profile and interactive-only
# logic here so noninteractive shells stay clean.

DOTFILES_ROOT="${DOTFILES_ROOT:-$HOME/dotfiles}"

if [ -r "$DOTFILES_ROOT/bash/.bash_env" ]; then
    . "$DOTFILES_ROOT/bash/.bash_env"
fi

case $- in
    *i*) ;;
    *) return;;
esac

HISTCONTROL=ignoreboth
shopt -s histappend
HISTSIZE=1000
HISTFILESIZE=2000
shopt -s checkwinsize

DOTFILES_SHELL_REMOTE=0
if [ -n "${CI:-}" ] || [ -n "${SSH_CONNECTION:-}" ] || [ -n "${SSH_TTY:-}" ] || [ -n "${TMUX:-}" ]; then
    DOTFILES_SHELL_REMOTE=1
fi

DOTFILES_SHELL_EFFECTIVE_MODE="${DOTFILES_SHELL_MODE:-normal}"
case "$DOTFILES_SHELL_EFFECTIVE_MODE" in
    minimal|full)
        ;;
    *)
        if [ "$DOTFILES_SHELL_REMOTE" -eq 1 ]; then
            DOTFILES_SHELL_EFFECTIVE_MODE=minimal
        else
            DOTFILES_SHELL_EFFECTIVE_MODE=normal
        fi
        ;;
esac
export DOTFILES_SHELL_REMOTE DOTFILES_SHELL_EFFECTIVE_MODE

if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt

case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
esac

if [ "$DOTFILES_SHELL_EFFECTIVE_MODE" != minimal ]; then
    if [ -r "$HOME/.bash_aliases" ]; then
        . "$HOME/.bash_aliases"
    elif [ -r "$DOTFILES_ROOT/bash/.bash_aliases" ]; then
        . "$DOTFILES_ROOT/bash/.bash_aliases"
    fi
fi

if [ "$DOTFILES_SHELL_EFFECTIVE_MODE" != minimal ]; then
    if [ -r /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -r /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
fi

if [ -r "$HOME/.fzf.bash" ] && [ "$DOTFILES_SHELL_EFFECTIVE_MODE" != minimal ]; then
    . "$HOME/.fzf.bash"
fi

dotfiles-shell-diagnostics() {
    printf 'shell=%s\n' "bash"
    printf 'interactive=%s\n' "yes"
    printf 'login=%s\n' "$(shopt -q login_shell && printf yes || printf no)"
    printf 'remote=%s\n' "$DOTFILES_SHELL_REMOTE"
    printf 'mode=%s\n' "$DOTFILES_SHELL_EFFECTIVE_MODE"
    printf 'ssh_connection=%s\n' "${SSH_CONNECTION:-<unset>}"
    printf 'tmux=%s\n' "${TMUX:-<unset>}"
    printf 'editor=%s\n' "${EDITOR:-<unset>}"
    printf 'visual=%s\n' "${VISUAL:-<unset>}"
    printf 'path=%s\n' "$PATH"
    printf 'git=%s\n' "$(command -v git 2>/dev/null || printf '<missing>')"
    printf 'nvim=%s\n' "$(command -v nvim 2>/dev/null || printf '<missing>')"
    printf 'tmux_bin=%s\n' "$(command -v tmux 2>/dev/null || printf '<missing>')"
}
