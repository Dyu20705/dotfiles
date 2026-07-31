# Dotfiles Command and Keymap Cheat Sheet

This is the complete operational reference for the personal Ubuntu-first,
Zsh-first dotfiles repository.

Commands are run from the repository root unless the command has already been
installed into `~/.local/bin`.

## Scope and notation

This document distinguishes three command classes:

| Class | Meaning |
| --- | --- |
| Stable operator interface | `dot`, `dev`, `gw`, shell helpers and documented keymaps |
| Direct maintenance entrypoint | Repository scripts that are safe to invoke explicitly |
| Internal implementation detail | Cache, status, clipboard and test helper scripts that should not become user-facing dependencies |

Notation:

- `<value>` is required.
- `[value]` is optional.
- `A|B` means choose one value.
- Examples use `~/src/dotfiles` as the checkout path; the repository does not
  require that exact location.
- Commands that mutate packages, links, backups, worktrees or sessions are
  called out explicitly.

## Operating model

```text
WezTerm -> tmux -> Zsh -> project commands
                   |-> Neovim
                   |-> Git / LazyGit
```

- Zsh is the only managed interactive shell.
- Bash remains required because repository management and validation scripts
  use `#!/usr/bin/env bash`.
- Git is the source of truth. LazyGit is an optional terminal UI over Git.
- Machine identity, private paths, assets and host-only commands stay outside
  the repository.
- Package installation and symlink deployment are separate operations.

## Fast paths

### First installation

```bash
git clone https://github.com/Dyu20705/dotfiles.git ~/src/dotfiles
cd ~/src/dotfiles

# Inspect the package transaction.
bash scripts/dot packages --profile normal --dry-run

# Install packages, then deploy managed links.
bash scripts/dot packages --profile normal --yes
bash scripts/dot install --profile normal

# Create private Git identity.
cp git/.gitconfig.local.example ~/.gitconfig.local
$EDITOR ~/.gitconfig.local

# Verify the deployment.
dot doctor --explain
dot check runtime
exec zsh
```

### Routine update

```bash
cd ~/src/dotfiles
git pull --ff-only
dot install --profile normal
dot doctor --explain
dot check full
```

### Recovery before `dot` is installed

```bash
cd ~/src/dotfiles
bash scripts/dot doctor --profile normal --explain
bash scripts/dot install --profile normal --dry-run
```

## Profiles, contexts and effective behavior

### Profiles

| Profile | Intended use | Managed interactive shell |
| --- | --- | --- |
| `minimal` | Git, recovery commands and script runtime | None |
| `normal` | Daily Zsh, tmux and Neovim workflow | Zsh |
| `full` | Normal plus WezTerm, LazyGit and optional helpers | Zsh |

### Contexts

| Context | Detection or selection |
| --- | --- |
| `desktop` | Automatically selected when `DISPLAY` or `WAYLAND_DISPLAY` exists |
| `laptop` | Must be selected explicitly |
| `server` | Default when no GUI, SSH or CI signal exists |
| `remote` | Automatically selected for SSH or CI |

Profile resolution uses this order:

1. `DOTFILES_PROFILE`
2. `DOTFILES_SHELL_MODE`
3. `normal`

`server` and `remote` contexts reduce the effective profile to `minimal`
unless `DOTFILES_ALLOW_FULL_REMOTE=1` is explicit.

```bash
DOTFILES_PROFILE=normal dot env
DOTFILES_CONTEXT=laptop dot env
DOTFILES_CONTEXT=remote DOTFILES_ALLOW_FULL_REMOTE=1 \
  DOTFILES_PROFILE=normal dot env
```

Inspect the resolved non-secret state:

```bash
dot env
dot env --json | jq
dot status
```

## Exit status conventions

The stable operator contract defines:

| Exit | Meaning |
| ---: | --- |
| `0` | Success |
| `10` | Optional degradation; the core workflow remains usable |
| `20` | Invalid usage or configuration |
| `30` | Hard safety or runtime failure |

Important implementation detail: several validation scripts end with a shell
predicate and therefore return `1` when checks fail. Treat any non-zero result
as failure unless a command explicitly documents `10`, `20` or `30`.

Examples:

```bash
dot status
status=$?
printf 'dot status exit=%s\n' "$status"

if ! dot check full; then
  printf 'validation failed\n' >&2
fi
```

## The `dot` command

### Discovery

```bash
dot --help
dot --commands
```

The top-level help is intentionally compact. Delegated commands support
additional flags documented below.

### Complete command surface

| Goal | Command |
| --- | --- |
| Summarize checkout and deployment | `dot status` |
| Show effective environment | `dot env [--json]` |
| Deploy links | `dot install [--profile P] [--dry-run]` |
| Reapply links | `dot link [--profile P] [--dry-run]` |
| Install Ubuntu packages | `dot packages [--profile P] [--dry-run] [--yes\|-y]` |
| Diagnose tools and links | `dot doctor [--profile P] [--json] [--explain]` |
| Run repository checks | `dot check [static\|runtime\|full]` |
| Measure startup budgets | `dot bench [--json]` |
| List backups | `dot backup list [--json]` |
| Restore a backup | `dot backup restore <id> [--force]` |
| Safely remove managed links | `dot uninstall [--profile P] [--dry-run]` |
| List capability packs | `dot capability list` |
| Enable a capability | `dot capability enable <id>` |
| Disable a capability | `dot capability disable <id>` |
| Diagnose a capability | `dot capability doctor <id>` |

`P` is one of `minimal`, `normal` or `full`.

### Status and environment

```bash
dot status
dot env
dot env --json | jq
dot env --json | jq '{revision,profile,context,active_capabilities,xdg}'
```

`dot env` reports:

- checkout root and Git revision;
- effective profile and context;
- selected and active capability packs;
- effective XDG config, cache, state and data directories.

`dot status` adds a compact doctor summary. It maps a failing doctor run to exit
status `10`.

### Link deployment

`dot install` and `dot link` currently invoke the same safe symlink deployment
implementation.

```bash
dot install --profile minimal --dry-run
dot install --profile normal
dot link --profile full --dry-run
dot link --profile normal
```

Deployment behavior:

1. validates `config/workflow.json`;
2. rejects sources that do not exist;
3. rejects managed targets outside `HOME`;
4. leaves an already-correct symlink unchanged;
5. moves an existing path into an XDG-state backup;
6. creates the managed symlink;
7. records a restorable manifest.

Use `--dry-run` before changing a new machine or profile.

### Package installation

```bash
dot packages --profile minimal --dry-run
dot packages --profile normal --dry-run
dot packages --profile normal
dot packages --profile full --yes
```

Package installation:

- is Ubuntu/`apt-get` only;
- is separate from link deployment;
- prints the exact transaction with `--dry-run`;
- prompts normally unless `--yes` or `-y` is supplied.

Current package groups:

| Profile | Additional intent |
| --- | --- |
| `minimal` | Bash, Git, `jq`, `curl`, CA certificates |
| `normal` | Zsh, tmux, Neovim, search tools, clipboard tools and `direnv` |
| `full` | Normal plus `mpv`, Docker and Docker Compose |

### Diagnostics

```bash
dot doctor
dot doctor --profile minimal
dot doctor --profile normal --explain
dot doctor --json | jq
dot doctor --json | jq '.checks[] | select(.status != "ok")'
dot doctor --json | jq '.summary'
```

Doctor checks:

- required and optional commands;
- minimum versions where defined;
- managed symlink ownership and targets;
- private Git identity presence;
- TPM presence;
- selected capability packs.

`--explain` prints remediation commands for degraded checks.

### Validation

```bash
dot check static
dot check runtime
dot check full
```

| Profile | Coverage |
| --- | --- |
| `static` | Syntax, lint, manifest, security and configuration contracts |
| `runtime` | Isolated startup and runtime smoke tests |
| `full` | Static and runtime checks |

`dot check` defaults to `full`.

### Benchmarks

```bash
dot bench
dot bench --json
dot bench --json | jq '.[] | select(.status == "over-budget")'
```

The benchmark takes three samples and reports the median. The current script
measures Git and, when installed, Zsh and Neovim.

The manifest also declares tmux and WezTerm budgets, but the current benchmark
script does not measure them. Do not interpret an absent metric as a pass.

### Backup listing and restore

```bash
dot backup list
dot backup list --json | jq
dot backup restore <id>
dot backup restore <id> --force
```

Restore behavior:

- validates the backup ID and full manifest before mutation;
- rejects targets outside `HOME`;
- refuses to replace a changed current path without `--force`;
- with `--force`, moves the current path to a timestamped
  `.pre-restore-*` location;
- renames a consumed backup directory after successful restoration.

Inspect first:

```bash
id=$(dot backup list --json | jq -r '.[0].id')
printf 'latest backup: %s\n' "$id"
```

Never pass an unchecked or empty ID into restore.

### Safe uninstall

```bash
dot uninstall --profile normal --dry-run
dot uninstall --profile normal
```

Uninstall removes only symlinks that still point exactly to sources in the
current checkout. Existing files, directories and unrelated symlinks are left
unchanged.

### Capability lifecycle

```bash
dot capability list
dot capability enable system
dot capability doctor system
exec zsh

dot capability disable system
exec zsh
```

Selections are stored in `~/.config/dotfiles/capabilities`. Capability shell
helpers are not loaded in minimal mode.

## Configuration and state locations

### Local overlays

| Purpose | Loaded local path |
| --- | --- |
| Profile, context and private paths | `~/.config/dotfiles/local.env` |
| Zsh-only local commands | `~/.config/dotfiles/shell.local` |
| Selected capability IDs | `~/.config/dotfiles/capabilities` |
| Git identity and signing | `~/.gitconfig.local` |
| tmux machine overrides | `~/.tmux.conf.local` |

Tracked examples contain placeholders only. Never commit populated local files.

The repository also contains Neovim and WezTerm `local.lua.example` files, but
the current startup code does not source corresponding local Lua files. Use the
documented environment variables until explicit loader support is implemented.

### XDG-owned state

| Data | Default location |
| --- | --- |
| Project discovery cache | `~/.cache/dotfiles/projects` |
| Zsh history | `~/.local/state/zsh/history` |
| Deployment backups | `~/.local/state/dotfiles/backups` |
| Worktrees | `~/.local/share/worktrees/<repository>` |
| tmux session metadata | `~/.local/state/dotfiles/tmux/sessions` |
| Pomodoro state | `~/.local/state/dotfiles/tmux/pomodoro.json` |
| WezTerm persistent state | `~/.local/state/dotfiles/wezterm` |

All locations honor the corresponding `XDG_*_HOME` variable.

## Project sessions with `dev`

### `dev` syntax

```text
dev [query|.|--list|--refresh|--kill <session-name>]
```

### `dev` commands

| Command | Behavior |
| --- | --- |
| `dev` | Select from all discovered projects |
| `dev <query>` | Match project paths case-insensitively |
| `dev .` | Open the current Git repository root |
| `dev --list` | Print the cached project list |
| `dev --refresh` | Rescan roots, replace the cache and print it |
| `dev --kill <session-name>` | Kill an exact tmux session name |

Examples:

```bash
dev --refresh
dev --list
dev my-project
dev .
```

Project discovery uses:

```bash
export DOTFILES_PROJECT_DIRS="$HOME/src:$HOME/projects:$HOME/study"
export DOTFILES_PROJECT_MAX_DEPTH=5
```

Behavior details:

- one match opens immediately;
- multiple matches use `fzf` when available in a TTY;
- without `fzf`, refine the query;
- each canonical project path receives a stable session name in the form
  `<basename>-<checksum>`;
- inside tmux, `dev` switches client;
- outside tmux, it attaches or creates;
- without tmux, it prints the project path and returns `10`;
- `--kill` expects the generated tmux session name, not a project query.

Refresh after adding, moving or deleting repositories.

## Git worktrees with `gw`

`gw` must be run inside a Git repository.

### `gw` syntax

```text
gw list
gw status
gw new <branch> [base]
gw open <name-or-path>
gw remove <name-or-path> [--force]
gw prune
```

### `gw` commands

| Command | Behavior |
| --- | --- |
| `gw list`, `gw status` | Show path, branch, clean/dirty state and latest commit |
| `gw new <branch> [base]` | Add an existing branch or create it from `base` |
| `gw open <name-or-path>` | Open through `dev .`, or print the path |
| `gw remove <name-or-path>` | Remove a clean worktree |
| `gw remove <name-or-path> --force` | Explicitly remove a dirty worktree |
| `gw prune` | Prune stale Git worktree metadata |

Examples:

```bash
gw status
gw new issue-123 main
gw open issue-123
gw remove issue-123
gw prune
```

Default root:

```bash
${DOTFILES_WORKTREE_ROOT:-${XDG_DATA_HOME:-$HOME/.local/share}/worktrees/<repo>}
```

Override it per machine:

```bash
export DOTFILES_WORKTREE_ROOT="$HOME/worktrees/dotfiles"
```

Safety guarantees:

- refuses a branch already checked out elsewhere;
- refuses an existing destination path;
- refuses dirty removal unless `--force` is explicit;
- never fetches;
- never merges;
- never deletes branches.

## Zsh workflow

### Shell modes

```bash
DOTFILES_SHELL_MODE=minimal zsh
DOTFILES_SHELL_MODE=normal zsh
DOTFILES_SHELL_MODE=full zsh
dotfiles-shell-diagnostics
```

A normal shell becomes minimal in SSH or CI. Being inside tmux does not reduce a
local normal shell.

Completion can be disabled for diagnostics:

```bash
DOTFILES_SKIP_COMPLETION=1 zsh
```

### Aliases

| Alias | Expansion |
| --- | --- |
| `..` | `cd ..` |
| `...` | `cd ../..` |
| `vi`, `vim` | `nvim` |
| `gs` | `git status` |
| `gd` | `git diff` |
| `gl` | `git log --oneline --decorate --graph` |
| `reload` | `exec zsh` |
| `ll` | `eza -la`, falling back to `ls -l` |
| `la` | `eza -a`, falling back to `ls -la` |

### Helper functions

| Function | Purpose |
| --- | --- |
| `mkcd <directory>` | Create a directory and enter it |
| `ff [query]` | Find files, including hidden files, excluding `.git` |
| `fcd` | Select and enter a directory |
| `rgi <pattern> [path]` | Hidden-aware `ripgrep` with line numbers |
| `pspick` | Select or list processes |
| `extract <archive>` | Extract a supported archive |
| `dotfiles-shell-diagnostics` | Print effective shell/runtime diagnostics |

Examples:

```bash
mkcd sandbox
ff 'config'
fcd
rgi 'DOTFILES_' .
pspick
extract archive.tar.xz
```

Supported archive suffixes:

```text
.tar.gz  .tgz  .tar.bz2  .tbz2  .tar.xz  .txz
.tar     .zip  .gz       .bz2    .xz
```

`rgi` returns `10` when `ripgrep` is unavailable.

### History keys

| Key | Action |
| --- | --- |
| `Up` | Search backward using the current prefix |
| `Down` | Search forward using the current prefix |

Zsh uses Emacs key mode.

### Optional integrations

| Mode | Integration when installed |
| --- | --- |
| `normal`, `full` | Starship, zoxide, direnv |
| `full` only | Atuin |

Missing optional integrations must not make shell startup fail.

## System capability pack

After enabling `system` and restarting Zsh:

| Function | Command used |
| --- | --- |
| `sysports` | `ss -lntup`, falling back to `netstat -lntup` |
| `sysdisk` | `df -hT` |
| `sysjournal [count]` | `journalctl --no-pager -n <count>`; default `100` |

```bash
dot capability enable system
dot capability doctor system
exec zsh

sysports
sysdisk
sysjournal 50
```

## tmux

### Start, attach and inspect

```bash
tmux new-session -A -s main
tmux list-sessions
tmux source-file ~/.tmux.conf
tmux show-options -gqv @tmux_root
tmux display-message -p '#{config_file}'
```

The canonical config resolves its physical path and loads modular files. Local
overrides in `~/.tmux.conf.local` load last.

### Core keys

`Prefix` is `Ctrl+A`.

| Action | Key |
| --- | --- |
| Send literal prefix | `Ctrl+A`, then `Ctrl+A` |
| Horizontal split | `Ctrl+A`, then `\` |
| Vertical split | `Ctrl+A`, then `-` |
| New window in current directory | `Ctrl+A`, then `c` |
| Session chooser | `Ctrl+A`, then `s` |
| Resize left/down/up/right | `Ctrl+A`, then `h/j/k/l` |
| Zoom pane | `Ctrl+A`, then `m` |
| Open a horizontal Neovim pane | `Ctrl+A`, then `v` |
| Paste system clipboard | `Ctrl+A`, then `p` |
| Reload configuration | `Ctrl+A`, then `r` |
| Forward prefix to outer tmux | `Ctrl+A`, then `P` |
| Show runtime diagnostics | `Ctrl+A`, then `D` |

`h/j/k/l` resize keys are repeatable. `Prefix+P` forwards only when a nested
tmux server is detected.

`Ctrl+V` and `Shift+Insert` are deliberately not captured by tmux.

### Copy mode

tmux uses vi copy-mode keys.

| Action | Key |
| --- | --- |
| Begin selection | `v` |
| Copy and leave copy mode | `y` |

Copy uses the repository clipboard bridge. Over SSH, automatic
`set-clipboard` is disabled to reduce unintended clipboard propagation.

### Session persistence keys

These require TPM and tmux-resurrect.

| Action | Key |
| --- | --- |
| Save tmux-resurrect state | `Ctrl+A`, then `Ctrl+S` |
| Restore tmux-resurrect state | `Ctrl+A`, then `Ctrl+L` |

The bindings silently do nothing when the corresponding plugin script is
missing.

### TPM lifecycle

```bash
bash scripts/install-tmux-plugins.sh --check
bash scripts/install-tmux-plugins.sh --install
bash scripts/install-tmux-plugins.sh --update
```

`--check` returns `10` when TPM is absent. Core tmux remains usable without
plugins.

Configured plugins:

- TPM;
- tmux-sensible;
- vim-tmux-navigator;
- tmux-yank;
- tmux-resurrect.

### Saved session metadata

```text
bash tmux/session-manager.sh create <name> <directory> [description]
bash tmux/session-manager.sh list
bash tmux/session-manager.sh restore
bash tmux/session-manager.sh delete <name>
```

Examples:

```bash
bash tmux/session-manager.sh create notes "$HOME/study" "Study workspace"
bash tmux/session-manager.sh list
bash tmux/session-manager.sh restore
bash tmux/session-manager.sh delete notes
```

Session names allow letters, digits, `.`, `_` and `-`.

### Pomodoro helper

```text
bash tmux/pomodoro.sh start <sessions> <work-min> <break-min>
bash tmux/pomodoro.sh status
bash tmux/pomodoro.sh stop
```

Examples:

```bash
bash tmux/pomodoro.sh start 4 30 5
bash tmux/pomodoro.sh status
bash tmux/pomodoro.sh stop
```

Legacy positional syntax also works:

```bash
bash tmux/pomodoro.sh 4 30 5
```

Compact parser with defaults `4 × 30/5`:

```bash
bash tmux/pomocmd.sh
bash tmux/pomocmd.sh '6 25 5'
bash tmux/pomocmd.sh '6,25,5'
```

## Git configuration

### Identity

```bash
cp git/.gitconfig.local.example ~/.gitconfig.local
$EDITOR ~/.gitconfig.local
git config --show-origin --get-regexp '^user\.'
```

The tracked config intentionally contains no personal identity or signing key.

### Configured Git aliases

| Alias | Expansion |
| --- | --- |
| `git st` | `git status` |
| `git co` | `git checkout` |
| `git sw` | `git switch` |
| `git br` | `git branch` |
| `git ci` | `git commit` |
| `git ca` | `git commit -a` |
| `git d` | `git diff` |
| `git lg` | Graph, decorated, relative-date log for all refs |
| `git last` | Last commit with statistics |
| `git unstage <path>` | `git restore --staged <path>` |

### Configured defaults

- default branch: `main`;
- `pull.ff=only`;
- fetch prune and prune-tags;
- `push.autoSetupRemote=true`;
- `diff.algorithm=histogram`;
- `merge.conflictStyle=zdiff3`;
- `rerere.enabled=true` with autoupdate;
- merge and diff tool: `nvimdiff`;
- branch list sorted by recent commit;
- tag list sorted by version.

Inspect the active configuration:

```bash
git config --show-origin --list
git config --show-origin --get pull.ff
git config --show-origin --get-regexp '^alias\.'
```

### Safe daily sequence

```bash
git status
git diff
git diff --staged
git add <path>
git commit
git pull --ff-only
git push
```

Before discarding anything:

```bash
git status
git diff -- <path>
git restore --staged <path>
```

Use `git restore <path>` only after confirming that uncommitted changes may be
discarded.

### Explicit network operations

LazyGit auto-fetch is disabled. Use Git when exact network behavior matters:

```bash
git fetch --prune --prune-tags
git pull --ff-only
git push
```

## LazyGit and platform opener

Start LazyGit:

```bash
lazygit
```

Configured behavior:

- auto-fetch is disabled;
- UI auto-refresh is enabled;
- files edit in terminal Neovim;
- files and links open through `dotfiles-open`;
- self-update is disabled.

Test the opener:

```bash
command -v dotfiles-open
dotfiles-open .
dotfiles-open 'https://example.com'
```

`dotfiles-open` tries, in order:

1. `xdg-open`;
2. macOS `open`;
3. `wslview`;
4. `cmd.exe /c start`.

## Neovim

### Requirements and startup controls

- Neovim `0.11.3` or newer;
- Git in `PATH`;
- network access for the first lazy.nvim bootstrap unless bootstrap is disabled.

Environment controls:

| Variable | Meaning |
| --- | --- |
| `DOTFILES_NVIM_BOOTSTRAP=0` | Do not clone missing lazy.nvim |
| `DOTFILES_NVIM_STRICT=1` | Convert core startup errors into a failing exit |
| `DOTFILES_NVIM_EXTENDED=1` | Enable all optional Neovim capabilities |
| `DOTFILES_NVIM_CAPABILITIES=a,b` | Enable selected optional capabilities |
| `DOTFILES_NVIM_LANGUAGE_GROUPS=a,b` | Select LSP language groups |

Headless checks:

```bash
DOTFILES_NVIM_BOOTSTRAP=0 \
  nvim --headless -u nvim/.config/nvim/init.lua '+qa'

DOTFILES_NVIM_STRICT=1 DOTFILES_NVIM_BOOTSTRAP=0 \
  nvim --headless -u nvim/.config/nvim/init.lua '+qa'
```

Recovery commands:

```vim
:checkhealth
:Lazy sync
:Mason
:ConformInfo
:DotfilesCapabilities
```

### Core editing keys

`<leader>` is `Space`.

| Mode | Key | Action |
| --- | --- | --- |
| Visual | `J` | Move selection down |
| Visual | `K` | Move selection up |
| Visual | `<leader>p` | Paste without replacing the unnamed register |

### Telescope

| Key | Action |
| --- | --- |
| `<leader>ff` | Find files |
| `<leader>fg` | Live grep |
| `<leader>fb` | List buffers |
| `<leader>fh` | Search help tags |

### LSP

| Key | Action |
| --- | --- |
| `K` | Hover documentation |
| `gd` | Go to definition |
| `gD` | Go to declaration |
| `gi` | Go to implementation |
| `gr` | List references |
| `<leader>rn` | Rename symbol |
| `<leader>ca` | Code action |

Management commands:

```vim
:Mason
:MasonInstall
:MasonUninstall
:MasonLog
:LspInstall
:LspUninstall
```

Default language groups:

```text
core, python, web, shell
```

Available groups:

| Group | Servers |
| --- | --- |
| `core` | `lua_ls` |
| `python` | `pyright` |
| `web` | `ts_ls`, `html`, `cssls`, `jsonls`, `yamlls` |
| `shell` | `bashls` |
| `systems` | `clangd`, `rust_analyzer`, `gopls` |
| `infra` | `dockerls`, `terraformls` |

Example:

```bash
DOTFILES_NVIM_LANGUAGE_GROUPS=core,systems,infra nvim
```

### Formatting and linting

| Key | Action |
| --- | --- |
| `<leader>fm` | Format current buffer |
| `<leader>xl` | Manually lint current buffer, subject to the collision below |

Formatting runs on save with LSP fallback. Linting runs after buffer writes.

```vim
:ConformInfo
```

### Gitsigns

| Key | Action |
| --- | --- |
| `]c` | Next Git hunk |
| `[c` | Previous Git hunk |
| `<leader>hs` | Stage hunk |
| `<leader>hr` | Reset hunk |
| `<leader>hS` | Stage buffer |
| `<leader>hu` | Undo staged hunk |
| `<leader>hR` | Reset buffer |
| `<leader>hp` | Preview hunk |
| `<leader>hb` | Blame current line |
| `<leader>hB` | Toggle line blame |
| `<leader>hd` | Diff against index |
| `<leader>hD` | Diff against previous commit |
| `<leader>gtb` | Toggle signs |

### Diagnostics and lists

| Key | Action |
| --- | --- |
| `<leader>xx` | Workspace diagnostics |
| `<leader>xX` | Current-buffer diagnostics |
| `<leader>xq` | Quickfix list |
| `<leader>xl` | Location list, subject to the collision below |

### Debug inspection commands

These are core configuration diagnostics, not DAP controls.

| Command | Key | Action |
| --- | --- | --- |
| `:DebugDump [value]` | `<leader>dd` | Dump argument, word or visual range |
| `:DebugLoc` | `<leader>dl` | Dump call location |
| `:DebugExtmarks` | `<leader>de` | Inspect extmark leaks |
| `:DebugModules [filter]` | `<leader>dm` | Inspect loaded-module leaks |
| `:DotfilesCapabilities` | None | Show capability and LSP health |

### Optional capability keys

Enable selected capabilities:

```bash
DOTFILES_NVIM_CAPABILITIES=outline,terminal,undo_tree nvim
```

Enable all:

```bash
DOTFILES_NVIM_EXTENDED=1 nvim
```

| Capability | Commands and keys |
| --- | --- |
| `outline` | `:AerialToggle`, `<leader>a` |
| `session` | `:SessionSave`, `:SessionRestore`, `<leader>ws`, `<leader>wr` |
| `debug` | DAP: `<leader>dc/db/dn/di/do` |
| `git_ui` | `:Neogit`, `<leader>gg` |
| `test` | `:Neotest`, `<leader>tn/tf/to/tp` |
| `filetree` | `:Neotree`, `<leader>v` |
| `markdown_ui` | Render Markdown UI for Markdown buffers |
| `project_replace` | `:Spectre`, `<leader>S`, `<leader>sw` |
| `terminal` | `:ToggleTerm`, `<leader>ot/of/oh/ov` |
| `undo_tree` | `:UndotreeToggle`, `<leader>u` |

DAP key meanings:

| Key | Action |
| --- | --- |
| `<leader>dc` | Continue |
| `<leader>db` | Toggle breakpoint |
| `<leader>dn` | Step over |
| `<leader>di` | Step into |
| `<leader>do` | Step out |

Test key meanings:

| Key | Action |
| --- | --- |
| `<leader>tn` | Run nearest configured test |
| `<leader>tf` | Run current test file |
| `<leader>to` | Open test output |
| `<leader>tp` | Open test summary |

Terminal key meanings:

| Key | Action |
| --- | --- |
| `<leader>ot` | Toggle default terminal |
| `<leader>of` | Floating terminal |
| `<leader>oh` | Horizontal terminal |
| `<leader>ov` | Vertical terminal |

### Surround and jump keys

nvim-surround exposes:

| Mode | Keys |
| --- | --- |
| Normal | `ys`, `yS`, `yss`, `ySS`, `ds`, `cs` |
| Visual | `S`, `gS` |

Flash lazily maps normal-mode `s`, `S` and `r` when no user mapping exists.

### Known Neovim hazards

1. `<leader>xl` is declared by both nvim-lint and Trouble. The mapping loaded
   last wins; do not rely on both actions being reachable through that key.
2. Flash checks for existing mappings, not native Vim commands. Its `s`, `S`
   and `r` mappings can replace native normal-mode behavior after the plugin
   loads.
3. Neotest currently declares no adapters. Its UI and mappings can load, but
   language-specific execution requires adapter configuration.
4. Capability-gated keys do not exist unless their capability is enabled.
5. Zsh completion files currently cover top-level command names more thoroughly
   than delegated flags; this cheat sheet is the detailed syntax reference.

## WezTerm

### Modes

```bash
DOTFILES_WEZTERM_MODE=minimal wezterm
DOTFILES_WEZTERM_MODE=normal wezterm
DOTFILES_WEZTERM_MODE=aesthetic wezterm
```

- `minimal` disables asset discovery and media bindings.
- `normal` enables optional backgrounds and media controls.
- `aesthetic` uses the non-minimal feature set and raises the configured frame
  rate.

WezTerm attaches to or creates tmux session `main` when tmux is available,
otherwise it starts the configured login shell.

### Keys

| Action | Key |
| --- | --- |
| Open link under cursor | `Ctrl+Shift+L` |
| Select random background | `Ctrl+Shift+B` |
| Increase background brightness | `Ctrl+Shift+Up` |
| Decrease background brightness | `Ctrl+Shift+Down` |
| Play random track | `Ctrl+Shift+F6` |
| Stop the owned player | `Ctrl+Shift+F7` |
| Volume up | `Ctrl+Shift+F8` |
| Volume down | `Ctrl+Shift+F9` |
| Play default track | `Ctrl+Shift+F10` |

Only `Ctrl+Shift+L` is available in minimal mode.

### Environment variables

| Variable | Constraint or purpose |
| --- | --- |
| `DOTFILES_WEZTERM_MODE` | `minimal`, `normal` or `aesthetic` |
| `DOTFILES_WEZTERM_BG_DIR` | Background image directory |
| `DOTFILES_WEZTERM_MUSIC_DIR` | Music directory |
| `DOTFILES_WEZTERM_BG` | Explicit background image |
| `DOTFILES_WEZTERM_BRIGHTNESS` | `0.01` through `1.0` |
| `DOTFILES_WEZTERM_OPACITY` | `0.05` through `1.0` |
| `DOTFILES_WEZTERM_DEFAULT_TRACK` | Explicit default music track |
| `DOTFILES_WEZTERM_MEDIA_CONTROLLER` | Override media-controller path |

Example local configuration:

```bash
export DOTFILES_WEZTERM_MODE=normal
export DOTFILES_WEZTERM_BG_DIR="$HOME/Pictures/backgrounds"
export DOTFILES_WEZTERM_MUSIC_DIR="$HOME/Music"
export DOTFILES_WEZTERM_DEFAULT_TRACK="$HOME/Music/default.mp3"
export DOTFILES_WEZTERM_BRIGHTNESS=0.03
export DOTFILES_WEZTERM_OPACITY=0.30
```

Supported backgrounds:

```text
.png  .jpg  .jpeg  .webp
```

Supported music:

```text
.mp3  .flac  .wav  .m4a  .ogg  .opus
```

### Media controller CLI

Installed name:

```text
dotfiles-wezterm-media
```

Repository entrypoint:

```text
bash scripts/wezterm-media.sh
```

Complete syntax:

```bash
dotfiles-wezterm-media check mpv
dotfiles-wezterm-media check volume
dotfiles-wezterm-media play <track>
dotfiles-wezterm-media stop
dotfiles-wezterm-media volume up
dotfiles-wezterm-media volume down
dotfiles-wezterm-media state-set background <path>
dotfiles-wezterm-media state-set brightness <0.01-1.0>
```

The controller:

- owns a private `mpv` process and stops only that process;
- uses `wpctl`, falling back to `pactl`, for volume;
- stores state under the XDG state directory;
- validates readable paths and supported suffixes.

Validate the complete WezTerm contract:

```bash
bash scripts/check-wezterm.sh
```

## Direct maintenance entrypoints

These are useful when installed wrappers are unavailable or when debugging the
implementation.

| Entrypoint | Syntax or purpose |
| --- | --- |
| `bash scripts/dot ...` | Repository-local `dot` |
| `bash scripts/bootstrap.sh ...` | Link deployment |
| `bash scripts/packages.sh ...` | Ubuntu package transaction |
| `bash scripts/doctor.sh ...` | Diagnostics |
| `bash scripts/benchmark.sh [--json]` | Startup benchmark |
| `bash scripts/backup.sh ...` | Backup list and restore |
| `bash scripts/uninstall.sh ...` | Safe link removal |
| `bash scripts/open.sh <path-or-url>` | Platform opener |
| `bash scripts/wezterm-media.sh ...` | WezTerm media controller |
| `bash scripts/install-tmux-plugins.sh ...` | TPM lifecycle |
| `bash scripts/test.sh --profile ...` | Main static/runtime suite |
| `bash scripts/test-contracts.sh` | Repository contract tests |
| `bash scripts/security-check.sh` | Deterministic security baseline |
| `bash scripts/check-nvim-contract.sh` | Neovim configuration contract |
| `bash scripts/check-tmux-contract.sh` | tmux integration contract |
| `bash scripts/check-wezterm.sh` | WezTerm contract |

Use `--help` on scripts that expose it:

```bash
bash scripts/bootstrap.sh --help
bash scripts/packages.sh --help
bash scripts/doctor.sh --help
bash scripts/backup.sh --help
bash scripts/uninstall.sh --help
bash scripts/benchmark.sh --help
bash scripts/install-tmux-plugins.sh --help
```

## Validation and release gates

### Fast static gate

```bash
git diff --check
bash scripts/security-check.sh
bash scripts/test.sh --profile static
bash scripts/test-contracts.sh
```

### Full local gate

```bash
bash scripts/test.sh --profile full
bash scripts/test-contracts.sh
bash scripts/security-check.sh
bash scripts/check-wezterm.sh
```

With mise installed:

```bash
mise run doctor
mise run check
```

### Manual workstation acceptance

Automated checks cannot prove physical keyboard routing, GUI rendering,
Wayland/X11/OSC52 clipboard behavior, media playback or private asset paths.

After changing those areas:

1. Open WezTerm and confirm tmux session `main`.
2. Run `dotfiles-shell-diagnostics`.
3. Exercise both tmux split directions, copy, paste and reload.
4. Run `:checkhealth` and affected Neovim keymaps.
5. Open a file and URL from LazyGit.
6. Exercise WezTerm assets only with local files available.

## Security rules

Never commit:

- populated local overlays;
- personal Git identity or signing keys;
- access tokens or credentials;
- SSH/GPG private material;
- clipboard contents;
- private repository paths or hostnames;
- local media assets;
- generated state, caches or backups.

Run:

```bash
bash scripts/security-check.sh
git status --short
git diff --check
```

The security baseline checks mutable GitHub Actions references, credential-like
tracked files, private-key and token patterns, personal absolute paths and
tracked Git identity.

## Internal scripts and compatibility boundary

The following are implementation helpers, not stable user-facing APIs:

- tmux clipboard copy/paste scripts;
- tmux status and session cache builders;
- tmux cached metric updater;
- tmux random-note status helper;
- tmux failure-mode and test harness scripts;
- files beneath `scripts/lib/`;
- files beneath `scripts/tests/`;
- Neovim test fixtures;
- completion implementation files.

Call their owning public command instead:

| Internal area | Preferred interface |
| --- | --- |
| Link and backup internals | `dot install`, `dot backup`, `dot uninstall` |
| Context resolution | `dot env`, `dot status` |
| Project cache | `dev --refresh`, `dev --list` |
| Worktree internals | `gw` |
| Clipboard bridge | tmux copy mode and `Prefix+p` |
| Startup validation | `dot check`, contract scripts |

## Command-change audit checklist

When adding or changing a command, flag, keymap, profile or environment
variable:

1. update the implementation and its `--help`;
2. update `config/workflow.json` when dependencies, links or profiles change;
3. update Zsh completions for `dot`, `dev` or `gw`;
4. update this cheat sheet;
5. add or update deterministic contract tests;
6. run static, contract and security gates;
7. perform manual acceptance for GUI, clipboard or physical-key changes.

## Troubleshooting index

Start with:

```bash
dot doctor --explain
dot doctor --json | jq '.checks[] | select(.status != "ok")'
dotfiles-shell-diagnostics
```

Common targeted checks:

```bash
# Managed Zsh file
readlink -f ~/.zshrc
zsh -n ~/.zshrc

# tmux config ownership
tmux show-options -gqv @tmux_root
tmux display-message -p '#{config_file}'

# Git source and aliases
git config --show-origin --list
git config --show-origin --get-regexp '^alias\.'

# Neovim without network bootstrap
DOTFILES_NVIM_BOOTSTRAP=0 \
  nvim --headless -u nvim/.config/nvim/init.lua '+qa'

# Platform opener
dotfiles-open .

# WezTerm
bash scripts/check-wezterm.sh
```

See `docs/TROUBLESHOOTING.md` for failure-specific recovery and
`docs/MAINTENANCE.md` for the durable update policy.
