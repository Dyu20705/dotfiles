# Rush v0 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver a usable Ubuntu-first dotfiles v0 that closes the open operational backlog through stable commands, safe rollback, shared shell behavior, project/worktree helpers, diagnostics, tests and operator documentation.

**Architecture:** Extend the PR #21 manifest-driven Bash foundation rather than replacing it. Add thin command entrypoints and isolated libraries, keep machine/private state under XDG directories, and validate all new contracts through `scripts/test.sh` plus GitHub Actions clean-room jobs.

**Tech Stack:** Bash/POSIX shell, jq, tmux, Neovim Lua, WezTerm Lua, Git, YAML, GitHub Actions, mise.

## Global Constraints

- Ubuntu 24.04+ is the primary tested platform.
- Do not merge or tag automatically.
- Never overwrite or delete a user file without a recorded backup or an explicit force flag.
- Private identity, secrets, hostnames and personal asset paths remain untracked.
- Optional dependencies degrade quietly.
- GUI/audio/Wayland/X11 claims require manual evidence and must be labeled as such.
- Keep the PR #21 command and manifest behavior backward compatible.

---

### Task 1: Add failing v0 contract tests

**Files:**
- Create: `scripts/tests/v0_contract_test.sh`
- Create: `scripts/tests/backup_restore_test.sh`
- Create: `scripts/tests/dev_test.sh`
- Create: `scripts/tests/gw_test.sh`
- Create: `scripts/tests/capability_test.sh`
- Modify: `scripts/test.sh`

**Interfaces:**
- Consumes: `DOTFILES_ROOT`, temporary HOME/XDG directories, Git and jq.
- Produces: executable contract tests called by `scripts/test.sh --profile static`.

- [ ] **Step 1: Write tests that require the final command surface**

Assert that `scripts/dot`, `scripts/dev`, `scripts/gw`, `scripts/backup.sh`, `scripts/packages.sh`, `scripts/benchmark.sh`, completion files and the system capability manifest exist and expose `--help`.

- [ ] **Step 2: Write behavior fixtures**

Use temporary directories and repositories to assert:

```text
bootstrap apply twice -> identical links
backup restore -> original regular file restored
dev --list -> repository roots only
gw remove dirty -> rejected
gw remove --force -> succeeds
capability enable/disable -> selection changes outside checkout
dot env --json -> valid stable JSON
```

- [ ] **Step 3: Register tests in `run_static`**

Add one `run_check` per contract so CI identifies the failing subsystem precisely.

- [ ] **Step 4: Run CI and confirm RED**

Expected: the static job fails because the new command files are absent. The failure must name at least one missing v0 command, not a YAML or syntax error.

- [ ] **Step 5: Commit**

```bash
git add scripts/test.sh scripts/tests
git commit -m "test: define rush v0 contracts"
```

### Task 2: Extend the manifest and shared libraries

**Files:**
- Modify: `config/workflow.json`
- Modify: `scripts/lib/common.sh`
- Create: `scripts/lib/context.sh`

**Interfaces:**
- Produces: `effective_profile`, `effective_context`, `selected_capabilities`, exit-code constants, backup run helpers and package queries.

- [ ] **Step 1: Add additive manifest sections**

Add `contexts`, `packages`, `performance_budgets_ms`, `commands` and `capability_packs` without removing current `apps` or `links` fields.

- [ ] **Step 2: Extend manifest validation**

Validate known contexts, package arrays, command names and unique link targets while accepting the existing schema version.

- [ ] **Step 3: Add context resolution**

Implement deterministic defaults:

```text
SSH/CI -> remote
no GUI display -> server
otherwise -> desktop
```

Environment variables `DOTFILES_PROFILE`, `DOTFILES_CONTEXT` and XDG local overlay files override defaults only after validation.

- [ ] **Step 4: Add stable exit constants and state paths**

Expose `DOTFILES_EXIT_OK=0`, `DOTFILES_EXIT_DEGRADED=10`, `DOTFILES_EXIT_USAGE=20`, `DOTFILES_EXIT_HARD=30` and XDG config/cache/state/data helpers.

- [ ] **Step 5: Run manifest tests**

Run `bash scripts/test.sh --profile static`; expected remaining failures are commands not yet implemented.

### Task 3: Complete install, packages, backup and rollback

**Files:**
- Modify: `scripts/bootstrap.sh`
- Create: `scripts/packages.sh`
- Create: `scripts/backup.sh`
- Create: `scripts/uninstall.sh`
- Modify: `config/workflow.json`

**Interfaces:**
- `bootstrap.sh`: `--profile`, `--dry-run`, records `manifest.tsv` and `metadata.json` for mutations.
- `packages.sh`: `--profile`, `--dry-run`, `--yes`.
- `backup.sh`: `list`, `restore <id>`.
- `uninstall.sh`: `--profile`, `--dry-run`.

- [ ] **Step 1: Record one backup manifest per bootstrap run**

Each row contains operation, target, source and backup path. No path outside `HOME` is accepted.

- [ ] **Step 2: Implement restore**

Restore only rows from the selected manifest, remove only repository-owned links and reject a missing/incomplete backup.

- [ ] **Step 3: Implement package tiers**

Map manifest package names to Ubuntu apt packages. `--dry-run` prints the exact `apt-get install` command; mutation requires Ubuntu and `sudo` or root.

- [ ] **Step 4: Implement safe uninstall**

Remove symlinks only when their resolved target is inside `DOTFILES_ROOT`; leave regular files and unrelated links untouched.

- [ ] **Step 5: Run backup and idempotence fixtures**

Expected: apply twice succeeds, restore recreates the original file byte-for-byte, uninstall leaves unrelated files unchanged.

### Task 4: Add unified `dot` command and completions

**Files:**
- Create: `scripts/dot`
- Create: `completions/dot.bash`
- Create: `completions/_dot`
- Modify: `config/workflow.json`
- Modify: `scripts/doctor.sh`

**Interfaces:**
- Stable command surface defined in the design spec.
- `dot env --json` returns profile, context, capabilities, root and XDG paths without secrets.

- [ ] **Step 1: Implement help and argument routing**

Route install/link/packages/doctor/check/bench/backup/uninstall directly to focused scripts.

- [ ] **Step 2: Implement side-effect-free status and env**

`status` reports checkout revision, effective profile/context and link summary. `env` prints only non-secret configuration origins and paths.

- [ ] **Step 3: Extend doctor evidence**

Add shell/tmux/Neovim/WezTerm/media/clipboard/Git-local-include/capability checks. `--explain` includes source and remediation; JSON remains parseable.

- [ ] **Step 4: Generate completions from one command list**

Both Bash and Zsh completion files use the same literal subcommand registry as `dot --commands`.

- [ ] **Step 5: Run command snapshots**

Assert help, JSON and error exit codes are stable.

### Task 5: Share the Ubuntu CLI shell layer

**Files:**
- Create: `shell/common.sh`
- Modify: `bash/.bashrc`
- Modify: `bash/.bash_aliases`
- Modify: `zsh/.zshrc`
- Create: `shell/local.example`

**Interfaces:**
- Functions: `mkcd`, `ff`, `fcd`, `rgi`, `pspick`, `extract`.
- Commands: `dotfiles_fd`, `dotfiles_bat`, `dotfiles_ls` select Ubuntu-compatible binaries.

- [ ] **Step 1: Centralize command-name detection**

Prefer `fd`, fall back to `fdfind`; prefer `bat`, fall back to `batcat`; prefer `eza`, fall back to `ls`. Do not alias standard commands in minimal mode.

- [ ] **Step 2: Add conservative functions**

Functions validate arguments, handle missing optional tools and never mutate outside explicit targets.

- [ ] **Step 3: Source one shared file in Bash and Zsh**

Load after effective mode/context is known. Skip fuzzy hooks and local overlays in noninteractive/minimal contexts as appropriate.

- [ ] **Step 4: Add present/absent/Ubuntu-name fixtures**

Fake binaries on PATH and assert Bash/Zsh expose matching behavior without startup output.

### Task 6: Add project launcher and safe worktree helper

**Files:**
- Create: `scripts/dev`
- Create: `scripts/gw`
- Create: `completions/dev.bash`
- Create: `completions/_dev`
- Create: `completions/gw.bash`
- Create: `completions/_gw`
- Modify: `config/workflow.json`

**Interfaces:**
- `dev`: query/list/refresh/kill/current-project operations.
- `gw`: list/status/new/open/remove/prune operations.

- [ ] **Step 1: Implement deterministic project discovery**

Search configurable roots to a bounded depth, cache canonical Git roots, exclude `.git`, node_modules, cache and worktree roots, and provide a plain `find` fallback.

- [ ] **Step 2: Implement stable tmux session naming**

Use sanitized repository basename plus a short checksum of the canonical path. Attach existing sessions and create new sessions at the repository root.

- [ ] **Step 3: Implement worktree safety**

Reject branches already checked out, reject dirty removal without `--force`, show upstream/dirty/last-commit state and remain offline-capable.

- [ ] **Step 4: Run temporary-repository fixtures**

Cover list, create, duplicate branch, open, dirty remove rejection, forced remove and prune.

### Task 7: Finish tmux, clipboard and Neovim boundaries

**Files:**
- Create: `scripts/install-tmux-plugins.sh`
- Modify: `tmux/plugins.conf`
- Create: `tmux/tests/plugin_install_test.sh`
- Modify: `tmux/clipboard-paste.sh`
- Create: `tmux/clipboard-copy.sh`
- Create: `docs/NEOVIM_PLUGINS.md`
- Create: `docs/KEYMAPS.md`
- Modify: selected Neovim plugin specs only where required to mark extended behavior lazy/optional.

**Interfaces:**
- TPM helper: `--install`, `--update`, `--check`.
- Clipboard copy chooses Wayland/X11/OSC52 based on active environment and payload limit.

- [ ] **Step 1: Make TPM setup diagnosable**

Core tmux remains usable without TPM. The helper clones only when explicitly requested and reports current plugin state.

- [ ] **Step 2: Add clipboard copy provider selection**

Prefer Wayland `wl-copy`, X11 `xclip`/`xsel`, and OSC52 for remote/nested terminals. Enforce `DOTFILES_OSC52_MAX_BYTES` and never log content.

- [ ] **Step 3: Audit Neovim plugins**

Document one owner/use case per lock entry and classify core versus extended. Ensure terminal/test/DAP/tree/broad-Git UI do not eagerly own normal startup.

- [ ] **Step 4: Add headless filetype and keymap checks**

Exercise representative Lua, Python, Rust, Markdown and shell buffers without network access.

### Task 8: Add benchmarks, clean-room and security workflows

**Files:**
- Create: `scripts/benchmark.sh`
- Create: `.github/workflows/clean-room.yml`
- Create: `.github/workflows/security.yml`
- Create: `.github/workflows/benchmarks.yml`
- Create: `.github/workflows/update-dependencies.yml`
- Modify: `.github/workflows/validate.yml`
- Modify: `.github/dependabot.yml`
- Create: `mise.toml`
- Create: `docs/SECURITY.md`
- Create: `docs/BENCHMARKS.md`

**Interfaces:**
- Benchmark JSON contains metric, samples, median_ms, budget_ms and status.
- Clean-room job applies links twice, runs doctor/check and restores backups in a temporary HOME.

- [ ] **Step 1: Implement portable benchmarks**

Use `hyperfine` when available and a monotonic Python/time fallback otherwise. Measure Bash, Zsh, tmux, Neovim and WezTerm config evaluation without network.

- [ ] **Step 2: Pin Actions by full SHA**

Add readable version comments, `persist-credentials: false`, least-privilege permissions and bounded timeouts.

- [ ] **Step 3: Add security checks**

Run Gitleaks and zizmor or an equivalent workflow audit; keep Scorecard non-blocking. Never upload home paths, clipboard data or environment dumps.

- [ ] **Step 4: Add controlled update workflow**

Manual/scheduled workflow updates lock files in an isolated HOME, runs full checks and opens one draft PR only when changes exist. No auto-merge and no PAT when `GITHUB_TOKEN` is sufficient.

- [ ] **Step 5: Add optional mise pins**

Pin repository-maintenance tools only; all checks retain explicit native commands.

### Task 9: Add contexts, overlays and one capability pack

**Files:**
- Create: `config/local.example`
- Create: `tmux/local.conf.example`
- Create: `nvim/.config/nvim/lua/local.lua.example`
- Create: `wezterm/local.lua.example`
- Create: `capabilities/system/manifest.json`
- Create: `capabilities/system/shell.sh`
- Create: `capabilities/system/doctor.sh`
- Create: `capabilities/system/test.sh`
- Create: `docs/ARCHITECTURE.md`

**Interfaces:**
- Capability selection file: `${XDG_CONFIG_HOME:-~/.config}/dotfiles/capabilities` with one identifier per line.
- System pack provides read-only process/disk/journal helpers only.

- [ ] **Step 1: Implement selection and diagnostics**

`dot capability enable system` writes XDG config; disable removes the identifier; doctor validates manifest and optional tools.

- [ ] **Step 2: Preserve minimal isolation**

No capability script is sourced when profile is minimal. Disabled packs perform no startup work.

- [ ] **Step 3: Document ownership and admission rules**

Record core/capability/project/private boundaries, complexity budgets and keep/move/deprecate decisions for current tools.

### Task 10: Finalize operator documentation and release evidence

**Files:**
- Modify: `README.md`
- Create: `docs/CHEATSHEET.md`
- Create: `docs/GIT_WORKFLOW.md`
- Create: `CHANGELOG.md`
- Create: `docs/RELEASE_EVIDENCE.md`
- Create: `scripts/check-docs.sh`
- Modify: `docker-compose.yaml`
- Modify: `scripts/test.sh`

**Interfaces:**
- Documentation references only implemented commands and canonical paths.

- [ ] **Step 1: Rewrite quick start around `dot`**

Cover clone/install/doctor/dev/tmux/Neovim/Git/media/minimal recovery in the shortest usable path.

- [ ] **Step 2: Add intent-oriented cheat sheet and recipes**

Include install, normal session, no-fzf project opening, worktree create/remove, slow startup diagnosis, rollback, SSH, private identity/assets and minimal-mode recovery.

- [ ] **Step 3: Pin LazyDocker and document socket risk**

Use an explicit image version/digest strategy, correct config mount and start/stop commands.

- [ ] **Step 4: Add documentation contract test**

Check every referenced command, script, environment variable, canonical config path and critical key binding.

- [ ] **Step 5: Run final verification**

Run or observe fresh GitHub Actions for static, runtime, clean-room, security and benchmarks. Record exact commit SHAs, workflow runs, automated pass/fail state and manual-only gaps in `docs/RELEASE_EVIDENCE.md`.

- [ ] **Step 6: Open a draft PR**

Target `main`, do not merge, and map each issue to implementation and evidence in the PR body.
