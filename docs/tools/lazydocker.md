# LazyDocker

## Purpose

LazyDocker is the container inspection TUI for this repo.

## Why This Setup Exists

- give container work a focused review surface
- keep Docker socket access explicit
- avoid extra wrapper scripts around the core workflow

## Key Features Actually Enabled

| Feature | Notes |
| --- | --- |
| Entrypoint | `docker compose run --rm lazydocker` |
| Docker socket | Mounted from `/var/run/docker.sock` |
| Config persistence | Mounted into `~/.config/jesseduffield/lazydocker` |
| Terminal mode | `TERM=xterm-256color` and `COLORTERM=truecolor` |

## Important Keybindings / Aliases

LazyDocker uses its built-in keys. The important part of this repo is the compose entrypoint rather than custom remapping.

| Key | Meaning |
| --- | --- |
| `?` | Help |
| `q` | Quit |
| `enter` | Open or inspect the selection |

## Typical Usage Flow

1. Run the compose command from the repo root.
2. Inspect containers, services, logs, or exec shells.
3. Return to Neovim or tmux when the problem turns into code or config work.

## Productivity Tips

- keep LazyDocker as the inspection layer, not the orchestration layer
- use a tmux pane alongside it so logs and commands stay visible
- treat the compose file as the source of truth for how the TUI is launched

## Common Pitfalls

- forgetting the Docker socket mount
- assuming the config is generated somewhere else
- launching it outside the repo root and then wondering where the service definition lives

## Related Tools

- [Docker workflow](../workflow/docker-workflow.md)
- [tmux](tmux.md)
