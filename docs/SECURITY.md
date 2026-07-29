# Security Model

- Git identity, signing keys, tokens, hostnames and personal asset paths stay in
  local overlays.
- Bootstrap refuses targets outside `HOME` and records every mutation.
- Restore refuses changed paths unless `--force` is explicit.
- Worktree removal refuses dirty directories unless `--force` is explicit.
- GitHub Actions use least-privilege permissions and immutable action SHAs.
- Clipboard helpers never log payloads.
- Mounting `/var/run/docker.sock` grants powerful Docker daemon control; run only
  trusted images and prefer the native LazyDocker binary.

`scripts/security-check.sh` is the repository-owned deterministic baseline.
External scanners may supplement it but do not replace review.
