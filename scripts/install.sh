#!/usr/bin/env bash
# Install script - Safe symlink creation with rollback capability
#
# This script:
# - Creates symlinks from dotfiles to $HOME
# - Detects and backs up existing files
# - Never silently overwrites
# - Supports dry-run mode
# - Maintains a link registry for rollback
#
# Usage:
#   ./install.sh                      # Interactive
#   ./install.sh --force              # Skip confirmation
#   ./install.sh --dry-run            # Test without changes
#   ./install.sh --verbose            # Detailed output
#   ./install.sh --register-only      # Create registry only

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="${HOME}/.dotfiles-backup-${TIMESTAMP}"
LINK_REGISTRY="${HOME}/.dotfiles-links-${TIMESTAMP}"
LOGS_DIR="${SCRIPT_DIR}/logs"
LOG_FILE="${LOGS_DIR}/install_${TIMESTAMP}.log"

DRY_RUN=false
FORCE=false
VERBOSE=false
REGISTER_ONLY=false
ERRORS=0

# ============================================================================
# Utility Functions
# ============================================================================

log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] [${level}] ${message}" >> "${LOG_FILE}"
    
    case $level in
        ERROR)
            echo -e "${RED}✗ ${message}${NC}" >&2
            ((ERRORS++))
            ;;
        WARN)
            echo -e "${YELLOW}⚠ ${message}${NC}"
            ;;
        INFO)
            [[ ${VERBOSE} == true ]] && echo -e "${BLUE}ℹ ${message}${NC}"
            ;;
        OK)
            echo -e "${GREEN}✓ ${message}${NC}"
            ;;
    esac
}

die() {
    log ERROR "$*"
    exit 1
}

prompt_yn() {
    local question=$1
    [[ ${FORCE} == true ]] && return 0
    
    echo -ne "${YELLOW}${question} (y/n)${NC} "
    read -r response
    [[ "${response}" == "y" ]] || [[ "${response}" == "Y" ]]
}

# ============================================================================
# Registry Functions (for rollback capability)
# ============================================================================

register_link() {
    local src=$1
    local dest=$2
    local action=$3  # "create", "replace", "broken"
    
    echo "${src}|${dest}|${action}" >> "${LINK_REGISTRY}"
    log INFO "Registered: ${action} ${dest}"
}

save_registry() {
    if [[ ${DRY_RUN} == true ]]; then
        log INFO "DRY-RUN: Would save registry to ${LINK_REGISTRY}"
        return 0
    fi
    
    log OK "Link registry saved: ${LINK_REGISTRY}"
    echo "# Dotfiles link registry - $(date)" > "${LINK_REGISTRY}.header"
    echo "# Timestamp: ${TIMESTAMP}" >> "${LINK_REGISTRY}.header"
    echo "# Format: source|destination|action" >> "${LINK_REGISTRY}.header"
    cat "${LINK_REGISTRY}.header" "${LINK_REGISTRY}" > "${LINK_REGISTRY}.final" 2>/dev/null || true
    mv "${LINK_REGISTRY}.final" "${LINK_REGISTRY}" 2>/dev/null || true
}

# ============================================================================
# Symlink Management
# ============================================================================

check_symlink_target() {
    local src=$1
    
    if [[ ! -e "${src}" ]]; then
        log ERROR "Source does not exist: ${src}"
        return 1
    fi
    
    if [[ ! -r "${src}" ]]; then
        log ERROR "Source not readable: ${src}"
        return 1
    fi
    
    return 0
}

detect_conflicts() {
    local src=$1
    local dest=$2
    
    # No conflict if dest doesn't exist
    if [[ ! -e "${dest}" ]] && [[ ! -L "${dest}" ]]; then
        return 0
    fi
    
    # Check if it's already a symlink to the right place
    if [[ -L "${dest}" ]]; then
        local current=$(readlink "${dest}")
        if [[ "${current}" == "${src}" ]]; then
            log WARN "Already linked correctly: ${dest}"
            return 2  # Not a conflict, but don't overwrite
        fi
    fi
    
    # Conflict detected
    return 1
}

backup_file() {
    local file=$1
    
    if [[ ! -e "${file}" ]] && [[ ! -L "${file}" ]]; then
        return 0
    fi
    
    if [[ ${DRY_RUN} == true ]]; then
        log INFO "DRY-RUN: Would backup ${file}"
        return 0
    fi
    
    mkdir -p "${BACKUP_DIR}"
    
    local rel_path="${file#${HOME}/}"
    local backup_path="${BACKUP_DIR}/${rel_path}"
    mkdir -p "$(dirname "${backup_path}")"
    
    if cp -r "${file}" "${backup_path}" 2>> "${LOG_FILE}"; then
        log OK "Backed up: ${file} -> ${backup_path}"
        return 0
    else
        log ERROR "Failed to backup: ${file}"
        return 1
    fi
}

create_symlink() {
    local src=$1
    local dest=$2
    
    log INFO "Processing: ${dest}"
    
    # Verify source
    check_symlink_target "${src}" || return 1
    
    # Create destination directory
    local dest_dir="$(dirname "${dest}")"
    if [[ ! -d "${dest_dir}" ]]; then
        if [[ ${DRY_RUN} == true ]]; then
            log INFO "DRY-RUN: Would create directory ${dest_dir}"
        else
            mkdir -p "${dest_dir}" || {
                log ERROR "Failed to create directory: ${dest_dir}"
                return 1
            }
        fi
    fi
    
    # Check for conflicts
    if ! detect_conflicts "${src}" "${dest}"; then
        log WARN "Conflict detected: ${dest}"
        
        if ! prompt_yn "Overwrite ${dest}?"; then
            log WARN "Skipped: ${dest}"
            return 0
        fi
        
        if ! backup_file "${dest}"; then
            log ERROR "Failed to backup conflicting file, aborting: ${dest}"
            return 1
        fi
    elif [[ $? -eq 2 ]]; then
        # Already linked correctly, nothing to do
        register_link "${src}" "${dest}" "already-linked"
        return 0
    fi
    
    # Remove existing destination
    if [[ -e "${dest}" ]] || [[ -L "${dest}" ]]; then
        if [[ ${DRY_RUN} == true ]]; then
            log INFO "DRY-RUN: Would remove ${dest}"
        else
            rm -f "${dest}" || {
                log ERROR "Failed to remove existing ${dest}"
                return 1
            }
        fi
    fi
    
    # Create symlink
    if [[ ${DRY_RUN} == true ]]; then
        log INFO "DRY-RUN: Would symlink ${src} -> ${dest}"
        register_link "${src}" "${dest}" "would-create"
    else
        if ! ln -sf "${src}" "${dest}"; then
            log ERROR "Failed to create symlink: ${src} -> ${dest}"
            return 1
        fi
        
        # Verify symlink
        if [[ ! -L "${dest}" ]]; then
            log ERROR "Symlink verification failed: ${dest}"
            return 1
        fi
        
        local target=$(readlink "${dest}")
        if [[ "${target}" != "${src}" ]]; then
            log ERROR "Symlink target mismatch: expected ${src}, got ${target}"
            return 1
        fi
        
        log OK "Created symlink: ${dest}"
        register_link "${src}" "${dest}" "created"
    fi
    
    return 0
}

# ============================================================================
# Installation Procedures
# ============================================================================

install_nvim() {
    log INFO "Installing Neovim configuration..."
    create_symlink "${SCRIPT_DIR}/nvim/.config/nvim" "${HOME}/.config/nvim" || return 1
}

install_tmux() {
    log INFO "Installing Tmux configuration..."
    
    # Handle both tmux.conf and .tmux.conf naming
    if [[ -f "${SCRIPT_DIR}/tmux/tmux.conf" ]]; then
        create_symlink "${SCRIPT_DIR}/tmux/tmux.conf" "${HOME}/.tmux.conf" || return 1
    elif [[ -f "${SCRIPT_DIR}/tmux/.tmux.conf" ]]; then
        create_symlink "${SCRIPT_DIR}/tmux/.tmux.conf" "${HOME}/.tmux.conf" || return 1
    else
        log WARN "Tmux config not found"
    fi
}

install_wezterm() {
    log INFO "Installing WezTerm configuration..."
    create_symlink "${SCRIPT_DIR}/wezterm/wezterm.lua" "${HOME}/.wezterm.lua" || return 1
}

install_zsh() {
    log INFO "Installing Zsh configuration..."
    create_symlink "${SCRIPT_DIR}/zsh/.zshrc" "${HOME}/.zshrc" || return 1
}

install_bash() {
    log INFO "Installing Bash configuration..."
    create_symlink "${SCRIPT_DIR}/bash/.bashrc" "${HOME}/.bashrc" || return 1
}

install_git() {
    log INFO "Installing Git configuration..."
    create_symlink "${SCRIPT_DIR}/git/.gitconfig" "${HOME}/.gitconfig" || return 1
}

install_all() {
    local failed=0
    
    install_nvim || ((failed++))
    install_tmux || ((failed++))
    install_wezterm || ((failed++))
    install_zsh || ((failed++))
    install_bash || ((failed++))
    install_git || ((failed++))
    
    if [[ ${failed} -gt 0 ]]; then
        log ERROR "${failed} installations failed"
        return 1
    fi
    
    log OK "All installations completed"
    return 0
}

# ============================================================================
# Validation
# ============================================================================

validate_installation() {
    log INFO "Validating installation..."
    
    local symlinks=(
        "${HOME}/.config/nvim"
        "${HOME}/.tmux.conf"
        "${HOME}/.wezterm.lua"
        "${HOME}/.zshrc"
        "${HOME}/.bashrc"
        "${HOME}/.gitconfig"
    )
    
    local failed=0
    for symlink in "${symlinks[@]}"; do
        if [[ ! -L "${symlink}" ]]; then
            log WARN "Not a symlink: ${symlink}"
        else
            local target=$(readlink "${symlink}")
            if [[ ! -e "${target}" ]]; then
                log ERROR "Broken symlink: ${symlink} -> ${target}"
                ((failed++))
            else
                log OK "Valid symlink: ${symlink}"
            fi
        fi
    done
    
    if [[ ${failed} -gt 0 ]]; then
        log ERROR "${failed} validation(s) failed"
        return 1
    fi
    
    log OK "All symlinks validated"
    return 0
}

# ============================================================================
# Main
# ============================================================================

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                DRY_RUN=true
                VERBOSE=true
                echo -e "${YELLOW}DRY-RUN MODE${NC}"
                shift
                ;;
            --force)
                FORCE=true
                shift
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            --register-only)
                REGISTER_ONLY=true
                shift
                ;;
            *)
                die "Unknown option: $1"
                ;;
        esac
    done
}

print_header() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║         Dotfiles Install - Symlink Creator             ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_summary() {
    echo ""
    echo -e "${BLUE}Installation Complete${NC}"
    echo -e "Timestamp: ${TIMESTAMP}"
    echo -e "Log file:  ${LOG_FILE}"
    
    if [[ ! ${SKIP_BACKUP} == true ]]; then
        if [[ -d "${BACKUP_DIR}" ]]; then
            echo -e "Backup:    ${BACKUP_DIR}"
        fi
    fi
    
    echo -e "Registry:  ${LINK_REGISTRY}"
    echo ""
    
    if [[ ${ERRORS} -eq 0 ]]; then
        echo -e "${GREEN}✓ Installation successful${NC}"
    else
        echo -e "${RED}✗ Installation completed with ${ERRORS} error(s)${NC}"
        return 1
    fi
    
    echo ""
}

main() {
    mkdir -p "${LOGS_DIR}"
    echo "Install started at $(date)" > "${LOG_FILE}"
    
    parse_args "$@"
    print_header
    
    if [[ ${REGISTER_ONLY} == true ]]; then
        log INFO "Registry-only mode"
        install_all
    else
        install_all
        validate_installation
    fi
    
    save_registry
    print_summary
}

main "$@"
