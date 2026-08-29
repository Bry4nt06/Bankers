# Bankers Getaway — Donor Conversion Workflow

Gameplay Place 1 is the armored-truck getaway. Donor assets are visual/environment sources only; Bankers owns all gameplay code, vehicle control, seats, camera, mission state, and later police AI.

## 1. Keep the places separate

Menu place:

```powershell
rojo serve default.project.json
```

Gameplay place (`BankersGameplay.rbxl`):

```powershell
rojo serve gameplay.project.json
```

Do not connect the gameplay Rojo project to the menu place.

## 2. Armored vehicle donor

The preferred vehicle visual is the manually inserted Toolbox model named `Armored Vehicle` (original asset ID `5144461510`).

Insert it into Workspace in Edit mode. Do not press Play while the raw donor is present, because its original A-Chassis scripts/sounds may execute.

Then run:

```lua
require(game.ServerScriptService.BankersGameplay.BuildGetawayTruck).Run()
```

The baker will:

- prefer Workspace `Armored Vehicle` / `ArmoredVehicle` over InsertService;
- clone its visual geometry;
- strip donor scripts, modules, remotes, bindables, seats, sounds, BodyMovers, constraints, and old joints;
- fit the visual to the Bankers collision chassis;
- weld visual parts to the Bankers chassis;
- create Bankers driver/left/right/rear crew seats and gun mount points;
- remove the original raw donor only after conversion succeeds;
- fall back to the simple internal truck visual only if no usable donor exists.

Expected Output includes:

```text
[BankersTruckBake] using Workspace Armored Vehicle donor (...)
[BankersTruckBake] removed original Armored Vehicle after successful visual conversion
[BankersTruckBake] COMPLETE: one sanitized Bankers getaway truck created.
```

Press `Ctrl+S` after a successful bake.

## 3. City environment donor

Insert the chosen city/map manually from Toolbox into Workspace in Edit mode. Manual insertion avoids InsertService authorization failures.

Sanitize it before Play. Either pass the model directly:

```lua
require(game.ServerScriptService.BankersGameplay.PrepareCityEnvironment).Run(workspace["CITY MAP"])
```

or pass its exact Workspace name:

```lua
require(game.ServerScriptService.BankersGameplay.PrepareCityEnvironment).Run("CITY MAP")
```

The tool anchors the environment and strips scripts, remotes, bindables, seats, sounds, BodyMovers, constraints, and old joints. It renames the sanitized result to:

```text
BankersCityEnvironment
```

Press `Ctrl+S` after preparation.

## 4. Current driving controls

- `W` — accelerate
- `S` — reverse / brake
- `A` / `D` — steer
- `E` — exit any Bankers truck crew seat
- Gamepad `B` — exit

The Bankers chase camera ignores route trigger/checkpoint geometry and is positioned higher with a longer forward look distance.

## 5. Environment-first milestone

Do not build police pursuit AI until the permanent city donor is selected and sanitized.

After the city is in place, capture a high/top-down screenshot showing the full road network. The next map pass should replace the short graybox route with a 5–8 minute path through the real streets, including downtown, commercial, industrial, highway/tunnel, and extraction sections.
