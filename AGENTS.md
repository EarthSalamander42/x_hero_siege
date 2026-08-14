# Public repository workflow boundary

- Keep this repository limited to final game-facing source, runtime code, assets, and required public build configuration.
- Never create standalone tooling scripts here, including Node.js, JavaScript, PowerShell, Python, shell, migration, patching, deployment, inspection, generation, smoke-test, or verification utilities.
- Put reusable XHS tooling directly in the private sibling repository at `../xhs_ai/scripts/`.
- Put task-specific retained helpers in `../xhs_ai/tmp/`, and disposable helpers in the operating-system temporary directory.
- Panorama JavaScript and Lua files required by the shipped addon remain in their normal public runtime locations; this boundary applies to repository tooling and chantier scripts.
- Before finishing a task, inspect the public top-level `scripts/` directory and move any newly created tooling to its private canonical location.
