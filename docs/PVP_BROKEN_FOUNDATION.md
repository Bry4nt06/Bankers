# Bankers PvP — Broken donor foundation

This is a separate gameplay lane from the Bankers menu and the armored-truck getaway.

## Place separation

- `Bankers.rbxl` + `default.project.json` = cinematic/menu place
- `BankersGameplay.rbxl` + `gameplay.project.json` = co-op getaway prototype
- `BankersPvP.rbxl` + `pvp.project.json` = earlier clean-room PvP mechanics prototype
- `BankersPvPBrokenBase.rbxl` = primary PvP donor base built from the open-source `Broken.` snapshot

Do not connect the wrong Rojo project to another place.

## Current direction

Bankers PvP will no longer start by rebuilding Broken's combat from the bottom. The primary PvP foundation is the actual open-source Broken place snapshot:

`dwmk/RobloxGames/BrokenPVPgame_20240713_01.rbxl`

This immediately gives us the donor game's complete gun roster, combat scripts, movement, camera/aim handling, round/gameplay plumbing, UI/shop/loadout systems, NPC support, and map framework. We will tailor those systems for Bankers rather than re-implementing them one-by-one.

The existing `src/pvp/` clean-room implementation remains in the repository as a reference/fallback, but it is not the main foundation going forward.

## Install the donor base

From PowerShell:

```powershell
cd D:\RobloxProjects\Bankers
git pull origin main
powershell -ExecutionPolicy Bypass -File .\scripts\bootstrap-broken-pvp.ps1
```

The bootstrap downloads the pinned upstream snapshot and verifies its Git blob SHA before installing:

`D:\RobloxProjects\Bankers\BankersPvPBrokenBase.rbxl`

Open `BankersPvPBrokenBase.rbxl` directly in Roblox Studio.

### Important

Do **not** connect `pvp.project.json` to `BankersPvPBrokenBase.rbxl`. The earlier `pvp.project.json` makes `StarterPlayerScripts` authoritative for the clean-room prototype and could remove donor client scripts. We will create a donor-safe Bankers overlay project only after the Broken hierarchy has been inspected and the retained systems are identified.

## First donor-tailoring pass

The first pass on the donor base is intentionally subtraction-first:

1. Verify Broken runs unchanged in Studio.
2. Inventory all guns and combat/movement modules.
3. Keep the complete mechanics and weapon set initially.
4. Select one Broken map as the temporary Bankers PvP test map.
5. Remove/disable the other map rotations only after the map hierarchy is confirmed.
6. Remove Broken branding and unrelated presentation without changing mechanics.
7. Start tuning movement, gun balance, recoil, camera, animations, and round rules for Bankers.

This gets Bankers to a mature PvP baseline immediately while keeping the menu and getaway places isolated.
