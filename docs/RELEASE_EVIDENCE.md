# Release Evidence

## Candidate

- Branch: `agent/rush-complete-dotfiles-v0`
- Pull request: #29
- Release status: draft; not merged and not tagged
- Behavior implementation commit: `1ce870ee22157b7693ad5fe6f79050e2231fd2fb`

## Automated evidence

The behavior implementation commit was verified on July 28, 2026:

| Scope | Workflow or job | Result | Evidence |
| --- | --- | --- | --- |
| Existing static suite | Validate run `30364507569` | Pass | Editor, tmux and existing static checks passed |
| Rush v0 contracts | Validate run `30364507569` | Pass | Command surface, backup/restore, project cache, worktrees and capabilities passed |
| Ubuntu runtime | Validate run `30364507569` | Pass | Isolated Ubuntu smoke tests passed |
| macOS runtime | Validate run `30364507569` | Pass | Isolated macOS smoke tests passed |
| Clean-room deployment | Clean-room run `30364507076` | Pass | Apply twice, diagnose and restore passed |
| Repository security baseline | Security run `30364508103` | Pass | Immutable Actions and tracked-secret safeguards passed |

The Validate workflow conclusion for that commit was failure only because the
implementation plan did not follow the operator-document Markdown list-spacing
rule. Behavior jobs all passed. The follow-up CI-only patch excludes
`docs/superpowers/plans/` while continuing to lint README and operator docs.

Benchmark JSON generation is exercised by `scripts/tests/v0_extended_test.sh`.
The scheduled/manual benchmark workflow publishes an artifact when invoked.

## Manual-only acceptance

Physical keyboard routing, GUI rendering, Wayland/X11 clipboard integration,
OSC52 terminal support, media playback and private asset selection require a
real workstation. Headless CI must not be presented as evidence for them.

The Compose fallback uses a fixed LazyDocker tag to avoid a floating default,
but registry availability of that specific tag is **UNKNOWN — REQUIRES
VALIDATION** on a Docker-enabled workstation. The native LazyDocker binary
remains the preferred path.
