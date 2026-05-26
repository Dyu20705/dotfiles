# Workflow aliases for interactive Bash shells only.

alias ..='cd ..'
alias ...='cd ../..'

alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

mkcd() {
    mkdir -p "$1" && cd "$1"
}