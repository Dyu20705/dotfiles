# Docker Workflow

## Purpose

Docker support is intentionally small. The repo gives you one explicit LazyDocker entrypoint and keeps container work inside the same terminal workflow.

## Why This Setup Exists

- inspect containers without leaving the terminal stack
- avoid custom wrappers around Docker itself
- keep container config local and reproducible

## What Is Enabled

| Component | Role |
| --- | --- |
| `docker-compose.yaml` | Runs LazyDocker with the Docker socket mounted |
| LazyDocker config dir | Persisted under `~/.config/jesseduffield/lazydocker` by Compose |
| Neovim Docker LSP | `dockerls` for Dockerfile editing |

## Typical Flow

1. Open a tmux pane for container work.
2. Run `docker compose run --rm lazydocker` from the repo root.
3. Inspect containers, logs, exec shells, or compose services.
4. Edit Dockerfiles in Neovim with LSP support.

## Useful Commands

| Command | Purpose |
| --- | --- |
| `docker compose run --rm lazydocker` | Start LazyDocker |
| `nvim Dockerfile` | Open a Dockerfile with LSP support |
| `docker ps` | Check container state directly when needed |

## Productivity Tips

- keep LazyDocker for inspection, not as a replacement for Docker CLI fluency
- use a tmux pane for logs while another pane stays in the editor
- keep container-specific notes in Markdown if you need to revisit them later

## Common Pitfalls

- forgetting that the service needs access to `/var/run/docker.sock`
- assuming the Docker workflow adds extra automation around compose files
- running container work in a shell mode that has unnecessary remote restrictions

## Related Guides

- [Terminal workflow](terminal-workflow.md)
- [Neovim workflow](neovim-workflow.md)
- [LazyDocker tool guide](../tools/lazydocker.md)
