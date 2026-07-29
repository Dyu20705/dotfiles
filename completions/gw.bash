_gw_complete() { COMPREPLY=($(compgen -W 'list status new open remove prune --help' -- "${COMP_WORDS[COMP_CWORD]}")); }
complete -F _gw_complete gw
