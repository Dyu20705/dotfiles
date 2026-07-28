# Dotfiles Cheat Sheet

| Goal | Command or key | Scope | Notes |
| --- | --- | --- | --- |
| Install links | `dot install --profile normal` | Ubuntu | Run `dot packages --dry-run` first |
| Diagnose | `dot doctor` | All profiles | JSON: `dot doctor --json` |
| Run checks | `dot check full` | Repository | Static plus isolated runtime checks |
| Inspect environment | `dot env --json` | All | Does not print secrets |
| List backups | `dot backup list` | All | Restore with `dot backup restore <id>` |
| Find projects | `dev --list` | Normal/full | Uses configured local roots |
| Resume a project | `dev <query>` | Normal/full | Reuses one tmux session |
| New worktree | `gw new feature main` | Git repository | Stored under XDG data |
| Remove worktree | `gw remove feature` | Git repository | Refuses dirty worktrees |
| tmux prefix | `Ctrl+A` | tmux | Reload: `Ctrl+A`, then `r` |
| Search files | `<leader>f` | Neovim | Telescope/find namespace |
| Emergency mode | `DOTFILES_PROFILE=minimal dot doctor` | Recovery/SSH | No GUI or capability packs |
