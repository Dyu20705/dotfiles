# Git and Worktree Workflow

Personal name, email and signing values belong in `~/.gitconfig.local`.

```bash
cp git/.gitconfig.local.example ~/.gitconfig.local
$EDITOR ~/.gitconfig.local
```

Create a focused worktree from a repository:

```bash
gw new issue-123 main
gw status
gw open issue-123
```

Removal is intentionally strict:

```bash
gw remove issue-123
# Dirty worktrees require an explicit decision:
gw remove issue-123 --force
```

`gw` never fetches automatically and never deletes a branch. Use plain Git for
advanced operations; `gw` is only a safety-oriented convenience layer.
