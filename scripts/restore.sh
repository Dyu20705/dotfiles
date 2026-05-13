#!/usr/bin/env bash
# Restore script - Rollback symlinks and restore backups
#
# This script:
# - Restores files from timestamped backups
# - Removes symlinks created by install.sh
# - Recovers previous state safely
# - Supports dry-run mode
#
# Usage:
#   ./restore.sh [timestamp]           # List available restores or pick specific one
#   ./restore.sh --list                # List all available restores
#   ./restore.sh --restore 20260513_120000   # Restore specific backup
#   ./restore.sh --dry-run [timestamp]  # Test restore without changes
#   ./restore.sh --force [timestamp]    # Skip confirmation

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

HOME_DIR="${HOME}"
BACKUP_BASE="${HOME}/.dotfiles-backup-"
LINK_BASE="${HOME}/.dotfiles-links-"
LOGS_DIR="$(pwd)/logs"
LOG_FILE="${LOGS_DIR}/restore_$(date +%Y%m%d_%H%M%S).log"

DRY_RUN=false
FORCE=false
VERBOSE=false
RESTORE_TIMESTAMP=""

RESTORED=0
REMOVED=0
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
# Discovery Functions
# ============================================================================

list_backups() {
    echo ""
    echo -e "${BLUE}Available backups:${NC}"
    echo ""
    
    local backups=()
    if compgen -G "${BACKUP_BASE}*" > /dev/null; then
        for backup in ${BACKUP_BASE}*; do
            if [[ -d "${backup}" ]]; then
                local timestamp=$(basename "${backup}" | sed "s/^${BACKUP_BASE//./\\.}//")
                backups+=("${timestamp}")
                echo "  ${timestamp}"
            fi
        done
    else
        echo "  (no backups found)"
    fi
    
    echo ""
    return ${#backups[@]}
}

list_registries() {
    echo ""
    echo -e "${BLUE}Available link registries:${NC}"
    echo ""
    
    local registries=()
    if compgen -G "${LINK_BASE}*" > /dev/null; then
        for registry in ${LINK_BASE}*; do
            if [[ -f "${registry}" ]]; then
                local timestamp=$(basename "${registry}" | sed "s/^${LINK_BASE//./\\.}//")
                registries+=("${timestamp}")
                echo "  ${timestamp}"
            fi
        done
    else
        echo "  (no link registries found)"
    fi
    
    echo ""
    return ${#registries[@]}
}

find_latest_backup() {
    local latest=""
    if compgen -G "${BACKUP_BASE}*" > /dev/null; then
        latest=$(ls -td ${BACKUP_BASE}* | head -1 | xargs basename)
        latest=${latest#${BACKUP_BASE}}
        echo "${latest}"
    fi
}

# ============================================================================
# Restore Functions
# ============================================================================

restore_backup() {
    local timestamp=$1
    local backup_dir="${BACKUP_BASE}${timestamp}"
    
    if [[ ! -d "${backup_dir}" ]]; then
        log ERROR "Backup not found: ${backup_dir}"
        return 1
    fi
    
    log INFO "Restoring from backup: ${timestamp}"
    log INFO "Source: ${backup_dir}"
    
    if [[ ${DRY_RUN} == true ]]; then
        log INFO "DRY-RUN: Would restore files from ${backup_dir}"
        return 0
    fi
    
    # Restore each file
    while IFS= read -r -d '' src; do
        local rel_path="${src#${backup_dir}/}"
        local dest="${HOME_DIR}/${rel_path}"
        
        # Create destination directory
        mkdir -p "$(dirname "${dest}")"
        
        # Remove existing symlink/file if it's from dotfiles
        if [[ -L "${dest}" ]]; then
            local target=$(readlink "${dest}")
            if [[ "${target}" == *"dotfiles"* ]]; then
                rm -f "${dest}"
                log OK "Removed symlink: ${dest}"
            fi
        fi
        
        # Restore backup
        if cp -r "${src}" "${dest}"; then
            log OK "Restored: ${rel_path}"
            ((RESTORED++))
        else
            log ERROR "Failed to restore: ${rel_path}"
            ((ERRORS++))
        fi
    done < <(find "${backup_dir}" -type f -print0)
}

remove_symlinks() {
    local registry=$1
    
    if [[ ! -f "${registry}" ]]; then
        log WARN "Registry not found: ${registry}"
        return 0
    fi
    
    log INFO "Removing symlinks from registry: ${registry}"
    
    if [[ ${DRY_RUN} == true ]]; then
        log INFO "DRY-RUN: Would process registry ${registry}"
        return 0
    fi
    
    # Read registry and remove symlinks (reverse order)
    local lines=()
    while IFS='|' read -r src dest action; do
        # Skip comments
        [[ "${src}" == "#"* ]] && continue
        [[ -z "${src}" ]] && continue
        
        lines+=("${src}|${dest}|${action}")
    done < "${registry}"
    
    # Process in reverse order
    for ((i=${#lines[@]}-1; i>=0; i--)); do
        IFS='|' read -r src dest action <<< "${lines[$i]}"
        
        if [[ "${action}" == "created" ]] || [[ "${action}" == "would-create" ]]; then
            if [[ -L "${dest}" ]]; then
                rm -f "${dest}"
                log OK "Removed symlink: ${dest}"
                ((REMOVED++))
            fi
        fi
    done
}

# ============================================================================
# Validation
# ============================================================================

validate_restore() {
    log INFO "Validating restore..."
    
    local critical_files=(
        "${HOME}/.config"
        "${HOME}/.tmux.conf"
        "${HOME}/.zshrc"
        "${HOME}/.bashrc"
    )
    
    local broken=0
    for file in "${critical_files[@]}"; do
        if [[ ! -e "${file}" ]] && [[ ! -L "${file}" ]]; then
            log WARN "File not found: ${file}"
        else
            log OK "File available: ${file}"
        fi
    done
    
    log OK "Validation complete"
}

# ============================================================================
# Main
# ============================================================================

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --list)
                list_backups
                list_registries
                exit 0
                ;;
            --dry-run)
                DRY_RUN=true
                VERBOSE=true
                shift
                RESTORE_TIMESTAMP=$1
                ;;
            --force)
                FORCE=true
                shift
                RESTORE_TIMESTAMP=$1
                ;;
            --restore)
                shift
                RESTORE_TIMESTAMP=$1
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            *)
                RESTORE_TIMESTAMP=$1
                shift
                ;;
        esac
    done
}

print_header() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║            Dotfiles Restore - Recovery Tool            ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_summary() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                    RESTORE SUMMARY                     ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "Timestamp: $(date)"
    echo -e "Log file:  ${LOG_FILE}"
    echo ""
    echo -e "Files restored: ${RESTORED}"
    echo -e "Symlinks removed: ${REMOVED}"
    echo -e "Errors: ${ERRORS}"
    echo ""
    
    if [[ ${DRY_RUN} == true ]]; then
        echo -e "${YELLOW}DRY-RUN: No actual changes were made${NC}"
    fi
    
    if [[ ${ERRORS} -eq 0 ]]; then
        echo -e "${GREEN}✓ Restore completed successfully${NC}"
    else
        echo -e "${RED}✗ Restore completed with ${ERRORS} error(s)${NC}"
        return 1
    fi
    
    echo ""
}

main() {
    mkdir -p "${LOGS_DIR}"
    echo "Restore started at $(date)" > "${LOG_FILE}"
    
    parse_args "$@"
    print_header
    
    # If no timestamp specified, find latest
    if [[ -z "${RESTORE_TIMESTAMP}" ]]; then
        log INFO "No timestamp specified, finding latest backup..."
        RESTORE_TIMESTAMP=$(find_latest_backup)
        
        if [[ -z "${RESTORE_TIMESTAMP}" ]]; then
            log ERROR "No backups found"
            list_backups
            exit 1
        fi
        
        log OK "Found latest backup: ${RESTORE_TIMESTAMP}"
    fi
    
    # Confirm before proceeding
    if ! prompt_yn "Restore from ${RESTORE_TIMESTAMP}?"; then
        log INFO "Restore cancelled"
        exit 0
    fi
    
    # Restore files
    restore_backup "${RESTORE_TIMESTAMP}"
    
    # Remove symlinks
    remove_symlinks "${LINK_BASE}${RESTORE_TIMESTAMP}"
    
    # Validate
    validate_restore
    
    print_summary
}

main "$@"
