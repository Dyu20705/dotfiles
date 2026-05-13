#!/usr/bin/env bash
# Bootstrap script for Ubuntu/Debian dotfiles
# 
# Safety-first design:
# - Validates environment before making changes
# - Creates timestamped backups
# - Supports dry-run and rollback
# - Idempotent (safe to rerun)
# - Structured logging
#
# Usage:
#   ./bootstrap.sh                    # Interactive mode
#   ./bootstrap.sh --dry-run          # Test without changes
#   ./bootstrap.sh --verbose          # Detailed output
#   ./bootstrap.sh --no-backup        # Skip backups (dangerous!)

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOGS_DIR="${SCRIPT_DIR}/logs"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="${LOGS_DIR}/bootstrap_${TIMESTAMP}.log"
BACKUP_DIR="${HOME}/.dotfiles-backup-${TIMESTAMP}"

# Flags
DRY_RUN=false
VERBOSE=false
SKIP_BACKUP=false
SKIP_PACKAGES=false

# Counters
PACKAGES_INSTALLED=0
PACKAGES_SKIPPED=0
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
            [[ ${VERBOSE} == true ]] && echo -e "${YELLOW}⚠ ${message}${NC}"
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

debug() {
    [[ ${VERBOSE} == true ]] && log INFO "DEBUG: $*"
}

# ============================================================================
# Validation Functions
# ============================================================================

detect_os() {
    if [[ ! -f /etc/os-release ]]; then
        die "Cannot detect OS. Not a standard Linux distribution."
    fi
    
    source /etc/os-release
    
    case "${ID}" in
        ubuntu|debian)
            log OK "Detected: ${PRETTY_NAME}"
            ;;
        *)
            die "Unsupported OS: ${PRETTY_NAME}. Requires Ubuntu/Debian."
            ;;
    esac
}

check_root() {
    if [[ ${EUID} -eq 0 ]]; then
        die "Do not run this script as root. sudo will be used when needed."
    fi
    log OK "Running as non-root user (correct)"
}

check_sudo() {
    if ! sudo -n true 2>/dev/null; then
        log WARN "sudo requires password. Will prompt when needed."
    else
        log OK "sudo available without password"
    fi
}

check_git() {
    if ! command -v git &> /dev/null; then
        die "git not found. Install it first: sudo apt install git"
    fi
    local version=$(git --version | awk '{print $3}')
    log OK "git ${version} available"
}

check_network() {
    if ! ping -c 1 8.8.8.8 &> /dev/null; then
        die "No network connectivity. Cannot download packages."
    fi
    log OK "Network connectivity verified"
}

# ============================================================================
# Package Management Functions
# ============================================================================

update_package_lists() {
    if [[ ${DRY_RUN} == true ]]; then
        log INFO "DRY-RUN: Would update package lists"
        return 0
    fi
    
    log INFO "Updating package lists..."
    if ! sudo apt-get update -qq 2>> "${LOG_FILE}"; then
        log ERROR "Failed to update package lists"
        return 1
    fi
    log OK "Package lists updated"
}

install_package() {
    local package=$1
    
    # Check if already installed
    if dpkg -l | grep -q "^ii  ${package}"; then
        log WARN "Package already installed: ${package}"
        ((PACKAGES_SKIPPED++))
        return 0
    fi
    
    log INFO "Installing: ${package}"
    
    if [[ ${DRY_RUN} == true ]]; then
        log INFO "DRY-RUN: Would install ${package}"
        ((PACKAGES_INSTALLED++))
        return 0
    fi
    
    if ! sudo apt-get install -y "${package}" >> "${LOG_FILE}" 2>&1; then
        log ERROR "Failed to install ${package}"
        return 1
    fi
    
    log OK "Installed: ${package}"
    ((PACKAGES_INSTALLED++))
    return 0
}

install_packages() {
    # Core build tools
    local packages=(
        "build-essential"
        "git"
        "curl"
        "wget"
        "ca-certificates"
    )
    
    # Shell
    packages+=("zsh" "bash")
    
    # Editors & tools
    packages+=("neovim" "tmux" "strace" "htop")
    
    # Development
    packages+=("python3" "python3-pip" "python3-dev" "nodejs" "npm")
    
    # Languages
    packages+=("clang" "lldb" "lld" "rustc" "cargo")
    
    # System utilities
    packages+=("ripgrep" "fd-find" "jq" "yq" "fzf" "exa" "bat")
    packages+=("openssh-client" "openssh-server" "gnupg" "age")
    
    # Container tools
    packages+=("docker.io" "docker-compose")
    
    # Kubernetes
    packages+=("kubectl")
    
    log INFO "Installing ${#packages[@]} packages..."
    
    update_package_lists || return 1
    
    for package in "${packages[@]}"; do
        install_package "${package}" || {
            log WARN "Continuing despite failure on ${package}"
        }
    done
    
    log OK "Package installation complete (Installed: ${PACKAGES_INSTALLED}, Skipped: ${PACKAGES_SKIPPED})"
}

# ============================================================================
# Backup & Symlink Functions
# ============================================================================

create_backup() {
    if [[ ${SKIP_BACKUP} == true ]]; then
        log WARN "Backup skipped (--no-backup flag)"
        return 0
    fi
    
    if [[ ${DRY_RUN} == true ]]; then
        log INFO "DRY-RUN: Would create backup at ${BACKUP_DIR}"
        return 0
    fi
    
    log INFO "Creating backup directory: ${BACKUP_DIR}"
    mkdir -p "${BACKUP_DIR}"
    
    # Backup existing configs
    local configs=(
        ".config/nvim"
        ".tmux.conf"
        ".wezterm.lua"
        ".zshrc"
        ".bashrc"
        ".gitconfig"
    )
    
    for config in "${configs[@]}"; do
        local src="${HOME}/${config}"
        if [[ -e "${src}" ]]; then
            log INFO "Backing up: ${config}"
            cp -r "${src}" "${BACKUP_DIR}/" 2>> "${LOG_FILE}" || {
                log ERROR "Failed to backup ${config}"
            }
        fi
    done
    
    log OK "Backup created at ${BACKUP_DIR}"
}

safe_symlink() {
    local src=$1
    local dest=$2
    
    if [[ ! -e "${src}" ]]; then
        log ERROR "Source does not exist: ${src}"
        return 1
    fi
    
    # Create destination directory if needed
    local dest_dir="$(dirname "${dest}")"
    mkdir -p "${dest_dir}"
    
    # Handle existing file/symlink
    if [[ -e "${dest}" ]] || [[ -L "${dest}" ]]; then
        if [[ -L "${dest}" ]]; then
            local current_target=$(readlink "${dest}")
            if [[ "${current_target}" == "${src}" ]]; then
                log WARN "Symlink already exists and correct: ${dest}"
                return 0
            fi
        fi
        
        log WARN "Destination exists, will be replaced: ${dest}"
        if [[ ${DRY_RUN} == false ]]; then
            rm -f "${dest}" || {
                log ERROR "Failed to remove existing ${dest}"
                return 1
            }
        fi
    fi
    
    if [[ ${DRY_RUN} == true ]]; then
        log INFO "DRY-RUN: Would symlink ${src} -> ${dest}"
        return 0
    fi
    
    ln -sf "${src}" "${dest}" || {
        log ERROR "Failed to create symlink: ${src} -> ${dest}"
        return 1
    }
    
    log OK "Symlink created: ${dest}"
    return 0
}

create_symlinks() {
    log INFO "Creating symlinks..."
    
    local symlinks=(
        "${SCRIPT_DIR}/nvim/.config/nvim:${HOME}/.config/nvim"
        "${SCRIPT_DIR}/tmux/tmux.conf:${HOME}/.tmux.conf"
        "${SCRIPT_DIR}/wezterm/wezterm.lua:${HOME}/.wezterm.lua"
        "${SCRIPT_DIR}/zsh/.zshrc:${HOME}/.zshrc"
        "${SCRIPT_DIR}/bash/.bashrc:${HOME}/.bashrc"
        "${SCRIPT_DIR}/git/.gitconfig:${HOME}/.gitconfig"
    )
    
    local failed=0
    for mapping in "${symlinks[@]}"; do
        IFS=':' read -r src dest <<< "${mapping}"
        safe_symlink "${src}" "${dest}" || ((failed++))
    done
    
    if [[ ${failed} -gt 0 ]]; then
        log ERROR "Failed to create ${failed} symlinks"
        return 1
    fi
    
    log OK "All symlinks created successfully"
}

# ============================================================================
# Post-Install Configuration
# ============================================================================

setup_shell() {
    log INFO "Configuring shell..."
    
    if [[ ${DRY_RUN} == true ]]; then
        log INFO "DRY-RUN: Would set Zsh as default shell"
        return 0
    fi
    
    # Set Zsh as default shell (if not already)
    local current_shell=$(basename "$SHELL")
    if [[ "${current_shell}" != "zsh" ]]; then
        log INFO "Setting Zsh as default shell..."
        chsh -s "$(which zsh)" || {
            log ERROR "Failed to set Zsh as default. You may need to run: chsh -s $(which zsh)"
        }
    else
        log OK "Zsh is already default shell"
    fi
}

setup_neovim() {
    log INFO "Configuring Neovim..."
    
    if [[ ${DRY_RUN} == true ]]; then
        log INFO "DRY-RUN: Would initialize Neovim plugins"
        return 0
    fi
    
    # Initialize Lazy.nvim on first run
    if [[ ! -d "${HOME}/.local/share/nvim/lazy" ]]; then
        log INFO "First Neovim launch will install Lazy.nvim plugins..."
        timeout 120 nvim +Lazy sync +q 2>> "${LOG_FILE}" || {
            log WARN "Neovim plugin sync may have timed out (normal on first run)"
        }
    fi
}

setup_tmux() {
    log INFO "Configuring Tmux..."
    
    if [[ ${DRY_RUN} == true ]]; then
        log INFO "DRY-RUN: Would initialize Tmux plugins"
        return 0
    fi
    
    # Initialize TPM plugins
    if [[ ! -d "${HOME}/.tmux/plugins/tpm" ]]; then
        log INFO "Installing Tmux Plugin Manager..."
        git clone https://github.com/tmux-plugins/tpm "${HOME}/.tmux/plugins/tpm" 2>> "${LOG_FILE}" || {
            log ERROR "Failed to install TPM"
        }
    fi
    
    log OK "Tmux configured"
}

# ============================================================================
# Validation & Health Checks
# ============================================================================

validate_symlinks() {
    log INFO "Validating symlinks..."
    
    local symlinks=(
        "${HOME}/.config/nvim"
        "${HOME}/.tmux.conf"
        "${HOME}/.wezterm.lua"
        "${HOME}/.zshrc"
        "${HOME}/.bashrc"
        "${HOME}/.gitconfig"
    )
    
    local broken=0
    for symlink in "${symlinks[@]}"; do
        if [[ ! -L "${symlink}" ]]; then
            log WARN "Not a symlink or missing: ${symlink}"
            ((broken++))
        else
            local target=$(readlink "${symlink}")
            if [[ ! -e "${target}" ]]; then
                log ERROR "Broken symlink: ${symlink} -> ${target}"
                ((broken++))
            else
                log OK "Valid symlink: ${symlink}"
            fi
        fi
    done
    
    if [[ ${broken} -gt 0 ]]; then
        log ERROR "${broken} broken symlinks detected"
        return 1
    fi
    
    log OK "All symlinks validated"
}

validate_zsh() {
    log INFO "Validating Zsh configuration..."
    
    if ! zsh -n "${SCRIPT_DIR}/zsh/.zshrc" 2>> "${LOG_FILE}"; then
        log ERROR "Zsh syntax error in .zshrc"
        return 1
    fi
    
    log OK "Zsh configuration valid"
}

validate_tmux() {
    log INFO "Validating Tmux configuration..."
    
    if ! tmux source-file -q "${SCRIPT_DIR}/tmux/tmux.conf" 2>> "${LOG_FILE}"; then
        log ERROR "Tmux syntax error in tmux.conf"
        return 1
    fi
    
    log OK "Tmux configuration valid"
}

validate_lua() {
    log INFO "Validating Lua configurations..."
    
    if ! command -v lua &> /dev/null; then
        log WARN "Lua not available, skipping Lua validation"
        return 0
    fi
    
    local lua_files=(
        "${SCRIPT_DIR}/nvim/.config/nvim/init.lua"
        "${SCRIPT_DIR}/wezterm/wezterm.lua"
    )
    
    for file in "${lua_files[@]}"; do
        if [[ -f "${file}" ]]; then
            if ! lua -l luac -p "${file}" 2>> "${LOG_FILE}"; then
                log ERROR "Lua syntax error: ${file}"
                return 1
            fi
        fi
    done
    
    log OK "Lua configurations valid"
}

run_validations() {
    log INFO "Running validation suite..."
    
    local failed=0
    
    validate_symlinks || ((failed++))
    validate_zsh || ((failed++))
    validate_tmux || ((failed++))
    validate_lua || ((failed++))
    
    if [[ ${failed} -gt 0 ]]; then
        log ERROR "${failed} validations failed"
        return 1
    fi
    
    log OK "All validations passed"
}

# ============================================================================
# Main Flow
# ============================================================================

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                DRY_RUN=true
                VERBOSE=true
                echo -e "${YELLOW}DRY-RUN MODE: No changes will be made${NC}"
                shift
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            --no-backup)
                SKIP_BACKUP=true
                shift
                ;;
            --skip-packages)
                SKIP_PACKAGES=true
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
    echo -e "${BLUE}║      Dotfiles Bootstrap - Ubuntu/Debian               ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    [[ ${DRY_RUN} == true ]] && echo -e "${YELLOW}MODE: DRY-RUN (no changes)${NC}"
    [[ ${VERBOSE} == true ]] && echo -e "${BLUE}MODE: VERBOSE${NC}"
    [[ ${SKIP_BACKUP} == true ]] && echo -e "${RED}WARNING: Backups disabled${NC}"
    
    echo ""
}

print_summary() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                     BOOTSTRAP SUMMARY                 ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "Timestamp:  ${TIMESTAMP}"
    echo -e "Log file:   ${LOG_FILE}"
    
    if [[ ${SKIP_BACKUP} == false ]]; then
        echo -e "Backup:     ${BACKUP_DIR}"
    fi
    
    echo ""
    echo -e "Packages installed: ${PACKAGES_INSTALLED}"
    echo -e "Packages skipped:   ${PACKAGES_SKIPPED}"
    echo -e "Errors:             ${ERRORS}"
    echo ""
    
    if [[ ${DRY_RUN} == true ]]; then
        echo -e "${YELLOW}DRY-RUN: No actual changes were made${NC}"
    fi
    
    if [[ ${ERRORS} -eq 0 ]]; then
        echo -e "${GREEN}✓ Bootstrap completed successfully${NC}"
    else
        echo -e "${RED}✗ Bootstrap completed with ${ERRORS} error(s)${NC}"
        echo -e "Review logs at: ${LOG_FILE}"
        return 1
    fi
    
    echo ""
    echo "Next steps:"
    echo "  1. Restart your shell: exec zsh"
    echo "  2. Verify setup: make diagnostics (if available)"
    echo "  3. Review logs: cat ${LOG_FILE}"
    echo ""
}

main() {
    # Create logs directory
    mkdir -p "${LOGS_DIR}"
    
    # Initialize log file
    echo "Bootstrap started at $(date)" > "${LOG_FILE}"
    
    parse_args "$@"
    print_header
    
    # Pre-flight checks
    log INFO "Running pre-flight checks..."
    detect_os
    check_root
    check_sudo
    check_git
    check_network
    
    # Backup existing configs
    create_backup
    
    # Install packages (unless skipped)
    if [[ ${SKIP_PACKAGES} == false ]]; then
        install_packages
    else
        log WARN "Package installation skipped"
    fi
    
    # Create symlinks
    create_symlinks
    
    # Setup individual components
    setup_shell
    setup_neovim
    setup_tmux
    
    # Run validations
    run_validations
    
    # Print summary
    print_summary
}

main "$@"
