# Rush v0 Integration Design

## Objective

Ship a usable Ubuntu-first workstation from the existing stabilization branch as quickly as possible while preserving rollback, diagnostics and testability. This design deliberately favors thin shell interfaces and explicit files over a broad refactor. Later design work may replace internals without changing the user-facing command contract.

## Baseline

The implementation starts from draft PR #21 at commit `8d53358ade4b411f8dd854422bd1a3603a7429e7`. That branch already provides manifest-driven links, isolated shell/tmux/Neovim/WezTerm checks, resilient optional integrations and initial documentation. PR #28 is treated as reference evidence; its tmux fix is not cherry-picked blindly because the #21 branch already has a newer synchronous `current_file`-based tmux entrypoint.

## Product Contract

The supported primary platform is Ubuntu 24.04 or later. The daily path is:

```text
clone -> dot install -> dot doctor -> dev -> tmux -> Neovim -> Git/gw
```

Stable commands:

```text
dot status
dot install [--profile minimal|normal|full] [--context desktop|laptop|server|remote]
dot link [--profile ...] [--dry-run]
dot packages [--profile ...] [--dry-run]
dot doctor [--profile ...] [--json] [--explain]
dot check [static|runtime|full|clean-room]
dot bench [--json]
dot backup list
dot backup restore <id>
dot uninstall [--profile ...]
dot env [--json]
dot capability list|enable|disable|doctor <id>
dev [query|.|--list|--refresh|--kill <name>]
gw list|status|new|open|remove|prune
```

Exit codes are stable:

- `0`: success;
- `10`: usable but an optional capability is degraded;
- `20`: invalid user input or configuration;
- `30`: hard operational failure.

## Architecture

### 1. Declarative contract

`config/workflow.json` remains the single tracked contract for profiles, machine contexts, package tiers, links, performance budgets and available capability packs. Existing fields remain compatible with PR #21; new fields are additive so current bootstrap and doctor behavior is not broken.

### 2. Thin operator command

`scripts/dot` is a dispatcher. It delegates to focused scripts and never reimplements linking, diagnostics, tests or benchmarks. The bootstrap links it to `~/.local/bin/dot`.

### 3. Installation and rollback

`scripts/bootstrap.sh` remains the link engine. It records one manifest per mutating run beneath `${XDG_STATE_HOME:-~/.local/state}/dotfiles/backups/<id>/manifest.tsv`. `scripts/backup.sh` lists and restores only recorded paths. `scripts/uninstall.sh` removes only symlinks that resolve into the current checkout. `scripts/packages.sh` prints or installs Ubuntu package groups separately from links.

### 4. Shared shell capability layer

`shell/common.sh` is POSIX-compatible and sourced by Bash and Zsh after mode/context resolution. It centralizes Ubuntu command aliases (`fd`/`fdfind`, `bat`/`batcat`), conservative wrappers, fuzzy helpers and optional integration detection. Minimal and remote modes do not initialize interactive plugins.

### 5. Project and worktree workflows

`scripts/dev` discovers Git repositories under `DOTFILES_PROJECT_DIRS`, caches results under XDG cache, uses `fzf` when available and otherwise prints deterministic choices. It attaches to or creates one stable tmux session per project.

`scripts/gw` wraps plain Git worktree operations. It stores managed worktrees under `${DOTFILES_WORKTREE_ROOT:-${XDG_DATA_HOME:-~/.local/share}/worktrees/<repo>}`, rejects dirty removal without `--force`, detects already checked-out branches and can open a worktree through `dev`.

### 6. Profiles, contexts and private overlays

Independent dimensions are preserved:

- feature profile: `minimal`, `normal`, `full`;
- machine context: `desktop`, `laptop`, `server`, `remote`;
- zero or more explicit capability packs;
- untracked local overlays.

Precedence is:

```text
repository defaults -> machine context -> feature profile -> capability selection -> private local overlay
```

Tracked `.example` files document local Git, shell, tmux, Neovim and WezTerm overrides without private values.

### 7. Capability packs

`capabilities/system` is the only demonstration pack. Its manifest declares packages, shell file, doctor script, test script, ownership boundaries, disable behavior and expected cost. Selection is stored outside the repository under XDG config. No pack loads in minimal mode.

### 8. Editor boundary

Normal Neovim startup keeps editing, search, LSP, diagnostics, formatting and focused Git review. Terminal, test-runner, DAP UI, file-tree and broad Git UI plugins are classified as extended and are lazy/optional rather than startup owners. A plugin audit and keymap reference document the retained purpose of every lock-file entry.

### 9. Verification

`scripts/test.sh` remains the local entrypoint and gains contract tests for the new commands, rollback, shell parity, project discovery, safe worktrees, capabilities and documentation references. GitHub Actions adds:

- Ubuntu clean-room install/idempotence/restore tests;
- SHA-pinned validation actions and least-privilege permissions;
- secret and workflow security scans;
- scheduled/manual benchmarks;
- scheduled/manual dependency-update draft PRs.

GUI, Wayland/X11 clipboard, physical key routing and audio playback cannot be proven in headless CI. They remain explicit manual acceptance items and are never represented as automated evidence.

## Error Handling

All command entrypoints use `set -euo pipefail` where compatible, validate arguments before mutation, reject targets outside `HOME`, avoid printing secrets or clipboard content and emit concise actionable diagnostics. Optional tools return degraded status without breaking shell or tmux startup.

## Issue Coverage

- #1, #25: unified install/link/packages/backup/restore/uninstall/status interfaces.
- #3–#7: existing WezTerm/shell/tmux contracts retained; tmux helper and clipboard fixtures extended.
- #8–#11: canonical configs, Neovim recovery, dependency matrix and LazyDocker risk/pinning finalized.
- #12–#15: clean-room, security, optional mise and benchmark workflows.
- #16–#17: project launcher and controlled dependency-update workflow.
- #19–#20: machine contexts, private overlays, roadmap and release evidence.
- #22–#24: Neovim boundary, shared CLI stack and safe Git/worktree helper.
- #26–#27: operator handbook and one demonstrable capability pack.

## Deferred Redesign

A later architecture pass may replace shell implementations, split the manifest or redesign profiles. It must preserve the command names, exit semantics, backup safety and evidence contracts unless a migration is documented.
