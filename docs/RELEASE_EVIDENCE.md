# Release Evidence

## Candidate

- Branch: `agent/rush-complete-dotfiles-v0`
- Pull request: #29
- Release status: draft; not merged and not tagged

## Automated evidence

The final commit and workflow run identifiers are recorded after all required
jobs complete. Required jobs are Markdown, static contracts, Ubuntu runtime,
macOS runtime, clean-room, security and benchmark artifact generation.

## Manual-only acceptance

Physical keyboard routing, GUI rendering, Wayland/X11 clipboard integration,
OSC52 terminal support, media playback and private asset selection require a
real workstation. Headless CI must not be presented as evidence for them.
