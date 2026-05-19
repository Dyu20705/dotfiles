# ============================================================================
# Zsh Configuration - dotfiles minimal, production-ready setup
# ============================================================================
# This is a minimal .zshrc suitable for fresh Ubuntu environments
# See docs/SHELL_SETUP.md for customization options

# ============================================================================
# Early Initialization
# ============================================================================

# Enable Zsh options early
setopt EXTENDED_HISTORY          # Save timestamps in history
setopt INC_APPEND_HISTORY        # Write to history immediately
setopt HIST_IGNORE_DUPS          # Don't record duplicates
setopt HIST_FIND_NO_DUPS         # Don't show duplicates in search
setopt HIST_IGNORE_SPACE         # Ignore commands starting with space
setopt HIST_SAVE_NO_DUPS         # Don't save duplicates

# Use unique path arrays so PATH mutations stay idempotent.
typeset -U path PATH

# History configuration
HISTSIZE=50000
SAVEHIST=50000
HISTFILE=~/.zsh_history

# ==========================================================================
# Runtime mode and environment detection
# ==========================================================================

DOTFILES_SHELL_MODE=${DOTFILES_SHELL_MODE:-normal}
DOTFILES_SHELL_REMOTE=0

if [[ -n "$CI" || -n "$SSH_CONNECTION" || -n "$SSH_TTY" ]]; then
    DOTFILES_SHELL_REMOTE=1
fi

# Nested tmux sessions are usually latency-sensitive and should avoid extra work.
if [[ -n "$TMUX" ]]; then
    DOTFILES_SHELL_REMOTE=1
fi

DOTFILES_SHELL_EFFECTIVE_MODE="$DOTFILES_SHELL_MODE"
if [[ "$DOTFILES_SHELL_MODE" != "minimal" && "$DOTFILES_SHELL_MODE" != "full" && "$DOTFILES_SHELL_REMOTE" -eq 1 ]]; then
    DOTFILES_SHELL_EFFECTIVE_MODE="minimal"
fi

# ============================================================================
# PATH Management (idempotent - safe to re-source)
# ============================================================================

# Function to add to PATH only if not already present
add_to_path() {
    if [[ ":${PATH}:" != *":$1:"* ]]; then
        export PATH="$1:${PATH}"
    fi
}

path_append() {
    if [[ ":${PATH}:" != *":$1:"* ]]; then
        export PATH="${PATH}:$1"
    fi
}

# Add common tool locations
add_to_path "$HOME/.local/bin"
add_to_path "$HOME/.cargo/bin"
add_to_path "$HOME/.npm/bin"
add_to_path "$HOME/.fnm/bin"  # Fast Node Manager
add_to_path "/usr/local/go/bin"

# ============================================================================
# Core Environment
# ============================================================================

# Preferred editor
export EDITOR="nvim"
export VISUAL="nvim"

# Less options
export LESS="-R"

# Language
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# ============================================================================
# Aliases (safe, useful defaults)
# ============================================================================

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ~='cd ~'

# List commands
if command -v exa &> /dev/null; then
    alias ls='exa'
    alias la='exa -la'
    alias ll='exa -l'
else
    alias la='ls -la'
    alias ll='ls -l'
fi

# Editors
alias vi='nvim'
alias vim='nvim'

# Git (safe, common operations)
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log'
alias gs='git status'
alias gd='git diff'

# System
alias reload='exec zsh'
alias sudo='sudo '  # Allow aliases after sudo

# ============================================================================
# Common Functions
# ============================================================================

# Create directory and enter it
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Find and open in editor
edit() {
    local file
    file=$(find . -type f -name "*$1*" 2>/dev/null | head -1)
    [[ -n "$file" ]] && ${EDITOR} "$file"
}

is_minimal_shell() {
    [[ "$DOTFILES_SHELL_EFFECTIVE_MODE" == "minimal" ]]
}

is_full_shell() {
    [[ "$DOTFILES_SHELL_EFFECTIVE_MODE" == "full" ]]
}

# ============================================================================
# Shell Integration (if available)
# ============================================================================

if is_minimal_shell; then
    # Minimal mode: deterministic prompt, no optional integrations.
    PROMPT='%F{green}%n%f:%F{blue}%~%f %F{yellow}❯%f '
else
    # Normal/full mode: load optional integrations only when available.
    if command -v starship &> /dev/null; then
        eval "$(starship init zsh)"
    else
        # Fallback to basic prompt
        PROMPT='%F{green}%n%f:%F{blue}%~%f%F{cyan}$(__git_branch)%f %F{yellow}❯%f '

        # Simple git branch display
        __git_branch() {
            git rev-parse --abbrev-ref HEAD 2>/dev/null | sed 's/^/ (/' | sed 's/$/)/'
        }
    fi

    if command -v zoxide &> /dev/null; then
        eval "$(zoxide init zsh)"
    fi

    if command -v fzf &> /dev/null; then
        eval "$(fzf --zsh)"
    fi

    if command -v direnv &> /dev/null; then
        eval "$(direnv hook zsh)"
    fi

        if is_full_shell && command -v atuin &> /dev/null; then
        eval "$(atuin init zsh)"
    fi
fi

# ============================================================================
# Completion System
# ============================================================================

# Enable completion
autoload -Uz compinit

zcompdump_dir="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
zcompdump_file="$zcompdump_dir/zcompdump-$ZSH_VERSION"
[[ -d "$zcompdump_dir" ]] || command mkdir -p "$zcompdump_dir"

# Load completions cache (faster subsequent starts)
if [[ -f "$zcompdump_file" ]]; then
    compinit -d "$zcompdump_file" || {
        rm -f "$zcompdump_file"
        compinit -d "$zcompdump_file"
    }
else
    compinit -d "$zcompdump_file"
fi

# Completion options
setopt COMPLETE_IN_WORD
setopt MENU_COMPLETE

# Case-insensitive completion
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# ============================================================================
# Key Bindings
# ============================================================================

# Emacs-style by default (compatible with most shells)
bindkey -e

# Common bindings
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward

# Delete key
bindkey '^[[3~' delete-char

# Home/End keys
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line

# ============================================================================
# Post-Initialization Checks
# ============================================================================

# Warn about missing essential tools (non-fatal)
check_tools() {
    local essential=("git" "nvim" "tmux")
    local missing=()
    
    for tool in "${essential[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            missing+=("$tool")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "⚠ Warning: Missing tools - ${missing[*]}" >&2
    fi
}

# Only run once per session
if [[ -z "$DOTFILES_SHELL_CHECKED" ]]; then
    if is_full_shell; then
        check_tools
    fi
    export DOTFILES_SHELL_CHECKED=1
fi

# ============================================================================
# End of .zshrc
# ============================================================================
