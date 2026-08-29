# Bankers — Co-op PvE Vertical Slice

## Direction

Bankers begins as a co-op PvE heist game. All players are members of the Crew faction and oppose AI-controlled Law/security forces.

The architecture is hybrid-ready from day one: Crew and Law are separate factions, objective ownership is server-authoritative, and future player-controlled Law can be added without replacing the heist state machine.

## Gameplay place

The cinematic bank environment remains the menu place. Gameplay uses a separate Roblox place and a separate Rojo project:

```powershell
rojo serve gameplay.project.json
```

`default.project.json` remains the menu project.

## First heist loop

1. **Lobby / Crew Assembly**
   - Players spawn normally.
   - Crew loadouts and readiness will be added here.
   - Current scaffold starts with one player for fast Studio iteration.

2. **Infiltration**
   - Enter the target bank.
   - Reach the protected interior/vault floor.
   - Initial security guards are PvE.

3. **Vault**
   - Start a drill, thermal breach, or electronic bypass.
   - Defend the breach against security/police response.

4. **Loot**
   - Interact with cash/gold targets.
   - Carry bags with movement/weapon tradeoffs.
   - Meet a required loot value before extraction.

5. **Escape**
   - Move loot to the extraction vehicle/zone.
   - Survive final Law response.

6. **Results**
   - Calculate secured loot, crew survival, time, difficulty, and bonuses.

## Current foundation

- `gameplay.project.json` — isolated gameplay Rojo project.
- `src/gameplay/shared/HeistConfig.luau` — phase/faction configuration.
- `src/gameplay/server/GameplayBootstrap.server.luau` — normal spawning and Crew/Law teams.
- `src/gameplay/server/HeistDirector.server.luau` — server-authoritative heist phase state.
- `src/gameplay/client/HeistHud.client.luau` — first objective HUD.
- `ServerStorage.BankersGameplayEvents.AdvanceHeistPhase` — internal bindable event for future objective systems to advance the heist.

## Next implementation milestones

### Milestone 1 — Gameplay graybox

Build a new gameplay bank map with these tagged/defined spaces:

- Crew staging spawn
- Street/perimeter
- Bank entrance
- Lobby
- Security room
- Vault approach
- Vault room
- Loot room
- Extraction route
- Extraction vehicle/zone

### Milestone 2 — Interaction/objective framework

Add server-authoritative interactions for:

- doors
- keycards
- drill/breach start
- breach progress
- loot pickup/bagging
- extraction deposit

These systems fire `AdvanceHeistPhase` only after the required objective is complete.

### Milestone 3 — PvE Law foundation

Add AI roles:

- bank security guard
- patrol officer
- response officer
- tactical response unit

AI uses the `Law` faction, so the same damage/friendly-fire rules can later support human Law players.

### Milestone 4 — Crew combat

Add the production weapon framework, aiming, recoil, reloads, hit validation, armor, downed/revive state, and ammunition economy.

### Milestone 5 — Hybrid mode

Once PvE is stable, allow selected servers/modes to assign human players to `Law`. AI can remain as reinforcement and population filler.
