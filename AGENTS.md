# Repository Notes

## Panorama Compilation

Use the Node helper instead of calling Valve's compiler manually:

```powershell
node scripts/compile_panorama.js
```

With no arguments, it compiles the current XHS top HUD files:

- `content/panorama/layout/custom_game/custom_ui_manifest.xml`
- `content/panorama/layout/custom_game/xhs_top_hud.xml`
- `content/panorama/layout/custom_game/xhs_timers.xml`
- `content/panorama/styles/custom_game/xhs_top_hud.css`
- `content/panorama/scripts/custom_game/xhs_top_hud.js`

To compile specific Panorama source files:

```powershell
node scripts/compile_panorama.js content/panorama/layout/custom_game/foo.xml content/panorama/styles/custom_game/foo.css
```

Notes:

- Pass source files under `content/`, not generated files under `game/`.
- The repo `content` and `game` directories are junctions into the Steam Dota addon folders.
- `resourcecompiler.exe` must be run against the real Steam `content/dota_addons/x_hero_siege/...` paths. Running it from the repo-relative junction paths can fail with `gameinfo.gi` or empty filename errors.
- Do not compile Panorama after every edit. Only compile when the user asks, when new files must exist under `game/panorama`, or when debugging parser/compiler errors.
