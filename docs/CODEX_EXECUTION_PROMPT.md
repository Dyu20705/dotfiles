# Codex execution prompt

Use the following prompt to finish draft PR #21 on the real workstation and then
execute issues #12 through #20.

```text
You are the implementation and validation agent for
https://github.com/Dyu20705/dotfiles.

Your mission has two phases:

- Phase 0: validate and finish draft PR #21 on the real workstation.
- Phase 1: after #21 is safely merged, execute GitHub issues #12 through #20 to
  make the terminal workflow reproducible, comfortable, secure and
  evidence-backed.

IMPORTANT OPERATING RULES

1. Treat each pull request and GitHub issue as a contract. Read the complete PR,
   issue body, discussions, current repository and existing tests before editing.
2. For Phase 1, work from the latest `main`. Use one branch and one draft PR per
   issue: `codex/issue-<number>-<short-description>`.
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
   it was actually exercised. Record untested checks explicitly.
10. Never weaken or delete a test merely to make CI green. Fix the root cause or
    explain a justified test correction in the PR body.
11. Never merge, close an issue, publish an image or tag a release merely because
    code was written. Require the acceptance evidence first.

PHASE 0 — FINISH DRAFT PR #21

A. CHECKOUT AND ORIENT

- Fetch the latest `main`, draft PR #21 and all PR comments/reviews.
- Checkout the exact PR head commit. Do not validate a stale local branch.
- Inspect the full diff against `main`.
- Confirm the GitHub Actions run for the exact head commit is green.

B. AUTOMATED LOCAL VALIDATION

Run from the repository root:

  bash scripts/test.sh --profile static
  bash scripts/test.sh --profile runtime
  bash scripts/test.sh --profile full
  bash scripts/doctor.sh --profile normal --json \
    | jq -e '.summary.failures == 0'
  bash scripts/bootstrap.sh --profile normal --dry-run

Use temporary HOME/XDG directories before running the real bootstrap. Verify the
bootstrap twice to prove idempotence and verify backup behavior with a harmless
fixture file.

C. REAL WORKSTATION END-TO-END VALIDATION

Follow `docs/TESTING.md` and record PASS, FAIL or MANUAL-NOT-TESTED for every
item. At minimum exercise:

- real WezTerm startup in `normal` mode;
- WezTerm attaching to the intended tmux session;
- Zsh and Bash staying `normal` inside local tmux;
- horizontal/vertical pane creation with working-directory preservation;
- tmux reload, detach and reattach;
- Neovim startup, plugin loading and `:checkhealth`;
- Neovim Visual Block with Ctrl+V;
- clipboard copy/paste on the current Wayland or X11 session;
- tmux ↔ Neovim pane navigation;
- DAP F5/F10/F11/F12 reaching Neovim;
- test keymaps under `<leader>t` and terminal keymaps under `<leader>o`;
- Git diff/merge fixture, LazyGit opener and one safe test commit;
- behavior when TPM and optional tools are absent;
- `aesthetic` WezTerm mode only when local media dependencies/assets exist.

Do not expose clipboard contents, tokens, identity or private repository paths in
logs. Sanitize evidence before attaching it to GitHub.

D. PHASE 0 DECISION

- If any P0/P1 defect is found, fix it on the PR #21 branch, add a regression
  test, rerun every applicable check and keep the PR draft.
- If only unavailable manual environments remain, document them explicitly and
  keep the PR draft unless the maintainer accepts the limitation.
- Mark PR #21 ready and merge it only when the exact head commit has green CI,
  required local checks pass and the manual evidence is recorded.
- Prefer squash merge for the connector-generated incremental commit history,
  unless repository policy requires another method.
- After merge, update local `main` and verify the merge commit before Phase 1.

PHASE 1 — EXECUTION ORDER

Execute the issues in this order unless a documented dependency requires a small
adjustment:

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
- Identify platform, compatibility and security risks before editing.

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
- Quote arguments, validate names and avoid `eval` unless unavoidable and
  justified.
- Do not execute untrusted repository hooks or project commands automatically.

D. VALIDATE

Run all applicable commands, including at minimum:

  bash scripts/test.sh --profile static
  bash scripts/test.sh --profile runtime
  bash scripts/doctor.sh --profile normal --json \
    | jq -e '.summary.failures == 0'

After issue #12 exists, also run the clean-room profile. After issue #15 exists,
run the benchmark profile and compare against budgets.

Additionally:

- run ShellCheck and syntax validation for every changed shell file;
- parse every changed JSON/YAML/Lua file;
- use an isolated tmux socket;
- use temporary HOME/XDG directories;
- run Neovim headless with bootstrap enabled and disabled where relevant;
- inspect workflow permissions and untrusted-input handling for Actions changes;
- validate Docker/OCI metadata without exposing the host socket unless the test
  is intentionally isolated.

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

- Use fixtures representing the public pinned workflows: Rust/WASM web app,
  multi-agent infrastructure, Zig network simulator, GitHub Actions triage, data
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
