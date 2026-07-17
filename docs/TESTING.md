# Testing

## Local gates

```bash
bash scripts/test.sh --profile static
bash scripts/test.sh --profile runtime
```

Static checks cover shell and Lua syntax, ShellCheck, JSON/YAML parsing,
Compose rendering, hard-coded personal paths and simple Neovim keymap
collisions.

Runtime checks create temporary homes and isolated processes where possible:

- Bash interactive startup in normal mode.
- Zsh interactive startup in normal mode.
- tmux startup, prefix assertion and config reload on a dedicated socket.
- Neovim headless config load with network bootstrap disabled.
- WezTerm config parsing through `show-keys` when installed.
- Git config parsing in a temporary home and repository.

## Manual end-to-end acceptance

Run these after changes affecting terminal behavior:

1. Open WezTerm and confirm it attaches to the `main` tmux session.
2. Confirm the shell reports `mode=normal` inside tmux.
3. Create horizontal and vertical panes and verify their working directory.
4. Enter Neovim Visual Block mode with `Ctrl+V`.
5. Paste system clipboard content with `Prefix+p` and `Shift+Insert`.
6. Navigate between Neovim splits and tmux panes.
7. Run tests with `<leader>t...` and terminals with `<leader>o...`.
8. Start a DAP session and verify F5/F10/F11/F12 reach Neovim.
9. Stage and commit with Git, Neogit or LazyGit.
10. Detach, attach and reload tmux without errors.
11. Repeat in SSH and with optional tools removed from `PATH`.
12. On macOS, verify clipboard and `dotfiles-open` behavior.

## Clean-machine acceptance

Use a disposable VM or container home:

```bash
bash scripts/bootstrap.sh --profile normal --dry-run
bash scripts/bootstrap.sh --profile normal
bash scripts/doctor.sh --profile normal
```

The install must be idempotent, must not overwrite files without backup and
must keep shell startup quiet when optional integrations are absent.

## Performance regression checks

```bash
nvim --startuptime /tmp/nvim-startup.log '+qa'
bash tmux/diagnostics.sh startup
```

Track warm and cold startup separately. Avoid adding network calls or project
scans to shell startup, tmux redraws or Neovim `TextChanged` events.
