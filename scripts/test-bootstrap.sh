#!/usr/bin/env bash
# Docker-based validation harness
# Tests bootstrap in isolated fresh Ubuntu environment
#
# Validates:
# - Fresh install works completely
# - Idempotency (safe re-runs)
# - Rollback procedures
# - Edge case handling
# - Performance benchmarks
#
# Usage:
#   ./test-bootstrap.sh                    # Run all tests
#   ./test-bootstrap.sh --test-fresh       # Fresh install only
#   ./test-bootstrap.sh --test-idempotency # Re-run testing
#   ./test-bootstrap.sh --test-rollback    # Rollback testing
#   ./test-bootstrap.sh --keep-container   # Keep container for inspection

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPORTS_DIR="${SCRIPT_DIR}/test-reports"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORT_FILE="${REPORTS_DIR}/validation_${TIMESTAMP}.md"

# Test configuration
IMAGE_NAME="ubuntu:22.04"
CONTAINER_NAME="dotfiles-test-${TIMESTAMP}"
KEEP_CONTAINER=false
VERBOSE=false

# Test flags
TEST_FRESH=true
TEST_IDEMPOTENCY=true
TEST_ROLLBACK=true
TEST_EDGE_CASES=true
TEST_CONFLICTS=false

# Results
TESTS_PASSED=0
TESTS_FAILED=0
ISSUES_FOUND=()

# ============================================================================
# Utilities
# ============================================================================

log() {
    local level=$1
    shift
    local message="$*"
    
    case $level in
        PASS)
            echo -e "${GREEN}✓ ${message}${NC}"
            ((TESTS_PASSED++))
            ;;
        FAIL)
            echo -e "${RED}✗ ${message}${NC}"
            ((TESTS_FAILED++))
            ISSUES_FOUND+=("${message}")
            ;;
        WARN)
            echo -e "${YELLOW}⚠ ${message}${NC}"
            ;;
        INFO)
            echo -e "${BLUE}ℹ ${message}${NC}"
            ;;
        SECTION)
            echo ""
            echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo -e "${CYAN}${message}${NC}"
            echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            ;;
    esac
}

die() {
    log FAIL "$*"
    exit 1
}

report() {
    echo "$*" >> "${REPORT_FILE}"
}

# ============================================================================
# Setup
# ============================================================================

setup() {
    mkdir -p "${REPORTS_DIR}"
    
    # Initialize report
    cat > "${REPORT_FILE}" <<EOF
# Dotfiles Bootstrap Validation Report

**Timestamp**: $(date)  
**Image**: ${IMAGE_NAME}  
**Container**: ${CONTAINER_NAME}  

EOF
    
    log SECTION "Docker Test Harness Started"
    log INFO "Report: ${REPORT_FILE}"
}

cleanup() {
    if [[ ${KEEP_CONTAINER} == true ]]; then
        log WARN "Container kept for inspection: ${CONTAINER_NAME}"
        log INFO "To remove: docker rm ${CONTAINER_NAME}"
        return 0
    fi
    
    log INFO "Cleaning up container..."
    docker rm -f "${CONTAINER_NAME}" 2>/dev/null || true
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --test-fresh)
                TEST_IDEMPOTENCY=false
                TEST_ROLLBACK=false
                shift
                ;;
            --test-idempotency)
                TEST_FRESH=false
                TEST_ROLLBACK=false
                shift
                ;;
            --test-rollback)
                TEST_FRESH=false
                TEST_IDEMPOTENCY=false
                shift
                ;;
            --test-conflicts)
                TEST_CONFLICTS=true
                shift
                ;;
            --keep-container)
                KEEP_CONTAINER=true
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

# ============================================================================
# Docker Management
# ============================================================================

docker_run() {
    local cmd=$1
    docker exec "${CONTAINER_NAME}" bash -c "${cmd}"
}

docker_run_capture() {
    local cmd=$1
    docker exec "${CONTAINER_NAME}" bash -c "${cmd}" 2>&1
}

create_container() {
    log INFO "Creating container from ${IMAGE_NAME}..."
    
    docker run -d \
        --name "${CONTAINER_NAME}" \
        --volume "${SCRIPT_DIR}:/dotfiles:ro" \
        "${IMAGE_NAME}" \
        tail -f /dev/null > /dev/null
    
    # Wait for container to be ready
    sleep 2
    
    log PASS "Container created: ${CONTAINER_NAME}"
}

# ============================================================================
# Test 1: Fresh Install
# ============================================================================

test_fresh_install() {
    [[ ${TEST_FRESH} == false ]] && return 0
    
    log SECTION "Test 1: Fresh Ubuntu Bootstrap"
    report "## Test 1: Fresh Ubuntu Bootstrap"
    report ""
    
    # Update system
    log INFO "Updating package lists..."
    docker_run "apt-get update -qq" || {
        log FAIL "Failed to update package lists"
        return 1
    }
    
    docker_run "apt-get install -qq -y git" || {
        log FAIL "Failed to install git"
        return 1
    }
    
    # Run bootstrap
    log INFO "Running bootstrap..."
    local start=$(date +%s%N)
    
    if ! docker_run "cd /dotfiles && bash bootstrap.sh --verbose 2>&1"; then
        log FAIL "Bootstrap failed"
        docker_run_capture "cat /dotfiles/logs/bootstrap_*.log | tail -50"
        return 1
    fi
    
    local end=$(date +%s%N)
    local duration=$((($end - $start) / 1000000))
    log PASS "Bootstrap completed in ${duration}ms"
    report "- Bootstrap completed successfully in ${duration}ms"
    
    # Verify basic setup
    log INFO "Verifying installation..."
    
    # Check symlinks
    docker_run "test -L ~/.config/nvim" && log PASS "Neovim symlink exists" || log FAIL "Neovim symlink missing"
    docker_run "test -L ~/.tmux.conf" && log PASS "Tmux symlink exists" || log FAIL "Tmux symlink missing"
    docker_run "test -L ~/.zshrc" && log PASS "Zsh symlink exists" || log FAIL "Zsh symlink missing"
    
    # Run diagnostics
    log INFO "Running diagnostics..."
    local diag_output=$(docker_run_capture "cd /dotfiles && bash scripts/diagnostics/run.sh 2>&1 | tail -20")
    
    if echo "${diag_output}" | grep -q "System appears to be healthy"; then
        log PASS "Diagnostics passed"
        report "- All diagnostics passed"
    else
        log WARN "Diagnostics showed issues"
        report "- Diagnostics output:"
        echo "${diag_output}" | sed 's/^/  /' >> "${REPORT_FILE}"
    fi
    
    report ""
}

# ============================================================================
# Test 2: Idempotency (Re-run)
# ============================================================================

test_idempotency() {
    [[ ${TEST_IDEMPOTENCY} == false ]] && return 0
    
    log SECTION "Test 2: Idempotency (Safe Re-runs)"
    report "## Test 2: Idempotency Verification"
    report ""
    
    # First run
    log INFO "First bootstrap run..."
    docker_run "cd /dotfiles && bash bootstrap.sh --skip-packages 2>&1" > /dev/null || {
        log FAIL "First run failed"
        return 1
    }
    log PASS "First run completed"
    
    # Get state after first run
    local state1=$(docker_run "find ~/.config ~/.tmux.conf ~/.zshrc -type l -exec ls -l {} \; 2>/dev/null | md5sum")
    
    # Second run
    log INFO "Second bootstrap run (should be idempotent)..."
    local start=$(date +%s%N)
    
    docker_run "cd /dotfiles && bash bootstrap.sh --skip-packages 2>&1" > /dev/null || {
        log FAIL "Second run failed"
        return 1
    }
    
    local end=$(date +%s%N)
    local duration=$((($end - $start) / 1000000))
    log PASS "Second run completed in ${duration}ms (should be faster)"
    
    # Verify state unchanged
    local state2=$(docker_run "find ~/.config ~/.tmux.conf ~/.zshrc -type l -exec ls -l {} \; 2>/dev/null | md5sum")
    
    if [[ "${state1}" == "${state2}" ]]; then
        log PASS "Idempotency verified: state unchanged"
        report "- Second run state matches first run (idempotent)"
    else
        log WARN "State changed between runs"
        report "- WARNING: State changed between runs (non-idempotent)"
    fi
    
    report ""
}

# ============================================================================
# Test 3: Rollback
# ============================================================================

test_rollback() {
    [[ ${TEST_ROLLBACK} == false ]] && return 0
    
    log SECTION "Test 3: Rollback Capability"
    report "## Test 3: Rollback Testing"
    report ""
    
    # Create initial files
    log INFO "Creating test files..."
    docker_run "mkdir -p ~/.config && echo 'test content' > ~/.config/nvim-original"
    
    # Run bootstrap
    log INFO "Running bootstrap..."
    docker_run "cd /dotfiles && bash bootstrap.sh --skip-packages 2>&1" > /dev/null || {
        log FAIL "Bootstrap failed"
        return 1
    }
    
    # Get backup timestamp
    local backup=$(docker_run "ls -td ~/.dotfiles-backup-* | head -1 | xargs basename")
    if [[ -z "${backup}" ]]; then
        log FAIL "No backup directory found"
        return 1
    fi
    
    log PASS "Backup created: ${backup}"
    
    # Modify a file
    log INFO "Modifying configuration..."
    docker_run "echo 'modified' > ~/.zshrc"
    
    # Rollback
    log INFO "Testing rollback..."
    docker_run "cd /dotfiles && bash restore.sh --restore ${backup#*-} --force 2>&1" > /dev/null || {
        log FAIL "Rollback failed"
        return 1
    }
    
    # Verify rollback
    local restored=$(docker_run_capture "head -1 ~/.zshrc")
    if [[ "${restored}" != "modified" ]]; then
        log PASS "Rollback successful: file restored"
        report "- Rollback restored file correctly"
    else
        log FAIL "Rollback did not restore file"
        return 1
    fi
    
    report ""
}

# ============================================================================
# Test 4: Edge Cases
# ============================================================================

test_edge_cases() {
    [[ ${TEST_EDGE_CASES} == false ]] && return 0
    
    log SECTION "Test 4: Edge Case Handling"
    report "## Test 4: Edge Case Testing"
    report ""
    
    # Test: Missing dependencies
    log INFO "Testing missing dependency handling..."
    docker_run "rm -f /usr/bin/zsh" || true
    
    if docker_run "cd /dotfiles && bash bootstrap.sh --skip-packages --dry-run 2>&1 | grep -q 'zsh'"; then
        log PASS "Bootstrap detects missing zsh"
        report "- Bootstrap correctly handles missing dependencies"
    fi
    
    # Test: Permission issues
    log INFO "Testing permission handling..."
    docker_run "mkdir -p ~/.config && chmod 000 ~/.config"
    
    local result=$(docker_run "cd /dotfiles && bash install.sh 2>&1 | head -20" 2>&1 || true)
    if echo "${result}" | grep -q "Permission\|permission"; then
        log PASS "Bootstrap detects permission errors"
        report "- Bootstrap correctly reports permission issues"
    fi
    
    docker_run "chmod 755 ~/.config" || true
    
    report ""
}

# ============================================================================
# Test 5: Conflict Detection
# ============================================================================

test_conflicts() {
    [[ ${TEST_CONFLICTS} == false ]] && return 0
    
    log SECTION "Test 5: Conflict Detection"
    report "## Test 5: Conflict Detection"
    report ""
    
    # Check for PATH duplicates
    log INFO "Checking for PATH duplicates..."
    local dupes=$(docker_run "echo \$PATH | tr ':' '\\n' | sort | uniq -d | wc -l")
    
    if [[ ${dupes} -eq 0 ]]; then
        log PASS "No PATH duplicates found"
        report "- No PATH duplicates detected"
    else
        log WARN "Found ${dupes} PATH duplicates"
        report "- WARNING: Found ${dupes} PATH duplicates"
    fi
    
    # Check for duplicate shell hooks
    log INFO "Checking for duplicate shell initializations..."
    local zsh_markers=$(docker_run "grep -c '^# dotfiles' ~/.zshrc 2>/dev/null || echo 0")
    
    if [[ ${zsh_markers} -le 1 ]]; then
        log PASS "No duplicate shell markers"
        report "- No duplicate shell initialization markers"
    else
        log WARN "Found ${zsh_markers} shell markers (possible duplicates)"
        report "- WARNING: Found ${zsh_markers} shell markers"
    fi
    
    report ""
}

# ============================================================================
# Test 6: Performance Baseline
# ============================================================================

test_performance() {
    log SECTION "Test 6: Performance Baseline"
    report "## Test 6: Performance Benchmarks"
    report ""
    
    # Bootstrap timing
    log INFO "Measuring bootstrap performance..."
    local start=$(date +%s%N)
    docker_run "cd /dotfiles && bash bootstrap.sh --skip-packages 2>&1" > /dev/null || true
    local end=$(date +%s%N)
    local bootstrap_time=$((($end - $start) / 1000000))
    
    log INFO "Bootstrap time: ${bootstrap_time}ms"
    report "- Bootstrap execution time: ${bootstrap_time}ms"
    
    # Shell startup
    log INFO "Measuring shell startup..."
    local shell_time=$(docker_run_capture "time zsh -i -c exit 2>&1" | grep real | awk '{print $2}' || echo "N/A")
    
    log INFO "Shell startup: ${shell_time}"
    report "- Shell startup time: ${shell_time}"
    
    report ""
}

# ============================================================================
# Report Generation
# ============================================================================

generate_summary() {
    report "## Summary"
    report ""
    report "| Metric | Result |"
    report "|--------|--------|"
    report "| Tests Passed | ${TESTS_PASSED} |"
    report "| Tests Failed | ${TESTS_FAILED} |"
    report "| Issues Found | ${#ISSUES_FOUND[@]} |"
    report ""
    
    if [[ ${#ISSUES_FOUND[@]} -gt 0 ]]; then
        report "### Issues Found"
        report ""
        for issue in "${ISSUES_FOUND[@]}"; do
            report "- ${issue}"
        done
        report ""
    fi
    
    report "---"
    report "Report generated: $(date)"
}

print_summary() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}VALIDATION SUMMARY${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "Tests Passed:  ${GREEN}${TESTS_PASSED}${NC}"
    echo -e "Tests Failed:  ${RED}${TESTS_FAILED}${NC}"
    echo -e "Issues Found:  ${YELLOW}${#ISSUES_FOUND[@]}${NC}"
    echo ""
    echo -e "Report: ${REPORT_FILE}"
    echo ""
    
    if [[ ${TESTS_FAILED} -eq 0 ]]; then
        echo -e "${GREEN}✓ All tests passed${NC}"
        return 0
    else
        echo -e "${RED}✗ Some tests failed${NC}"
        return 1
    fi
}

# ============================================================================
# Main
# ============================================================================

main() {
    parse_args "$@"
    setup
    trap cleanup EXIT
    
    # Check prerequisites
    if ! command -v docker &> /dev/null; then
        die "Docker is not installed"
    fi
    
    log INFO "Pulling image: ${IMAGE_NAME}"
    docker pull -q "${IMAGE_NAME}" || die "Failed to pull image"
    
    create_container
    
    # Run tests
    test_fresh_install || true
    test_idempotency || true
    test_rollback || true
    test_edge_cases || true
    test_conflicts || true
    test_performance || true
    
    generate_summary
    print_summary
}

main "$@"
