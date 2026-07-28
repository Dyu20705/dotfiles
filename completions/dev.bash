_dev_complete() { COMPREPLY=($(compgen -W '. --list --refresh --kill --help' -- "${COMP_WORDS[COMP_CWORD]}")); }
complete -F _dev_complete dev
