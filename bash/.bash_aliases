# Workflow aliases for interactive Bash shells only.

alias ..='cd ..'
alias ...='cd ../..'

alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

mkcd() {
    [ "$#" -eq 1 ] || {
        printf 'usage: mkcd <directory>\n' >&2
        return 2
    }
    mkdir -p -- "$1" || return
    cd -- "$1" || return
}
