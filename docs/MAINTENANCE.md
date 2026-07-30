# Maintenance

## Routine update

```bash
cd ~/src/dotfiles
git pull --ff-only
dot install --profile normal
dot doctor
dot check full
```

Use the full profile only on the machine where WezTerm, LazyGit and optional
helpers are wanted.

## Validation gates

```bash
bash scripts/test.sh --profile static
bash scripts/test.sh --profile runtime
bash scripts/test-contracts.sh
bash scripts/security-check.sh
```

`mise run check` runs the main validation suites when `mise` is installed.

Static checks cover syntax, manifest safety, links, hard-coded personal paths,
keymap contracts, Git configuration, clipboard streaming and config parsing.
Runtime checks use temporary homes and isolated processes where possible.

## Manual checks

Automated CI cannot prove physical keyboard routing, GUI rendering, real
Wayland/X11/OSC52 clipboard behavior, media playback or private asset paths.
After changing those areas, validate on the actual workstation:

1. Open WezTerm and confirm it attaches to tmux session `main`.
2. Run `dotfiles-shell-diagnostics` and confirm `shell=zsh`.
3. Create both tmux split directions and reload the config.
4. Test tmux copy/paste on the active display server.
5. Start Neovim, run `:checkhealth` and exercise affected keymaps.
6. Open files and links from LazyGit.
7. Test WezTerm background/media controls only with local assets available.

## Dependencies

`config/workflow.json` is the machine-readable source of truth.

- Bash, Git and `jq`: management/runtime baseline.
- Zsh, tmux and Neovim: normal profile.
- WezTerm: full profile.
- LazyGit, Docker, `fzf`, `zoxide`, `starship`, `direnv` and `atuin`: optional.

Use:

```bash
dot packages --profile normal --dry-run
dot doctor --json | jq '.checks[] | select(.status != "ok")'
```

## Local benchmarks

Performance numbers are machine-specific and are not published as release
artifacts.

```bash
dot bench
dot bench --json | jq
```

Use the results only to detect regressions on the same machine.

## Dependency automation

Dependabot and the controlled dependency-refresh workflow may open owner-only
maintenance pull requests. Review lock changes and run the complete validation
gates before merging. No dependency update is auto-merged.

## Documentation policy

Keep only durable operator, architecture, maintenance, security and
troubleshooting documentation. Do not commit transient implementation plans,
agent prompts, release evidence, personal notes or generated benchmark reports.
