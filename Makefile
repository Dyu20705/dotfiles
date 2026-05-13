.PHONY: help bootstrap install restore diagnostics profile clean logs

# Dotfiles automation Makefile
# Provides convenient commands for bootstrap, installation, and validation

SCRIPTS_DIR := scripts
DIAGNOSTICS_DIR := $(SCRIPTS_DIR)/diagnostics
SHELL := /bin/bash

# Colors
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
NC := \033[0m

help: ## Show this help message
	@echo -e "$(BLUE)Dotfiles Management$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo -e "$(YELLOW)Examples:$(NC)"
	@echo "  make bootstrap                 # Fresh install"
	@echo "  make install                   # Create symlinks only"
	@echo "  make diagnostics               # Run all checks"
	@echo "  make profile                   # Profile startup times"
	@echo "  make restore                   # Restore from backup"

# ============================================================================
# Bootstrap & Installation
# ============================================================================

bootstrap: ## Bootstrap entire dotfiles (packages + config)
	@echo -e "$(BLUE)Starting bootstrap...$(NC)"
	@bash bootstrap.sh
	@echo -e "$(GREEN)Bootstrap complete$(NC)"

bootstrap-dry: ## Dry-run bootstrap (no changes)
	@echo -e "$(YELLOW)DRY-RUN: No changes will be made$(NC)"
	@bash bootstrap.sh --dry-run

bootstrap-verbose: ## Bootstrap with verbose output
	@bash bootstrap.sh --verbose

install: ## Create symlinks for dotfiles
	@echo -e "$(BLUE)Creating symlinks...$(NC)"
	@bash install.sh

install-dry: ## Dry-run install
	@bash install.sh --dry-run

install-force: ## Force install (skip confirmation)
	@bash install.sh --force

restore: ## Restore from backup
	@echo -e "$(RED)Restoring dotfiles...$(NC)"
	@bash restore.sh --list
	@echo ""
	@bash restore.sh

# ============================================================================
# Diagnostics & Validation
# ============================================================================

diagnostics: ## Run comprehensive diagnostics
	@echo -e "$(BLUE)Running diagnostics...$(NC)"
	@bash $(DIAGNOSTICS_DIR)/run.sh --verbose

diagnostics-quick: ## Quick diagnostics (essential checks only)
	@bash $(DIAGNOSTICS_DIR)/run.sh --quick

diagnostics-deep: ## Deep diagnostics (detailed analysis)
	@bash $(DIAGNOSTICS_DIR)/run.sh --deep --verbose

diagnostics-profile: ## Run diagnostics with profiling
	@bash $(DIAGNOSTICS_DIR)/run.sh --profile

# ============================================================================
# Performance Profiling
# ============================================================================

profile: ## Profile shell and Neovim startup times
	@echo -e "$(BLUE)Profiling startup performance...$(NC)"
	@bash $(DIAGNOSTICS_DIR)/profile-startup.sh

profile-deep: ## Deep profiling with plugin analysis
	@bash $(DIAGNOSTICS_DIR)/profile-startup.sh --deep

profile-nvim: ## Profile Neovim only
	@bash $(DIAGNOSTICS_DIR)/profile-startup.sh --nvim-only

profile-shell: ## Profile shell only
	@bash $(DIAGNOSTICS_DIR)/profile-startup.sh --shell-only

# ============================================================================
# Utilities
# ============================================================================

logs: ## Show latest bootstrap log
	@if [ -f logs/bootstrap_*.log ]; then \
		echo -e "$(BLUE)Latest bootstrap log:$(NC)"; \
		tail -50 $$(ls -t logs/bootstrap_*.log | head -1); \
	else \
		echo "No bootstrap logs found"; \
	fi

logs-install: ## Show latest install log
	@if [ -f logs/install_*.log ]; then \
		echo -e "$(BLUE)Latest install log:$(NC)"; \
		tail -50 $$(ls -t logs/install_*.log | head -1); \
	else \
		echo "No install logs found"; \
	fi

logs-diagnostics: ## Show latest diagnostics log
	@if [ -f logs/diagnostics_*.log ]; then \
		echo -e "$(BLUE)Latest diagnostics log:$(NC)"; \
		tail -100 $$(ls -t logs/diagnostics_*.log | head -1); \
	else \
		echo "No diagnostics logs found"; \
	fi

clean-logs: ## Remove old logs (keep last 5)
	@echo "Cleaning old logs..."
	@ls -t logs/*.log 2>/dev/null | tail -n +6 | xargs -r rm -v
	@echo "Done"

# ============================================================================
# Workflow
# ============================================================================

setup: bootstrap diagnostics ## Full setup: bootstrap + diagnostics

validate: diagnostics profile ## Full validation: diagnostics + profiling

test-fresh: ## Test bootstrap on fresh system (requires container)
	@echo -e "$(YELLOW)This would test in a fresh Ubuntu container$(NC)"
	@echo "Implementation: docker run -v \$$PWD:/dotfiles ubuntu:latest /dotfiles/bootstrap.sh"

# ============================================================================
# Development
# ============================================================================

lint-shell: ## Lint shell scripts (requires shellcheck)
	@if command -v shellcheck &> /dev/null; then \
		echo -e "$(BLUE)Linting shell scripts...$(NC)"; \
		shellcheck bootstrap.sh install.sh restore.sh; \
		shellcheck scripts/diagnostics/*.sh; \
	else \
		echo "shellcheck not installed"; \
	fi

format-shell: ## Format shell scripts (requires shfmt)
	@if command -v shfmt &> /dev/null; then \
		echo -e "$(BLUE)Formatting shell scripts...$(NC)"; \
		shfmt -i 4 -w bootstrap.sh install.sh restore.sh; \
		shfmt -i 4 -w scripts/diagnostics/*.sh; \
	else \
		echo "shfmt not installed"; \
	fi

check: ## Run linters and validators
	@echo -e "$(BLUE)Running checks...$(NC)"
	@make lint-shell
	@make diagnostics-quick

# ============================================================================
# Documentation
# ============================================================================

docs: ## Show bootstrap documentation
	@if [ -f docs/BOOTSTRAP.md ]; then \
		less docs/BOOTSTRAP.md; \
	else \
		echo "docs/BOOTSTRAP.md not found"; \
	fi

docs-arch: ## Show architecture documentation
	@if [ -f docs/ARCHITECTURE.md ]; then \
		less docs/ARCHITECTURE.md; \
	else \
		echo "docs/ARCHITECTURE.md not found"; \
	fi

# Default target
.DEFAULT_GOAL := help
