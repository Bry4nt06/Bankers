# Bankers Intro Scene Setup

This place is treated as a menu-only cinematic scene.

## Required Studio camera markers

Create two anchored Parts directly in `Bankers.rbxl`:

- `MenuCameraStart` — the wide establishing shot of the bank facade.
- `MenuCameraEnd` — the lower/closer shot aimed at the figures, vehicles, and entrance.

Recommended marker properties:

- Anchored = true
- CanCollide = false
- CanTouch = false
- CanQuery = false
- Transparency = 0.65 while editing
- Size = 2, 2, 2

The client hides the marker Parts locally during Play.

## Capture a Studio viewport into a marker

Frame the Studio viewport exactly as desired, then run in the Command Bar:

```lua
workspace.MenuCameraStart.CFrame = workspace.CurrentCamera.CFrame
```

For the end shot:

```lua
workspace.MenuCameraEnd.CFrame = workspace.CurrentCamera.CFrame
```

Save `Bankers.rbxl` after setting the markers.

## Camera behavior

The intro controller:

1. Starts at `MenuCameraStart` with a wider 58 degree FOV.
2. Uses a seven-second quintic ease to float down to `MenuCameraEnd`.
3. Narrows to 44 degree FOV for a restrained cinematic push-in.
4. Fades in the BANKERS / PLAY menu late in the move.
5. After arrival, applies very small idle sway and cursor parallax for a grounded shooter-menu feel.
6. PLAY fades to black and currently exposes a transition hook for the future gameplay place.

## Scene behavior

`MenuScene.server.luau` disables automatic player spawning, freezes all Models named `Rig`, and anchors the contents of `Workspace.Vehicles` when that folder exists. This keeps the intro composition deterministic.
