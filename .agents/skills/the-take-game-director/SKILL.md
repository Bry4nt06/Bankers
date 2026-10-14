---
name: the-take-game-director
description: >
  Project director for THE TAKE, the Roblox heist game in this repository. Use for broad game
  creation, major feature work, map conversion, heist loops, combat, AI, UI, progression, art
  production, optimization, and release-readiness. Routes work through the installed Roblox and
  cross-engine game-development skills while preserving THE TAKE's single-place/Rojo architecture,
  donor-content boundaries, quality bar, and current project decisions.
---

# THE TAKE Game Director

Own the end-to-end outcome for THE TAKE: establish a playable loop first, then bring environment,
systems, presentation, and verification up to the requested quality bar.

This is a Roblox project. Do not apply Three.js, Vite, browser-canvas, WebGL, npm-game-scaffold,
or Playwright-browser assumptions to the game runtime.

## Source of truth

- Final place architecture: `TheTake.rbxl` with `thetake.project.json`.
- Rojo-authored code lives under `src/thetake`.
- Donor systems and maps already present in the place are preserved unless a task explicitly
  replaces or sanitizes them.
- Do not reconnect old standalone project files to `TheTake.rbxl`.
- Before editing a Studio subtree, determine whether Studio, Rojo, a donor model, or generated
  content owns it.
- Do not overwrite hand-authored Studio geometry with Rojo unless the project deliberately adopts
  a file-backed representation for that geometry.

## Skill routing

For broad work, use the smallest useful set from the installed skill library:

- Studio/project changes: `roblox-studio-workflow`
- Luau/game systems: `roblox-luau`
- Remotes/security/server authority: `roblox-networking`
- Character/rig/equipment: `roblox-characters`
- Physics/vehicles/raycasting: `roblox-physics`
- UI/HUD/menu: `roblox-ui` + `game-ui-ux`
- Persistent progression/economy: `roblox-datastores` + `save-systems`
- Level/blockout/heist route: `level-design`
- AI/security/police: `game-ai`
- Asset families/art direction: `create-game-assets`
- Camera work: `camera-systems`
- Feel/feedback: `game-feel`
- Performance: `performance-optimization`
- FPS combat design: `fps-shooter`

Load only the skills needed for the current task.

## Production workflow

### 1. Lock the player promise

Before a major system or map pass, state:

- player fantasy
- target feeling
- primary action
- secondary actions
- 5–30 second repeat loop
- 1–10 minute progression loop
- failure state
- reward/risk
- what skilled play looks like
- non-goals for the current slice

For the first heist vertical slice, the promise is:
"Plan an approach, breach a believable bank, survive escalating resistance, secure valuable loot,
and escape under pressure."

### 2. Build the playable loop before content volume

For the first bank heist:

Crew Spawn -> Approach -> Enter Bank -> Reach Restricted/Vault Area -> Breach -> Defend ->
Loot -> Escape -> Extraction -> Results

Do not multiply maps, weapons, enemies, cosmetics, or monetization before this loop works.

### 3. Validate level flow before dressing

For map work:

1. establish player metrics and combat scale;
2. select the critical path;
3. define optional/flank paths;
4. place encounter spaces and sightlines;
5. test traversal and readability;
6. only then add detailed environment dressing.

Donor geometry is reference/environment material, not permission to keep bad gameplay flow.

### 4. Premium-quality pass

When the user asks for detailed, premium, high-quality, realistic, or same-quality work, a
prototype is not done.

Review all visible surfaces:

- architecture and silhouette
- material consistency
- prop density
- lighting and contrast
- landmarks/readability
- interactables/objective telegraphing
- animation/motion quality
- VFX and feedback
- UI cohesion
- performance budget

Do not use random low-detail Toolbox models to fill quality gaps. Prefer existing coherent donor
assets, approved asset families, source-controlled authored geometry, or licensed/generated assets
that match the established direction.

### 5. Representative scene before mass production

Finish one representative area to near-final quality before multiplying content.

For the first bank map, the representative area should be:
bank exterior -> main lobby -> restricted corridor -> vault approach -> vault/loot room.

Use this scene to lock:
- material palette
- lighting
- prop density
- signage
- money/loot presentation
- security style
- trim/detail scale
- performance expectations

### 6. Server-authoritative gameplay

Clients may request actions but do not decide:
- money/loot value
- purchases
- objective completion
- damage
- inventory ownership
- breach completion
- extraction credit
- rewards

Validate remote arguments and keep authoritative state on the server.

### 7. Continuity note

For substantial work maintain `artifacts/game-progress.md` with:

- current objective
- locked design decisions
- completed work
- current branch
- Studio-only manual changes
- pending asset work
- known defects
- next blocking action

Update the note after major milestones rather than restarting project analysis every session.

## Verification

A change is complete only when verification matches the change.

For Roblox gameplay work, use the applicable subset:

- fresh Studio Play test after Rojo sync;
- Output reviewed for errors/warnings;
- server and client paths both exercised;
- multi-client test when replication/authority changed;
- respawn/rejoin test when player state changed;
- target input modes checked when UI/input changed;
- performance inspected when map density, AI, VFX, or physics increased;
- before/after screenshots for major visual passes;
- exact objective path exercised for heist-state changes.

Do not claim a visual/gameplay result was verified if only code was written.

## Current priority

Unless the user changes direction, prioritize the first playable bank-heist vertical slice over
additional Vault polish.

Current sequence:

1. Prepare and sanitize the chosen CityMap donor working copy.
2. Select the bank building and critical route.
3. Greybox bank interior and three entry routes.
4. Add vault/breach/loot/extraction markers.
5. Implement the server-authoritative heist phase loop.
6. Add security/police PvE.
7. Integrate combat/loadout systems.
8. Dress the representative bank scene to the approved quality bar.
9. Optimize and expand only after the slice plays well.
