# Dotfiles Cheat Sheet

This is the operational reference for the personal Zsh-first configuration.
Commands are run from the repository root unless stated otherwise.

## Operating model

```text
WezTerm -> tmux -> Zsh -> project commands
                   |-> Neovim
                   |-> Git / LazyGit
```

- Zsh is the only managed interactive shell.
- Bash remains installed because repository management and validation scripts
  use `#!/usr/bin/env bash`.
- Git is the canonical implementation. LazyGit is an optional terminal UI over
  Git and inherits the tracked Git configuration.
- Personal identity, paths, assets and machine-only commands stay outside Git.

## Install and update

| Goal | Command |
| --- | --- |
| Preview packages | `bash scripts/dot packages --profile normal --dry-run` |
| Install packages | `bash scripts/dot packages --profile normal --yes` |
| Deploy normal profile | `bash scripts/dot install --profile normal` |
| Deploy full profile | `bash scripts/dot install --profile full` |
| Reapply links | `dot link --profile normal` |
| Diagnose | `dot doctor` |
| Diagnose as JSON | `dot doctor --json` |
| Inspect effective context | `dot env --json \| jq` |
| Update checkout | `git pull --ff-only` |
| Validate after update | `dot check full` |

Recommended update sequence:

```bash
cd ~/src/dotfiles
git pull --ff-only
dot install --profile normal
dot doctor
dot check full
```

## Profiles and contexts

| Profile | Intended use | Managed interactive shell |
| --- | --- | --- |
| `minimal` | Recovery commands and Git configuration | None |
| `normal` | Daily Zsh, tmux and Neovim workflow | Zsh |
| `full` | Normal plus WezTerm, LazyGit and optional helpers | Zsh |

Machine contexts are `desktop`, `laptop`, `server` and `remote`. SSH and CI
sessions reduce a normal shell session to minimal behavior unless explicitly
overridden.

```bash
DOTFILES_PROFILE=normal dot env
DOTFILES_CONTEXT=laptop dot env
DOTFILES_SHELL_MODE=minimal zsh
DOTFILES_SHELL_MODE=full zsh
dotfiles-shell-diagnostics
```

## Private local overlays

Tracked examples contain placeholders only.

| Purpose | Local path |
| --- | --- |
| Git identity/signing | `~/.gitconfig.local` |
| Profile, context and private paths | `~/.config/dotfiles/local.env` |
| Zsh-only local commands | `~/.config/dotfiles/shell.local` |
| tmux machine overrides | `~/.tmux.conf.local` |
| Neovim local Lua | `~/.config/nvim/lua/local.lua` |
| WezTerm local Lua | `~/.config/wezterm/local.lua` |

Create Git identity:

```bash
cp git/.gitconfig.local.example ~/.gitconfig.local
$EDITOR ~/.gitconfig.local
git config --show-origin --get-regexp '^user\.'
```

Never commit the populated local files.

## `dot` command

| Command | Purpose |
| --- | --- |
| `dot status` | Show repository and deployment status |
| `dot install --profile <name>` | Deploy the selected profile |
| `dot link --profile <name>` | Recreate managed links |
| `dot packages --profile <name>` | Preview or install Ubuntu packages |
| `dot doctor` | Check commands, versions and managed links |
| `dot check static` | Syntax, manifest, security and configuration checks |
| `dot check runtime` | Isolated runtime smoke tests |
| `dot check full` | Static plus runtime checks |
| `dot bench [--json]` | Local startup measurements |
| `dot backup list` | List recorded deployment backups |
| `dot backup restore <id>` | Restore a deployment backup |
| `dot uninstall --profile <name>` | Remove links still owned by this checkout |
| `dot env [--json]` | Show effective non-secret configuration |
| `dot capability list` | List optional personal capability packs |

## Backup, restore and uninstall

```bash
dot backup list
dot backup restore <id>

dot uninstall --profile normal --dry-run
dot uninstall --profile normal
```

Restore refuses changed paths unless `--force` is explicit. Uninstall removes
only symlinks that still point into this checkout.

## Zsh

### Built-in aliases

| Alias | Expansion |
| --- | --- |
| `..` | `cd ..` |
| `...` | `cd ../..` |
| `vi`, `vim` | `nvim` |
| `gs` | `git status` |
| `gd` | `git diff` |
| `gl` | `git log --oneline --decorate --graph` |
| `reload` | `exec zsh` |
| `ll` | `eza -la` or `ls -l` |
| `la` | `eza -a` or `ls -la` |

### Helper functions

| Function | Purpose |
| --- | --- |
| `mkcd <dir>` | Create a directory and enter it |
| `ff [query]` | Find files with `fd`/`fdfind`, falling back to `find` |
| `fcd` | Select and enter a directory, using `fzf` when available |
| `rgi <pattern> [path]` | Hidden-aware `ripgrep` search excluding `.git` |
| `pspick` | Inspect/select processes |
| `extract <archive>` | Extract common archive formats |

Optional integrations load only when installed: `starship`, `zoxide`,
`direnv`, `atuin`, `eza`, `fzf`, `fd`/`fdfind` and `bat`/`batcat`.

## Projects and tmux sessions

```bash
dev --list
dev <query>
dev .
dev --refresh
dev --kill <name>
```

`dev` discovers Git repositories under `DOTFILES_PROJECT_DIRS` and reuses one
stable tmux session per canonical project path.

### tmux keys

`Prefix` is `Ctrl+A`.

| Action | Key |
| --- | --- |
| Send literal prefix | `Ctrl+A`, then `Ctrl+A` |
| Horizontal split | `Ctrl+A`, then `\` |
| Vertical split | `Ctrl+A`, then `-` |
| New window in current directory | `Ctrl+A`, then `c` |
| Session chooser | `Ctrl+A`, then `s` |
| Resize pane | `Ctrl+A`, then `h/j/k/l` |
| Zoom pane | `Ctrl+A`, then `m` |
| Paste system clipboard | `Ctrl+A`, then `p` |
| Begin copy selection | Copy mode, then `v` |
| Copy selection | Copy mode, then `y` |
| Reload configuration | `Ctrl+A`, then `r` |
| Diagnostics | `Ctrl+A`, then `D` |

`Ctrl+V` is deliberately not captured by tmux.

## Git, worktrees and LazyGit

### Division of responsibility

| Tool | Use it for |
| --- | --- |
| Git CLI | Automation, exact commands, recovery, scripts, rebases and advanced operations |
| LazyGit | Interactive staging, history browsing, branch navigation and routine commits |
| `gw` | Safe local worktree creation/open/removal |

There is no configuration conflict: LazyGit invokes Git and respects
`git/.gitconfig`. Automatic fetching is disabled in LazyGit, while the Git
configuration owns fetch, pull, merge and rerere semantics.

### Git defaults

- default branch: `main`
- `pull.ff=only`
- fetch prune and prune-tags
- `push.autoSetupRemote=true`
- `diff.algorithm=histogram`
- `merge.conflictStyle=zdiff3`
- `rerere.enabled=true`
- merge/diff tool: `nvimdiff`

### Worktrees

```bash
gw list
gw status
gw new feature-name main
gw open feature-name
gw remove feature-name
gw prune
```

`gw` never fetches, merges or deletes branches. Dirty worktree removal requires
an explicit `--force`.

## Neovim

Stable namespaces:

| Namespace | Purpose |
| --- | --- |
| `<leader>f` | Find and search |
| `<leader>g` | Focused Git operations |
| `<leader>t` | Tests when enabled |
| `<leader>d` | Debugging when enabled |
| `<leader>x` | Diagnostics and lint |
| `<leader>o` | Optional open/terminal tools |

Useful recovery commands:

```vim
:checkhealth
:Lazy sync
:Mason
:ConformInfo
```

Headless diagnostic:

```bash
DOTFILES_NVIM_BOOTSTRAP=0 \
  nvim --headless -u nvim/.config/nvim/init.lua '+qa'
```

## WezTerm

WezTerm starts or attaches to the tmux session named `main` when tmux is
available.

| Action | Key |
| --- | --- |
| Open link under cursor | `Ctrl+Shift+L` |
| Select random background | `Ctrl+Shift+B` |
| Increase background brightness | `Ctrl+Shift+Up` |
| Decrease background brightness | `Ctrl+Shift+Down` |
| Play random track | `Ctrl+Shift+F6` |
| Stop owned player | `Ctrl+Shift+F7` |
| Volume up | `Ctrl+Shift+F8` |
| Volume down | `Ctrl+Shift+F9` |
| Play default track | `Ctrl+Shift+F10` |

Local asset variables:

```bash
export DOTFILES_WEZTERM_BG_DIR="$HOME/Pictures/backgrounds"
export DOTFILES_WEZTERM_MUSIC_DIR="$HOME/Music"
export DOTFILES_WEZTERM_DEFAULT_TRACK="$HOME/Music/default.mp3"
```

Media controls require `mpv`; volume uses `wpctl` and falls back to `pactl`.

## Validation and security

```bash
dot check static
dot check runtime
dot check full
bash scripts/test-contracts.sh
bash scripts/security-check.sh
bash scripts/check-wezterm.sh
```

Before pushing any change:

```bash
git diff --check
bash scripts/security-check.sh
bash scripts/test.sh --profile static
bash scripts/test-contracts.sh
```

Never publish clipboard contents, populated local overlays, private repository
paths, hostnames, access tokens, private keys or generated state.
