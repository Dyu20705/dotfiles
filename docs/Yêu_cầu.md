Đây là cách tôi sẽ viết yêu cầu cho AI coding agent để agent làm đúng hướng, không phá basecode và tập trung vào reliability thay vì “refactor vô tội vạ”.

---

# Dotfiles Stabilization & Production Hardening Tasks

Repository: [GitHub Repository](https://github.com/Dyu20705?utm_source=chatgpt.com)

## Global Constraints

* DO NOT rewrite the architecture.
* DO NOT replace working tools/frameworks unless absolutely necessary.
* Preserve existing basecode and user workflows.
* Prioritize:

  * stability
  * deterministic behavior
  * security
  * reproducibility
  * maintainability
* Any destructive change MUST include justification.
* Any shell script modification MUST preserve POSIX/Bash compatibility.
* Prefer minimal safe patches over large refactors.
* All changes must be tested locally and inside Docker when possible.
* Every detected bug/error during execution MUST be fixed immediately before continuing.
* Never silently remove functionality.
* Ensure idempotent setup behavior.

---

# Task 1 — Remove docs/ From Remote & Ignore It

## Requirements

* Remove existing `docs/` directory from git tracking on remote.
* Keep local `docs/` untouched.
* Add `docs/` into `.gitignore`.
* Ensure future commits never include docs artifacts.

## Expected Operations

```bash
git rm -r --cached docs
echo "docs/" >> .gitignore
```

## Validation

* `git status` should not track docs anymore.
* Existing local docs files must remain on disk.

---

# Task 2 — Audit & Optimize Important Scripts

## Requirements

Perform full audit of all scripts:

* install scripts
* bootstrap scripts
* setup scripts
* shell helper scripts
* tmux helper scripts
* wezterm helper scripts

## For each script:

### Determine

* Is it actually used?
* Is it critical?
* Is it redundant?
* Is it safe?
* Is it portable?
* Is it idempotent?

### Optimize Important Scripts

Focus on:

* startup speed
* error handling
* portability
* shellcheck compliance
* deterministic execution

## Mandatory Improvements

### Add strict mode where safe

```bash
set -euo pipefail
```

### Fix quoting

```bash
"$VAR"
```

### Prevent unsafe globbing

### Add dependency checks

Example:

```bash
command -v tmux >/dev/null 2>&1
```

### Improve logging

Use readable logs:

```bash
[INFO]
[WARN]
[ERROR]
```

### Ensure rerunnable installs

No duplicated symlinks/configs.

---

# Task 3 — Verify tmux Shell Scripts Work Correctly

## Requirements

Fully verify:

* tmux startup scripts
* session scripts
* plugin scripts
* shell integrations
* keybindings invoking shell commands

## Validate

* no broken paths
* no race conditions
* no missing executable permissions
* no invalid shell syntax
* no plugin initialization failures

## Must Test

### Inside real tmux

```bash
tmux source-file ~/.tmux.conf
```

### Plugin initialization

Especially:

* TPM
* resurrect
* continuum
* clipboard integrations

## Fix Requirements

* repair broken shell hooks
* repair PATH issues
* repair clipboard issues
* ensure compatibility on Ubuntu

---

# Task 4 — Force WezTerm Background Rendering Fallback

## Problem

Background image fallback is NOT rendering.

Need guaranteed default background rendering.

## Requirements

Implement deterministic fallback logic:

### If image exists

Render image.

### If image missing/fails

Render built-in default background automatically.

NOT transparent.
NOT empty.
NOT broken.

## Required Improvements

### Verify paths

Use absolute paths safely.

### Add file existence checks

Example:

```lua
local success = wezterm.file_exists(path)
```

### Implement explicit fallback

Example behavior:

```lua
if background_exists then
  use_background_image()
else
  use_default_background()
end
```

### Ensure compatible with:

* Windows
* WSL
* Linux

### Validate visually

Agent MUST confirm actual rendering behavior.

---

# Task 5 — Verify Config & Plugins Work Correctly

## Requirements

Audit ALL configs:

* zsh
* bash
* tmux
* wezterm
* neovim
* shell aliases
* environment variables

## Plugin Validation

Ensure plugins:

* load successfully
* do not conflict
* do not slow startup excessively
* fail gracefully

## Detect

* duplicated configs
* conflicting keymaps
* invalid lazy-loading
* deprecated APIs
* startup errors
* broken PATH exports

## Mandatory Validation

### Neovim

```bash
nvim --headless "+Lazy! sync" +qa
```

### tmux

```bash
tmux start-server
```

### WezTerm

Validate config parsing.

### Shell

```bash
zsh -n ~/.zshrc
bash -n script.sh
```

---

# Task 6 — Complete docker-compose.yaml & README.md

## docker-compose.yaml Requirements

Create reliable development/testing environment.

Must support:

* Ubuntu-based environment
* tmux
* zsh
* neovim
* wezterm compatibility testing where possible

## docker-compose Goals

* reproducible setup
* quick onboarding
* safe testing
* isolated validation

## README.md Requirements

Rewrite professionally.

Must include:

# Sections

* Overview
* Features
* Screenshots/GIFs
* Installation
* Quick Start
* Structure
* Keybindings
* Plugin List
* Testing
* Troubleshooting
* Security Philosophy
* Maintenance Notes
* Platform Support

## README Quality

Should feel:

* production-grade
* infra-engineer style
* concise but professional
* technically trustworthy

---

# Task 7 — Fix Bugs Immediately During Work

## Requirements

During ALL tasks:

* Any discovered bug
* Any warning
* Any shellcheck issue
* Any runtime error
* Any broken plugin
* Any invalid path
* Any failing startup

MUST be fixed immediately.

Do NOT postpone issues.

## Required Workflow

1. detect
2. explain
3. patch
4. validate
5. continue

---

# Task 8 — Preserve Security, Basecode & Infrastructure Stability

## Hard Constraints

DO NOT:

* break user workflow
* overengineer
* replace stable tools unnecessarily
* add risky dependencies
* weaken shell security
* add telemetry
* add cloud dependencies

## Security Requirements

* secure file permissions
* safe shell execution
* sanitized environment variables
* no unsafe curl | sh patterns
* deterministic installs
* avoid privilege escalation

## Stability Requirements

* configs must load deterministically
* startup should remain fast
* plugin manager failures should degrade gracefully
* fallback behavior required for all critical features

---

# Required Final Deliverables

## Agent MUST provide:

### 1. Full change summary

* what changed
* why changed
* impact

### 2. Validation report

Include results of:

```bash
shellcheck
zsh -n
bash -n
tmux source-file
nvim headless
docker compose up
```

### 3. Risk assessment

List:

* remaining risks
* edge cases
* future improvements

### 4. Security review

Explain:

* shell safety
* permission handling
* dependency risks

### 5. Performance notes

Include:

* startup optimizations
* plugin load improvements
* script execution improvements

Cách viết như trên sẽ giúp AI agent:

* không “tự tiện rewrite”
* tập trung fix thực tế
* tránh phá workflow
* hoạt động giống một infra/system engineer hơn là “AI code generator”.
