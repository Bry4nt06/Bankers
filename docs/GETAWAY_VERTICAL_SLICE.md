# Bankers — Getaway Vertical Slice

Gameplay Place 1 begins immediately after the robbery. The crew escapes in an armored truck while police vehicles pursue through a curated city route.

## First playable target

1. Crew deploys at the armored-truck start.
2. Six-second mission countdown.
3. Pursuit begins through downtown streets.
4. Police response escalates at route checkpoint 5.
5. Crew reaches the tunnel approach at route checkpoint 8.
6. Extraction zone completes the getaway.
7. Results screen/state resets for another run.

## Environment route

The graybox intentionally represents a curated chase corridor rather than an open world:

- Bank Exit
- Downtown Grid
- Commercial Streets
- Downtown Arterial
- Industrial Entry
- Industrial District
- Highway Approach
- Tunnel Run

The final art environment can replace the graybox roads/buildings with Roblox Modern City donor assets while preserving checkpoint, police-spawn, truck-start, and extraction markers.

## Planned crew roles

- Driver — armored truck control
- Left gunner — fires from left side/rear quarter
- Right gunner — fires from right side/rear quarter
- Rear gunner — focuses on pursuing vehicles

Unused positions can be AI-assisted when fewer than four players are present.

## Next implementation passes

1. Armored-truck physics/controller and crew seats.
2. Passenger firing arcs and weapon mounts.
3. Police pursuit vehicle AI.
4. Vehicle health, tires, collision damage, and police disable states.
5. Roadblocks and heavier response waves.
6. Replace graybox dressing with curated Modern City assets.
7. Menu PLAY teleport into this gameplay place.
