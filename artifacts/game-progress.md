# THE TAKE — Game Progress

## Current objective

Build the first complete playable bank-heist vertical slice using a donor CityMap as the
environment foundation.

## Architecture

- Final place: `TheTake.rbxl`
- Active Rojo project: `thetake.project.json`
- Active development branch at this checkpoint: `feature/vault-wardrobe-fit-pass2`
- Donor maps remain preserved under `ReplicatedStorage.Maps`
- Working bank map copy: `Workspace.TheTakeBankMap`

## Locked direction

- Co-op heist first; Law/security is PvE initially.
- First loop: approach -> infiltrate -> breach -> defend -> loot -> escape -> extraction -> results.
- Detailed/premium visual target; avoid low-detail random Toolbox filler.
- Use donor city geometry as a base, but redesign flow where gameplay requires it.
- Build and approve one representative bank route before dressing the entire city.
- Server-authoritative objectives, loot, rewards, damage, and progression.

## Completed / available

- Integrated single-place THE TAKE architecture.
- Cinematic menu scene.
- Vault/store foundation and wardrobe work.
- Donor city maps available in the place.
- `PrepareBankMap.luau` added for sanitizing and structuring the working donor map.
- User has cloned a donor city map into Workspace as the working bank map.
- Game-development agent skills installed locally.
- Project-local `the-take-game-director` added to adapt premium production workflow to Roblox.

## Current map structure target

`Workspace.TheTakeBankMap`

- Environment
- Bank
  - Exterior
  - Lobby
  - TellerArea
  - Offices
  - SecurityRoom
  - VaultApproach
  - Vault
  - LootRoom
- Streets
- Props
- GameplayMarkers
  - CrewSpawn
  - FrontEntry
  - SideEntry
  - RearEntry
  - VaultBreach
  - LootZone
  - EscapeRoute
  - Extraction

## Next blocking action

Run the bank-map preparation tool on the Workspace copy if it has not already been run, then
capture a high/top-down Studio screenshot of the full map.

Use that screenshot to choose:

1. the bank building,
2. crew approach/staging area,
3. front/side/rear entry routes,
4. vault location,
5. escape route,
6. extraction location.

After those locations are locked, greybox the bank interior before adding final art detail.

## Deferred

- Finish Vault imported-gear fitting.
- Additional store content.
- Multiple heist maps.
- Advanced monetization.
- Large weapon/content expansion.
- Full police vehicle pursuit system.
