# Broken. open-source donor

Bankers PvP directly uses the open-source game `Broken.` by Dewan Mukto / dwmk as its PvP donor foundation.

Source repository:
`https://github.com/dwmk/RobloxGames`

Pinned source place snapshot:
`BrokenPVPgame_20240713_01.rbxl`

Pinned Git blob SHA:
`455079b30c13fd5037f049ee83a3a8b90cd5e1e9`

The upstream repository is distributed under the MIT License, Copyright (c) 2024 Dewan Mukto. The upstream README explicitly allows importing scripts, models, UI, and other content from the ready-to-play `.rbxl` files into other games/projects.

Bankers installs that pinned donor snapshot locally as:

`BankersPvPBrokenBase.rbxl`

using:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\bootstrap-broken-pvp.ps1
```

The donor base is the primary PvP starting point. The separate `src/pvp/` code is an earlier clean-room prototype retained as a fallback/reference and should not be synced over the donor place.

When copied or substantially modified Broken code/content is retained in Bankers, preserve this attribution and the upstream MIT notice.
