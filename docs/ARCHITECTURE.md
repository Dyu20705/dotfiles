# Architecture

The repository has four ownership layers:

1. **Core workstation** — bootstrap, doctor, shell, tmux, Neovim, Git and tests.
2. **Capability packs** — optional reusable domain helpers such as `system`.
3. **Project-local environment** — versions, services and commands owned by each project.
4. **Private local overlay** — identity, secrets, paths and personal assets outside Git.

Configuration dimensions stay independent: profile (`minimal`, `normal`, `full`), machine context (`desktop`, `laptop`, `server`, `remote`), capability selection and private overlays. Minimal mode never loads a capability.

A default feature must improve a repeated workflow, have one owner, degrade quietly, be testable, document its cost and have a removal path.
