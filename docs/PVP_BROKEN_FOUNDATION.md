# THE TAKE PvP — Broken donor foundation

This is a separate gameplay lane from the cinematic menu and the armored-truck getaway prototype.

## Place separation

- `Bankers.rbxl` + `default.project.json` = THE TAKE cinematic/menu place
- `BankersGameplay.rbxl` + `gameplay.project.json` = co-op getaway prototype
- `BankersPvP.rbxl` + `pvp.project.json` = earlier clean-room PvP mechanics prototype
- `BankersPvPBrokenBase.rbxl` = primary PvP donor base built from the open-source `Broken.` snapshot
- `broken-pvp-overlay.project.json` = donor-safe direct-start overlay for the Broken base

Do not connect the wrong Rojo project to another place.

## Current direction

THE TAKE PvP does not rebuild Broken's combat from the bottom. The primary PvP foundation is the actual open-source Broken place snapshot:

`dwmk/RobloxGames/BrokenPVPgame_20240713_01.rbxl`

This gives the donor game's complete gun roster, combat scripts, movement, camera/aim handling, round/gameplay plumbing, UI/shop/loadout systems, NPC support, and map framework. Those systems will be tailored for THE TAKE rather than reimplemented one-by-one.

The existing `src/pvp/` clean-room implementation remains in the repository as a reference/fallback, but it is not the primary foundation.

## Install the donor base

From PowerShell:

```powershell
cd D:\RobloxProjects\Bankers
git pull origin main
powershell -ExecutionPolicy Bypass -File .\scripts\bootstrap-broken-pvp.ps1
```

The bootstrap downloads and verifies the pinned upstream snapshot before installing:

`D:\RobloxProjects\Bankers\BankersPvPBrokenBase.rbxl`

Open `BankersPvPBrokenBase.rbxl` directly in Roblox Studio.

## Remove Broken's starter menu without removing gameplay systems

Do **not** connect `pvp.project.json` to `BankersPvPBrokenBase.rbxl`. The clean-room project can remove donor client scripts.

Use the donor-safe overlay instead:

```powershell
cd D:\RobloxProjects\Bankers
rojo serve broken-pvp-overlay.project.json
```

Connect that Rojo server only from `BankersPvPBrokenBase.rbxl`.

The overlay now bypasses Broken's front-end entirely. At runtime it identifies only the `ScreenGui` that owns Broken's PLAY button and disables that menu. It leaves all other ScreenGuis untouched so combat HUD, round timer, voting, inventory/shop, and weapon interfaces remain available. It then uses Broken's existing `ReplicatedStorage.SpawnPlayer` entry point to request gameplay directly.

The donor content to preserve includes the map folders under `ReplicatedStorage.Maps`, `ServerStorage.AllWeapons`, `ServerStorage.AllArmor`, the donor weapon system, movement/player scripts, remotes, teams, round systems, and supporting map assets.

Long term, `Bankers.rbxl` remains THE TAKE's real cinematic entry place. Its PLAY button will teleport directly into the published PvP Place, where the direct-start overlay skips Broken's old menu and enters gameplay.

## First donor-tailoring pass

1. Verify the donor enters gameplay directly with the overlay.
2. Inventory all guns and combat/movement modules.
3. Keep the complete mechanics and weapon set initially.
4. Keep the donor maps available while we decide which maps to recreate/replace.
5. Remove Broken branding and unrelated presentation without changing mechanics.
6. Tune movement, gun balance, recoil, camera, animations, and round rules for THE TAKE.

This gets THE TAKE to a mature PvP baseline immediately while keeping its cinematic menu and other gameplay prototypes isolated.
