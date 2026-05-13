#!/usr/bin/env bash
# Startup performance profiler - Measure and analyze startup times
#
# This script:
# - Profiles shell startup time
# - Profiles Neovim startup time
# - Detects slow-loading plugins
# - Identifies performance bottlenecks
#
# Usage:
#   ./scripts/diagnostics/profile-startup.sh
#   ./scripts/diagnostics/profile-startup.sh --nvim-only
#   ./scripts/diagnostics/profile-startup.sh --deep

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILES_LOG="${SCRIPT_DIR}/../../logs/profile-$(date +%Y%m%d_%H%M%S).log"
SAMPLES=5

DEEP_MODE=false
NVIM_ONLY=false
SHELL_ONLY=false

mkdir -p "$(dirname "${PROFILES_LOG}")"

log() {
    echo "$*" | tee -a "${PROFILES_LOG}"
}

section() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}" | tee -a "${PROFILES_LOG}"
    echo -e "${CYAN}${1}${NC}" | tee -a "${PROFILES_LOG}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}" | tee -a "${PROFILES_LOG}"
}

# ============================================================================
# Shell Profiling
# ============================================================================

profile_shell() {
    section "Shell Startup Profiling (${SAMPLES} samples)"
    
    # Zsh
    if command -v zsh &> /dev/null; then
        log ""
        log "Zsh Startup Times:"
        local times=()
        
        for ((i=1; i<=SAMPLES; i++)); do
            local time_ms=$( { time zsh -i -c exit 2>&1; } | grep real | awk '{print $2}' | tr -d 'm' | tr 's' '000' | awk -F'.' '{print $1}')
            times+=("${time_ms}")
            log "  Sample $i: ${times[-1]} ms"
        done
        
        # Calculate average
        local sum=0
        for t in "${times[@]}"; do
            sum=$((sum + t))
        done
        local avg=$((sum / SAMPLES))
        log -e "  ${GREEN}Average: ${avg} ms${NC}"
    fi
    
    # Bash
    if command -v bash &> /dev/null; then
        log ""
        log "Bash Startup Times:"
        local times=()
        
        for ((i=1; i<=SAMPLES; i++)); do
            local time_ms=$( { time bash -i -c exit 2>&1; } | grep real | awk '{print $2}' | tr -d 'm' | tr 's' '000' | awk -F'.' '{print $1}')
            times+=("${time_ms}")
            log "  Sample $i: ${times[-1]} ms"
        done
        
        local sum=0
        for t in "${times[@]}"; do
            sum=$((sum + t))
        done
        local avg=$((sum / SAMPLES))
        log -e "  ${GREEN}Average: ${avg} ms${NC}"
    fi
}

# ============================================================================
# Neovim Profiling
# ============================================================================

profile_nvim() {
    section "Neovim Startup Profiling (${SAMPLES} samples)"
    
    if ! command -v nvim &> /dev/null; then
        log "${RED}Neovim not installed${NC}"
        return 1
    fi
    
    log ""
    log "Neovim Startup Times (cold start):"
    local times=()
    
    for ((i=1; i<=SAMPLES; i++)); do
        local time_ms=$( { time nvim --noplugin +q 2>&1; } | grep real | awk '{print $2}' | tr -d 'm' | tr 's' '000' | awk -F'.' '{print $1}')
        times+=("${time_ms}")
        log "  Sample $i: ${times[-1]} ms"
    done
    
    local sum=0
    for t in "${times[@]}"; do
        sum=$((sum + t))
    done
    local avg=$((sum / SAMPLES))
    log -e "  ${GREEN}Average: ${avg} ms${NC}"
    
    # With plugins
    log ""
    log "Neovim Startup Times (with plugins):"
    times=()
    
    for ((i=1; i<=SAMPLES; i++)); do
        local time_ms=$( { time nvim +q 2>&1; } | grep real | awk '{print $2}' | tr -d 'm' | tr 's' '000' | awk -F'.' '{print $1}')
        times+=("${time_ms}")
        log "  Sample $i: ${times[-1]} ms"
    done
    
    sum=0
    for t in "${times[@]}"; do
        sum=$((sum + t))
    done
    avg=$((sum / SAMPLES))
    log -e "  ${GREEN}Average: ${avg} ms${NC}"
}

# ============================================================================
# Detailed Analysis
# ============================================================================

profile_nvim_plugins() {
    section "Neovim Plugin Load Times (Deep Analysis)"
    
    if ! command -v nvim &> /dev/null; then
        log "${YELLOW}Neovim not installed${NC}"
        return 0
    fi
    
    # Use Neovim's startup profiler
    log ""
    log "Generating Neovim startup profile..."
    
    nvim --startuptime /tmp/nvim-startup.log +q 2>/dev/null || true
    
    if [[ -f /tmp/nvim-startup.log ]]; then
        log ""
        log "Top 10 slowest plugins:"
        tail -n +2 /tmp/nvim-startup.log | sort -k3 -rn | head -10 | while read -r line; do
            log "  ${line}"
        done
        
        log ""
        local total=$(tail -1 /tmp/nvim-startup.log | awk '{print $1}')
        log "Total startup time: ${YELLOW}${total} ms${NC}"
        
        rm -f /tmp/nvim-startup.log
    fi
}

# ============================================================================
# Main
# ============================================================================

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --deep)
                DEEP_MODE=true
                shift
                ;;
            --nvim-only)
                NVIM_ONLY=true
                shift
                ;;
            --shell-only)
                SHELL_ONLY=true
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
    
    log "${BLUE}Startup Performance Profiler${NC}"
    log "Log: ${PROFILES_LOG}"
    log "Samples per test: ${SAMPLES}"
    log ""
    
    if [[ ${SHELL_ONLY} == false ]]; then
        profile_nvim
    fi
    
    if [[ ${NVIM_ONLY} == false ]]; then
        profile_shell
    fi
    
    if [[ ${DEEP_MODE} == true ]]; then
        profile_nvim_plugins
    fi
    
    log ""
    log -e "${GREEN}Profiling complete${NC}"
    log "Results saved to: ${PROFILES_LOG}"
}

main "$@"
