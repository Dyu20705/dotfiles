# Dependencies

The machine-readable source of truth is `config/workflow.json`. Run
`bash scripts/doctor.sh --profile <profile>` after changing dependencies.

## Required by profile

| Tool | Minimal | Normal | Full | Notes |
| --- | --- | --- | --- | --- |
| Bash | required | required | required | bootstrap and diagnostics |
| Git | required | required | required | repository workflow |
| jq | optional | required | required | JSON state and manifests |
| Zsh | optional | required | required | primary interactive shell |
| tmux | optional | required | required | session layer |
| Neovim | optional | required | required | version 0.11.3 or newer |
| WezTerm | optional | optional | required | terminal entrypoint |

## Optional feature tools

| Area | Tools |
| --- | --- |
| Shell prompt/navigation | `starship`, `zoxide`, `fzf`, `direnv`, `atuin`, `eza` |
| Clipboard | `wl-paste`, `xclip`, `pbpaste`, PowerShell on WSL |
| Neovim formatting | `stylua`, `rustfmt`, `clang-format`, `black` |
| Neovim linting | `luacheck`, `clippy`, `clang-tidy`, `pylint` |
| WezTerm aesthetics | `mpv`, `pkill`, `pactl`, local image/audio files |
| Containers | Docker Engine and Docker Compose v2 |
| Validation | `shellcheck`, `yamllint`, Lua compiler |

## Platform notes

- `timeout` is not assumed. Clipboard and status helpers use `gtimeout` when
  available and otherwise run the local command directly.
- LazyGit uses `dotfiles-open`, which selects `xdg-open`, `open`, `wslview` or
  `cmd.exe` at runtime.
- Linux-only `/proc` collectors stay quiet on macOS.
- Git identity is stored in `~/.gitconfig.local`, not in the public repository.
