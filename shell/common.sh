# Shared interactive shell functions. Keep POSIX-compatible for Bash and Zsh.

dotfiles_command() { command -v "$1" 2>/dev/null || return 1; }
dotfiles_fd() { if dotfiles_command fd >/dev/null; then printf 'fd\n'; elif dotfiles_command fdfind >/dev/null; then printf 'fdfind\n'; else return 1; fi; }
dotfiles_bat() { if dotfiles_command bat >/dev/null; then printf 'bat\n'; elif dotfiles_command batcat >/dev/null; then printf 'batcat\n'; else return 1; fi; }
dotfiles_ls() { if dotfiles_command eza >/dev/null; then printf 'eza\n'; else printf 'ls\n'; fi; }
mkcd() { [ "$#" -eq 1 ] || { printf 'usage: mkcd <directory>\n' >&2; return 2; }; mkdir -p -- "$1" && cd -- "$1"; }
ff() { query=${1:-}; fd_bin=$(dotfiles_fd 2>/dev/null || true); if [ -n "$fd_bin" ]; then "$fd_bin" --type f --hidden --exclude .git -- "$query" .; else find . -type f -not -path '*/.git/*' -name "*$query*"; fi; }
fcd() { fd_bin=$(dotfiles_fd 2>/dev/null || true); if [ -n "$fd_bin" ]; then directories=$("$fd_bin" --type d --hidden --exclude .git .); else directories=$(find . -type d -not -path '*/.git/*'); fi; if command -v fzf >/dev/null 2>&1 && [ -t 0 ]; then selected=$(printf '%s\n' "$directories" | fzf --prompt='directory> ') || return; else selected=$(printf '%s\n' "$directories" | sed -n '1p'); fi; [ -n "$selected" ] && cd -- "$selected"; }
rgi() { [ "$#" -ge 1 ] || { printf 'usage: rgi <pattern> [path]\n' >&2; return 2; }; command -v rg >/dev/null 2>&1 || { printf 'ripgrep is not installed\n' >&2; return 10; }; rg --line-number --hidden --glob '!.git' -- "$@"; }
pspick() { if command -v fzf >/dev/null 2>&1 && [ -t 0 ]; then ps -eo pid,user,stat,etime,command | sed 1d | fzf --header='PID USER STAT ELAPSED COMMAND'; else ps -eo pid,user,stat,etime,command; fi; }
extract() { [ "$#" -eq 1 ] || { printf 'usage: extract <archive>\n' >&2; return 2; }; [ -f "$1" ] || return 2; case "$1" in *.tar.gz|*.tgz) tar -xzf "$1" ;; *.tar.bz2|*.tbz2) tar -xjf "$1" ;; *.tar.xz|*.txz) tar -xJf "$1" ;; *.tar) tar -xf "$1" ;; *.zip) unzip "$1" ;; *.gz) gunzip "$1" ;; *.bz2) bunzip2 "$1" ;; *.xz) unxz "$1" ;; *) printf 'unsupported archive: %s\n' "$1" >&2; return 2 ;; esac; }

_dotfiles_config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles"
[ -r "$_dotfiles_config_dir/local.env" ] && . "$_dotfiles_config_dir/local.env"
[ -r "$_dotfiles_config_dir/shell.local" ] && . "$_dotfiles_config_dir/shell.local"

if [ "${DOTFILES_SHELL_EFFECTIVE_MODE:-normal}" != minimal ] \
  && [ -n "${DOTFILES_ROOT:-}" ] \
  && [ -r "$_dotfiles_config_dir/capabilities" ]; then
  while IFS= read -r _dotfiles_capability; do
    case "$_dotfiles_capability" in
      ""|\#*) continue ;;
      *[!A-Za-z0-9_-]*) continue ;;
    esac
    _dotfiles_capability_file="$DOTFILES_ROOT/capabilities/$_dotfiles_capability/shell.sh"
    [ -r "$_dotfiles_capability_file" ] && . "$_dotfiles_capability_file"
  done < "$_dotfiles_config_dir/capabilities"
fi
unset _dotfiles_config_dir _dotfiles_capability _dotfiles_capability_file
