# Security Model

## Public-repository boundary

The tracked repository may contain reusable configuration and placeholder
examples only. The following must remain outside Git:

- Git name, email and signing key;
- access tokens, API keys, private keys and credentials;
- hostnames and private absolute paths;
- clipboard contents and private repository data;
- local backgrounds, music and other personal assets;
- caches, histories, logs, backups and runtime state.

Use `~/.gitconfig.local`, `~/.config/dotfiles/local.env` and other documented
local overlays for machine-specific values.

## Safeguards

- Bootstrap rejects deployment targets outside `HOME`.
- Every mutating deployment records a backup manifest.
- Restore preflights conflicts and requires `--force` for changed paths.
- Worktree removal refuses dirty directories unless explicitly forced.
- GitHub Actions use least-privilege permissions and immutable action SHAs.
- Clipboard helpers do not log payloads.
- LazyGit auto-fetch is disabled; Git remains the canonical operation layer.
- The optional LazyDocker helper mounts `/var/run/docker.sock`, which grants
  powerful host control. Prefer a native LazyDocker binary and run only trusted
  images.

## Secret scan

Run before every push:

```bash
bash scripts/security-check.sh
```

The deterministic baseline checks private-key markers, common token formats,
tracked credential-like filenames, personal Git identity, signing keys,
personal absolute paths and mutable GitHub Action references.

External scanners such as Gitleaks may supplement this baseline. They do not
replace reviewing the actual diff:

```bash
git diff --check
git diff --cached
git status --short
```

## Exposure response

When a real secret is committed:

1. Revoke or rotate it immediately.
2. Remove it from the current tree.
3. Purge it from Git history when exposure requires it.
4. Force-update affected refs only after preserving a safe recovery point.
5. Re-run the repository security scan.
6. Never post the secret itself in an issue, pull request or log.
