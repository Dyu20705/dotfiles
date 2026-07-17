# Testing

## Local gates

```bash
bash scripts/test.sh --profile static
bash scripts/test.sh --profile runtime
bash scripts/test.sh --profile full
```

Static checks cover:

- Bash, Zsh and Lua syntax plus ShellCheck.
- Manifest schema, profile references, unique targets and HOME-only deployment.
- Doctor JSON structure and failure semantics for regular files, unknown required
  versions and missing sources.
- Bootstrap dry-run behavior and checkout immutability.
- JSON/YAML/Compose parsing.
- Personal-path and generated-state guards.
- Critical WezTerm/tmux/Neovim keymap contracts.
- Git's built-in `nvimdiff` merge-tool contract.
- Clipboard streaming through a fake provider and isolated tmux client.

Runtime checks create temporary homes and isolated processes where possible:

- Bash and Zsh startup in local, tmux, CI and invalid-mode fixtures.
- tmux startup and reload on a dedicated socket.
- machine-local tmux overrides applied after canonical layers.
- Neovim headless core config load with network bootstrap disabled.
- WezTerm config parsing through `show-keys` when installed.
- Git config parsing in a temporary home and repository.

A skipped optional application is not proof that its runtime behavior works. Record
that item as `MANUAL-NOT-TESTED` until it is exercised in the target environment.

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
10. Open a real file and URL from the LazyGit TUI.
11. Detach, attach and reload tmux without errors.
12. Repeat in SSH and with optional tools removed from `PATH`.
13. On macOS, verify clipboard and `dotfiles-open` behavior.
14. Exercise aesthetic-mode background and media controls only when their assets
    and external commands are intentionally installed.

Never copy real clipboard contents, tokens, private paths or repository data into
public test logs or GitHub Actions artifacts.

## Clean-machine acceptance

Use a disposable VM, container or temporary HOME/XDG tree:

```bash
bash scripts/bootstrap.sh --profile normal --dry-run
bash scripts/bootstrap.sh --profile normal
bash scripts/bootstrap.sh --profile normal
bash scripts/doctor.sh --profile normal --json \
  | jq -e '.summary.failures == 0'
```

The install must be idempotent, must not overwrite files without backup and must
keep shell startup quiet when optional integrations are absent. Replace one
managed symlink with a harmless regular fixture and confirm doctor reports
`not-symlink` as a failure. Use a copied manifest with an out-of-HOME target and
confirm bootstrap rejects it without creating or moving anything.

## Performance regression checks

```bash
nvim --startuptime /tmp/nvim-startup.log '+qa'
bash tmux/diagnostics.sh startup
```

Track warm and cold startup separately. Avoid adding network calls or project
scans to shell startup, tmux redraws or Neovim `TextChanged` events.
