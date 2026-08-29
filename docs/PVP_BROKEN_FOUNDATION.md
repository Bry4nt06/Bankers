# Bankers PvP — Broken-inspired mechanics foundation

This is a separate gameplay lane from the Bankers menu and the armored-truck getaway.

## Place separation

- `Bankers.rbxl` + `default.project.json` = cinematic/menu place
- `BankersGameplay.rbxl` + `gameplay.project.json` = co-op getaway prototype
- `BankersPvP.rbxl` + `pvp.project.json` = PvP arena place

Do not connect the wrong Rojo project to another place.

## Current PvP foundation

The first pass is intentionally map-light and mechanics-heavy:

- FFA respawns
- KOs / WOs leaderboard
- server-authoritative hitscan damage
- headshot multiplier
- spawn protection
- automatic rifle
- magazine + reserve ammo
- reload timing
- third-person shoulder camera behavior
- right-mouse ADS
- recoil
- center-screen crosshair
- hit marker
- Shift sprint
- C / LeftCtrl crouch
- sprint + C / LeftCtrl slide

## Controls

| Input | Action |
| --- | --- |
| WASD | Move |
| Shift | Sprint |
| C / Left Ctrl | Crouch |
| Sprint + C / Left Ctrl | Slide |
| Left Mouse | Fire |
| Right Mouse | ADS |
| R | Reload |
| Space | Jump |

## First local setup

Create a new Roblox Studio Baseplate and immediately save it as:

`D:\RobloxProjects\Bankers\BankersPvP.rbxl`

Then run:

```powershell
cd D:\RobloxProjects\Bankers
git pull origin main
rojo serve pvp.project.json
```

Connect the Rojo plugin from the `BankersPvP.rbxl` Studio window.

In Edit mode, bake the disposable mechanics arena:

```lua
require(game.ServerScriptService.BankersPvP.BuildPvPTestArena).Run()
```

Save the place with Ctrl+S, then press Play.

## Testing PvP with multiple players

In Studio use the Test tab and start a local server with at least two players. The weapon service only damages other player characters; it does not self-damage.

## Design direction

The temporary arena is not intended to ship. Once movement and firearm feel are validated, replace it with purpose-built Bankers maps while keeping the combat services map-agnostic.

The target feel is a quick, readable arena shooter inspired by the open-source Roblox game `Broken.` without coupling Bankers to Broken's old place structure.
