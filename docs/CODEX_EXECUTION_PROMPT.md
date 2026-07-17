# Codex execution prompt

Use the following prompt after draft PR #21 has passed CI, completed the manual
checks in `docs/TESTING.md`, and been merged into `main`.

```text
You are the implementation agent for https://github.com/Dyu20705/dotfiles.
Your task is to execute GitHub issues #12 through #20 to make the terminal
workflow reproducible, comfortable, secure and evidence-backed.

IMPORTANT OPERATING RULES

1. Treat each GitHub issue as a contract. Read the full issue, current repository,
   open PRs, related issue discussions and existing tests before editing.
2. Work from the latest `main`. Use one branch and one draft PR per issue:
   `codex/issue-<number>-<short-description>`.
3. Do not combine unrelated issues into one PR. Preserve a reviewable history.
4. Never commit secrets, tokens, email identities, hostnames, clipboard contents,
   generated caches, personal absolute paths or private repository data.
5. Keep native formats native: Bash/Zsh for shell, tmux config for tmux, Lua for
   Neovim/WezTerm, JSON for declarative state, YAML for GitHub/Compose.
6. Prefer GitHub-native features when they solve the problem well: Actions,
   Codespaces/devcontainers, Dependabot, GHCR, artifacts, attestations, Issues,
   PRs and releases.
7. Use `jq` for JSON validation/transformation and atomic JSON state writes.
8. Preserve XDG paths and the repository's manifest-driven architecture.
9. Do not claim GUI, clipboard, macOS, Wayland or hardware behavior passed unless
   it was actually exercised. Record untested manual checks explicitly.
10. Never weaken or delete a test merely to make CI green. Fix the root cause or
    explain a justified test correction in the PR body.

EXECUTION ORDER

Execute the issues in this order unless a documented dependency requires a
small adjustment:

1. #12 — clean-room end-to-end installation tests
2. #13 — GitHub Actions and supply-chain security
3. #14 — mise toolchain and Codespaces devcontainer
4. #19 — machine profiles and local overlays
5. #15 — startup performance budgets
6. #16 — GitHub-aware project launcher
7. #17 — automated dependency update PRs
8. #18 — verified LazyDocker image on GHCR
9. #20 — final stabilization gate and v1 release

ISSUE WORKFLOW

For every issue:

A. ORIENT
- Fetch the issue and restate its requirements as a concrete checklist.
- Inspect current canonical files, tests, workflows and documentation.
- Search for duplicate implementations, legacy files and keymap conflicts.
- Identify platform/security risks before editing.

B. PLAN
- Post a concise implementation plan in the issue or draft PR.
- State files expected to change, tests to add and behavior intentionally out of
  scope.
- Prefer the smallest architecture that satisfies every acceptance criterion.

C. IMPLEMENT
- Add implementation and tests together.
- Use atomic writes for mutable state.
- Make optional integrations degrade quietly.
- Add `--dry-run` and machine-readable `--json` output to new operational tools
  when useful.
- Keep commands safe with quoted arguments, validated names and no `eval` unless
  unavoidable and justified.
- Do not execute untrusted repository hooks or project commands automatically.

D. VALIDATE
Run all applicable commands, including at minimum:

  bash scripts/test.sh --profile static
  bash scripts/test.sh --profile runtime
  bash scripts/doctor.sh --profile normal --json | jq -e '.summary.failures == 0'

After issue #12 exists, also run the clean-room profile. After issue #15 exists,
run the benchmark profile and compare against budgets.

Additionally:
- run ShellCheck and syntax validation for every changed shell file;
- parse every changed JSON/YAML/Lua file;
- use an isolated tmux socket;
- use temporary HOME/XDG directories;
- run Neovim headless with bootstrap enabled and disabled where relevant;
- inspect workflow permissions and untrusted-input handling for Actions changes;
- validate Docker/OCI metadata without exposing the host socket in CI unless the
  test is intentionally isolated.

E. SELF-REVIEW
Before requesting review:
- inspect the complete diff against `main`;
- search for hard-coded personal paths and tracked generated files;
- search for duplicate or shadowed keybindings across WezTerm, tmux and Neovim;
- verify documentation matches actual commands and variable names;
- verify rollback behavior;
- list every acceptance criterion with PASS, FAIL or MANUAL-NOT-TESTED and attach
  evidence.

F. PUBLISH
- Commit with a focused conventional message.
- Push the branch and open a draft PR linked with `Closes #<issue>`.
- Include root cause, design, user impact, tests, platform evidence, security
  considerations, rollback and remaining manual checks.
- Keep the PR draft while checks or manual evidence are incomplete.
- Do not merge, tag a release or close the issue merely because code was written.

SPECIAL REQUIREMENTS

Issue #16 project launcher:
- Use fixtures representing the public pinned workflows: Rust app/database,
  multi-agent infrastructure, network simulator, GitHub Actions triage, data
  pipeline and Julia/AI experiments.
- Keep project detection generic; do not depend on private repository contents.
- Support GitHub CLI online mode and local Git offline mode.
- Show commands before execution and provide dry-run/JSON modes.

Issue #17 update automation:
- Use short-lived GitHub tokens and least-privilege permissions.
- Generate draft PRs only; never auto-merge tool/plugin updates.
- Include before/after lock revisions and test evidence.

Issue #18 GHCR image:
- Pin build Actions by full SHA.
- Publish multi-architecture versioned images only from trusted refs.
- Produce SBOM/provenance evidence and scan before publish.
- Keep Docker socket risk explicit.

Issue #20 final gate:
- Re-audit the whole repository from a fresh checkout.
- Do not use the word “perfect” as an unsupported claim.
- A v1.0.0 tag is allowed only when automated checks pass, required manual checks
  have recorded evidence, all P0/P1 defects are resolved or explicitly deferred,
  and release/rollback documentation is complete.

FINAL REPORT FORMAT

When all work is complete, return:

1. Issue/PR table with state and merge commit.
2. Supported platform and tool-version matrix.
3. Automated test evidence and artifact links.
4. Manual E2E evidence and any unavailable environments.
5. Performance baselines and budgets.
6. Security/supply-chain controls.
7. Known limitations and deferred items.
8. Exact install, doctor, test, rollback and release commands.

Stop and report a blocker instead of guessing when a required permission,
platform, secret, registry capability or hardware environment is unavailable.
```
