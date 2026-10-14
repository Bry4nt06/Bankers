# THE TAKE — Agent Operating Guide

For broad work in this repository, start with the project-local skill:

`.agents/skills/the-take-game-director/SKILL.md`

THE TAKE is a Roblox/Rojo project. The director composes the installed Roblox/game-development
skills and carries the project's current architecture and production priorities.

## Project guardrails

- Use `thetake.project.json` for the integrated `TheTake.rbxl` build.
- Preserve donor systems unless a task explicitly replaces or sanitizes them.
- Treat `src/thetake` as Rojo-owned code.
- Treat hand-authored Studio map geometry as Studio-owned unless deliberately migrated.
- Never import Three.js/Vite/browser-runtime assumptions into Roblox code.
- Prefer one fully playable, high-quality heist vertical slice before expanding content volume.
- Keep authoritative gameplay state on the server.
- Verify changes in Studio and report what was actually tested.

## Current project focus

The Vault work is paused. Current priority is the first bank-heist map and playable robbery loop
using the selected CityMap donor.

See `artifacts/game-progress.md` for the active checkpoint.
