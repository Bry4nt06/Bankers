# THE TAKE — single-place architecture

THE TAKE uses one Roblox place file for both the cinematic frontend and the Broken-derived PvP gameplay.

## Master-file strategy

Do not manually transplant every Broken service into the old menu-only `Bankers.rbxl`.

Use the open-source Broken donor place as the master because it already contains its maps, guns, movement, remotes, weapon services, UI, round systems, storage hierarchy, and dependencies in their working locations.

Create the final place from:

`BankersPvPBrokenBase.rbxl` -> `TheTake.rbxl`

Then add the Bankers cinematic Workspace content as one isolated model named:

`Workspace.TheTakeMenuScene`

The integrated Rojo project is:

`thetake.project.json`

It is donor-safe: ServerScriptService and StarterPlayerScripts preserve unknown Broken instances. The project adds only THE TAKE integration scripts and selectively clears the obsolete `BankersBrokenOverlay` folder from the earlier donor experiment.

## Build the menu-scene package

Open `Bankers.rbxl` in Edit mode. Build a temporary `TheTakeMenuScene` model containing clones of the menu Workspace content, including `MenuCameraStart` and `MenuCameraEnd`.

Copy that one model into `TheTake.rbxl`.

The THE TAKE menu server controller stabilizes only descendants of `TheTakeMenuScene`; it does not scan or freeze Broken gameplay content.

## Runtime flow

1. The single place loads with Broken donor systems intact.
2. THE TAKE suppresses only Broken's starter-menu ScreenGui.
3. THE TAKE runs the original cinematic camera over `TheTakeMenuScene`.
4. The title is `THE TAKE` with the Bankers cinematic presentation.
5. PLAY fades to black.
6. THE TAKE releases camera/input/CoreGui to gameplay.
7. THE TAKE fires Broken's existing `ReplicatedStorage.SpawnPlayer` remote.
8. Broken movement, weapons, maps, HUD, rounds, and other donor systems continue from their original hierarchy.

## Rojo

Use only:

```powershell
cd D:\RobloxProjects\Bankers
git pull origin main
rojo serve thetake.project.json
```

Do not connect `default.project.json`, `gameplay.project.json`, `pvp.project.json`, or `broken-pvp-overlay.project.json` to `TheTake.rbxl`.
