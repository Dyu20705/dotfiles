#!/usr/bin/env bash
# Diagnostics script - Comprehensive validation of entire dotfiles setup
#
# This script:
# - Validates shell configuration
# - Checks Neovim setup and LSP availability
# - Validates Tmux configuration
# - Checks WezTerm setup
# - Verifies Git configuration
# - Detects potential conflicts
# - Profiles startup performance
#
# Usage:
#   ./scripts/diagnostics/run.sh                # Run all checks
#   ./scripts/diagnostics/run.sh --quick        # Quick checks only
#   ./scripts/diagnostics/run.sh --deep         # Deep diagnostic
#   ./scripts/diagnostics/run.sh --profile      # Include profiling

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="${SCRIPT_DIR}/../.."
DIAGNOSTICS_TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DIAGNOSTICS_LOG="${DOTFILES_ROOT}/logs/diagnostics_${DIAGNOSTICS_TIMESTAMP}.log"

# Diagnostic flags
QUICK_MODE=false
DEEP_MODE=false
PROFILE_MODE=false
VERBOSE=false

# Counters
CHECKS_PASSED=0
CHECKS_FAILED=0
WARNINGS=0

# ============================================================================
# Logging
# ============================================================================

mkdir -p "$(dirname "${DIAGNOSTICS_LOG}")"

log_raw() {
    echo "$*" >> "${DIAGNOSTICS_LOG}"
}

log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    log_raw "[${timestamp}] [${level}] ${message}"
    
    case $level in
        PASS)
            echo -e "${GREEN}✓ ${message}${NC}"
            ((CHECKS_PASSED++))
            ;;
        FAIL)
            echo -e "${RED}✗ ${message}${NC}"
            ((CHECKS_FAILED++))
            ;;
        WARN)
            echo -e "${YELLOW}⚠ ${message}${NC}"
            ((WARNINGS++))
            ;;
        INFO)
            [[ ${VERBOSE} == true ]] && echo -e "${BLUE}ℹ ${message}${NC}"
            ;;
    esac
}

section() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}${1}${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# ============================================================================
# System Information
# ============================================================================

check_system_info() {
    section "System Information"
    
    echo -e "OS: $(lsb_release -d | cut -f2)"
    echo -e "Kernel: $(uname -r)"
    echo -e "Shell: ${SHELL}"
    echo -e "Home: ${HOME}"
    echo -e "User: $(whoami)"
    echo ""
}

# ============================================================================
# Environment Checks
# ============================================================================

check_command_exists() {
    local cmd=$1
    if command -v "${cmd}" &> /dev/null; then
        log PASS "Command available: ${cmd}"
        echo "  Path: $(which "${cmd}")"
        return 0
    else
        log FAIL "Command not found: ${cmd}"
        return 1
    fi
}

check_core_commands() {
    section "Core Commands"
    
    local commands=("bash" "zsh" "git" "vim" "nvim" "tmux" "python3" "node" "curl")
    
    for cmd in "${commands[@]}"; do
        check_command_exists "${cmd}" || true
    done
}

# ============================================================================
# Shell Configuration Checks
# ============================================================================

check_shell_syntax() {
    section "Shell Configuration"
    
    # Check Zsh
    if [[ -f "${HOME}/.zshrc" ]]; then
        if zsh -n "${HOME}/.zshrc" 2>> "${DIAGNOSTICS_LOG}"; then
            log PASS "Zsh configuration syntax valid"
        else
            log FAIL "Zsh configuration has syntax errors"
        fi
    else
        log WARN "Zsh config not found: ${HOME}/.zshrc"
    fi
    
    # Check Bash
    if [[ -f "${HOME}/.bashrc" ]]; then
        if bash -n "${HOME}/.bashrc" 2>> "${DIAGNOSTICS_LOG}"; then
            log PASS "Bash configuration syntax valid"
        else
            log FAIL "Bash configuration has syntax errors"
        fi
    else
        log WARN "Bash config not found: ${HOME}/.bashrc"
    fi
}

check_shell_startup() {
    section "Shell Startup Performance"
    
    if [[ ${PROFILE_MODE} == false ]]; then
        log INFO "Profiling disabled (use --profile to enable)"
        return 0
    fi
    
    log INFO "Measuring shell startup times..."
    
    # Zsh startup
    if command -v zsh &> /dev/null; then
        local zsh_time=$( { time zsh -i -c exit; } 2>&1 | grep real | awk '{print $2}')
        echo -e "  Zsh startup: ${zsh_time}"
        log_raw "Zsh startup time: ${zsh_time}"
    fi
    
    # Bash startup
    if command -v bash &> /dev/null; then
        local bash_time=$( { time bash -i -c exit; } 2>&1 | grep real | awk '{print $2}')
        echo -e "  Bash startup: ${bash_time}"
        log_raw "Bash startup time: ${bash_time}"
    fi
}

check_path_duplicates() {
    section "PATH Configuration"
    
    echo "PATH entries: $(echo $PATH | tr ':' '\n' | wc -l)"
    
    # Check for duplicates
    local duplicates=$(echo $PATH | tr ':' '\n' | sort | uniq -d)
    if [[ -z "${duplicates}" ]]; then
        log PASS "No duplicate PATH entries"
    else
        log WARN "Duplicate PATH entries detected:"
        echo "${duplicates}" | while read -r dup; do
            echo "  - ${dup}"
        done
    fi
}

# ============================================================================
# Neovim Checks
# ============================================================================

check_nvim_config() {
    section "Neovim Configuration"
    
    if ! command -v nvim &> /dev/null; then
        log FAIL "Neovim not installed"
        return 1
    fi
    
    log PASS "Neovim installed: $(nvim --version | head -1)"
    
    if [[ ! -d "${HOME}/.config/nvim" ]]; then
        log FAIL "Neovim config directory not found"
        return 1
    fi
    
    log PASS "Neovim config directory exists"
    
    # Check init.lua
    if [[ ! -f "${HOME}/.config/nvim/init.lua" ]]; then
        log FAIL "init.lua not found"
        return 1
    fi
    
    log PASS "init.lua exists"
    
    # Check Lua syntax
    if command -v lua &> /dev/null; then
        if lua -l luac -p "${HOME}/.config/nvim/init.lua" 2>> "${DIAGNOSTICS_LOG}"; then
            log PASS "init.lua syntax valid"
        else
            log FAIL "init.lua has syntax errors"
        fi
    fi
}

check_nvim_lsp() {
    section "Neovim LSP Servers"
    
    if ! command -v nvim &> /dev/null; then
        log WARN "Neovim not installed, skipping LSP checks"
        return 0
    fi
    
    # Expected LSP servers
    local lsps=("lua_ls" "pylsp" "clangd" "rust_analyzer" "gopls")
    
    for lsp in "${lsps[@]}"; do
        if nvim --clean +":execute 'Mason'" +q 2>/dev/null | grep -q "${lsp}"; then
            log PASS "LSP available: ${lsp}"
        else
            log WARN "LSP may not be installed: ${lsp}"
        fi
    done
}

check_nvim_health() {
    section "Neovim Health Check"
    
    if ! command -v nvim &> /dev/null; then
        log WARN "Neovim not installed"
        return 0
    fi
    
    # Run neovim health check (non-interactive)
    if nvim +checkhealth +q 2>> "${DIAGNOSTICS_LOG}"; then
        log PASS "Neovim health check passed"
    else
        log WARN "Neovim health check had warnings (check logs)"
    fi
}

# ============================================================================
# Tmux Checks
# ============================================================================

check_tmux_config() {
    section "Tmux Configuration"
    
    if ! command -v tmux &> /dev/null; then
        log FAIL "Tmux not installed"
        return 1
    fi
    
    log PASS "Tmux installed: $(tmux -V)"
    
    # Check config file
    if [[ ! -f "${HOME}/.tmux.conf" ]]; then
        log FAIL "Tmux config not found"
        return 1
    fi
    
    log PASS "Tmux config found"
    
    # Validate syntax
    if tmux source-file -q "${HOME}/.tmux.conf" 2>> "${DIAGNOSTICS_LOG}"; then
        log PASS "Tmux configuration syntax valid"
    else
        log FAIL "Tmux configuration has errors"
    fi
}

check_tmux_plugins() {
    section "Tmux Plugin Manager"
    
    local tpm_dir="${HOME}/.tmux/plugins/tpm"
    
    if [[ -d "${tpm_dir}" ]]; then
        log PASS "TPM installed"
        
        # List plugins
        local plugins_dir="${HOME}/.tmux/plugins"
        if [[ -d "${plugins_dir}" ]]; then
            echo "  Installed plugins:"
            ls -1 "${plugins_dir}" | grep -v tpm | while read -r plugin; do
                echo "    - ${plugin}"
            done
        fi
    else
        log WARN "TPM not installed. Run: git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm"
    fi
}

# ============================================================================
# WezTerm Checks
# ============================================================================

check_wezterm_config() {
    section "WezTerm Configuration"
    
    if ! command -v wezterm &> /dev/null; then
        log WARN "WezTerm not installed"
        return 0
    fi
    
    log PASS "WezTerm installed: $(wezterm --version | head -1)"
    
    if [[ ! -f "${HOME}/.wezterm.lua" ]]; then
        log FAIL "WezTerm config not found"
        return 1
    fi
    
    log PASS "WezTerm config found"
    
    # Check syntax
    if command -v lua &> /dev/null; then
        if lua -l luac -p "${HOME}/.wezterm.lua" 2>> "${DIAGNOSTICS_LOG}"; then
            log PASS "WezTerm Lua configuration valid"
        else
            log FAIL "WezTerm configuration has syntax errors"
        fi
    fi
}

# ============================================================================
# Git Checks
# ============================================================================

check_git_config() {
    section "Git Configuration"
    
    if ! command -v git &> /dev/null; then
        log FAIL "Git not installed"
        return 1
    fi
    
    log PASS "Git installed: $(git --version)"
    
    # Check user config
    local user=$(git config user.name)
    local email=$(git config user.email)
    
    if [[ -z "${user}" ]]; then
        log WARN "Git user.name not configured"
    else
        echo "  Git user: ${user}"
    fi
    
    if [[ -z "${email}" ]]; then
        log WARN "Git user.email not configured"
    else
        echo "  Git email: ${email}"
    fi
    
    # Check for delta
    if command -v delta &> /dev/null; then
        log PASS "Git delta available"
    else
        log WARN "Git delta not installed (optional enhancement)"
    fi
}

check_git_signing() {
    section "Git Signing Configuration"
    
    # Check GPG
    if command -v gpg &> /dev/null; then
        log PASS "GPG available"
        
        local gpg_key=$(git config user.signingkey)
        if [[ -n "${gpg_key}" ]]; then
            echo "  Signing key: ${gpg_key}"
        else
            log WARN "Git signing key not configured"
        fi
    else
        log WARN "GPG not installed (needed for commit signing)"
    fi
    
    # Check SSH key
    if [[ -f "${HOME}/.ssh/id_ed25519" ]] || [[ -f "${HOME}/.ssh/id_rsa" ]]; then
        log PASS "SSH key found"
    else
        log WARN "SSH key not found. Generate with: ssh-keygen -t ed25519"
    fi
}

# ============================================================================
# Symlink Verification
# ============================================================================

check_symlinks() {
    section "Symlink Verification"
    
    local symlinks=(
        "${HOME}/.config/nvim"
        "${HOME}/.tmux.conf"
        "${HOME}/.wezterm.lua"
        "${HOME}/.zshrc"
        "${HOME}/.bashrc"
        "${HOME}/.gitconfig"
    )
    
    for symlink in "${symlinks[@]}"; do
        if [[ ! -L "${symlink}" ]]; then
            log WARN "Not a symlink or missing: ${symlink}"
        else
            local target=$(readlink "${symlink}")
            if [[ ! -e "${target}" ]]; then
                log FAIL "Broken symlink: ${symlink} -> ${target}"
            else
                echo "  ✓ ${symlink} -> $(basename ${target%/*})"
            fi
        fi
    done
}

# ============================================================================
# Conflict Detection
# ============================================================================

check_potential_conflicts() {
    section "Potential Conflicts"
    
    # Check for multiple shell initializations
    local shell_inits=$(grep -l "^# dotfiles" ${HOME}/.bashrc ${HOME}/.zshrc 2>/dev/null | wc -l)
    if [[ ${shell_inits} -gt 1 ]]; then
        log WARN "Multiple shell initialization markers found"
    else
        log PASS "Shell initialization clean"
    fi
    
    # Check for duplicate fzf initialization
    local fzf_inits=$(grep -c "fzf" ${HOME}/.zshrc 2>/dev/null || echo 0)
    if [[ ${fzf_inits} -gt 1 ]]; then
        log WARN "Multiple fzf initializations detected (${fzf_inits})"
    fi
}

# ============================================================================
# Deep Diagnostics
# ============================================================================

check_detailed_lsp() {
    section "Detailed LSP Status"
    
    if ! command -v nvim &> /dev/null; then
        log WARN "Neovim not installed"
        return 0
    fi
    
    local mason_dir="${HOME}/.local/share/nvim/mason/bin"
    if [[ ! -d "${mason_dir}" ]]; then
        log WARN "Mason binaries not found"
        return 0
    fi
    
    echo "  Available LSP binaries:"
    ls -1 "${mason_dir}" 2>/dev/null | grep -E "(clangd|lua_ls|pylsp|rust|gopls)" | while read -r binary; do
        echo "    - ${binary}"
    done
}

check_plugin_status() {
    section "Plugin Status"
    
    # Neovim plugins
    local nvim_plugins="${HOME}/.local/share/nvim/lazy"
    if [[ -d "${nvim_plugins}" ]]; then
        local plugin_count=$(ls -1d "${nvim_plugins}"/*/ 2>/dev/null | wc -l)
        echo "  Neovim plugins installed: ${plugin_count}"
    fi
    
    # Tmux plugins
    local tmux_plugins="${HOME}/.tmux/plugins"
    if [[ -d "${tmux_plugins}" ]]; then
        local plugin_count=$(ls -1d "${tmux_plugins}"/*/ 2>/dev/null | wc -l)
        echo "  Tmux plugins installed: ${plugin_count}"
    fi
}

# ============================================================================
# Report Generation
# ============================================================================

print_summary() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}DIAGNOSTICS SUMMARY${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    echo -e "Checks passed:  ${GREEN}${CHECKS_PASSED}${NC}"
    echo -e "Checks failed:  ${RED}${CHECKS_FAILED}${NC}"
    echo -e "Warnings:       ${YELLOW}${WARNINGS}${NC}"
    echo ""
    echo -e "Log file: ${DIAGNOSTICS_LOG}"
    echo ""
    
    if [[ ${CHECKS_FAILED} -eq 0 ]]; then
        echo -e "${GREEN}✓ System appears to be healthy${NC}"
    else
        echo -e "${RED}✗ Some issues detected - review log${NC}"
        return 1
    fi
    
    echo ""
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --quick)
                QUICK_MODE=true
                shift
                ;;
            --deep)
                DEEP_MODE=true
                shift
                ;;
            --profile)
                PROFILE_MODE=true
                shift
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            *)
                shift
                ;;
        esac
    done
}

main() {
    parse_args "$@"
    
    echo -e "${BLUE}Dotfiles Diagnostics${NC}"
    echo -e "Log: ${DIAGNOSTICS_LOG}"
    echo ""
    
    check_system_info
    check_core_commands
    check_shell_syntax
    check_shell_startup
    check_path_duplicates
    
    check_nvim_config
    check_nvim_lsp
    check_nvim_health
    
    check_tmux_config
    check_tmux_plugins
    
    check_wezterm_config
    
    check_git_config
    check_git_signing
    
    check_symlinks
    check_potential_conflicts
    
    if [[ ${DEEP_MODE} == true ]]; then
        check_detailed_lsp
        check_plugin_status
    fi
    
    print_summary
}

main "$@"
