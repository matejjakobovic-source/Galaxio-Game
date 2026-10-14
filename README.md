# 🪐 GRAVITY — Galaxio Game

A portrait-first mobile gravity runner built in **Godot 4.3+**. The player controls a small planet and changes its gravity by tapping the screen:

- Tap the **upper half** → gravity pulls **up**
- Tap the **lower half** → gravity pulls **down**
- Desktop testing: **W / ↑**, **S / ↓**, **Space** toggles gravity

## Current features

- Physics-based gravity movement with velocity damping on direction changes
- 120 deterministic levels with progressive difficulty
- Endless mode with procedural gates and increasing speed
- Date-seeded Daily Challenge (coins / perfect combo / survival)
- Coin economy saved locally
- 10-step Velocity Core upgrade system
- 8 procedural planet skins
- Power-ups: Magnet, Shield, Slow Motion
- Perfect Gate combo system and 5-perfect **Rush** bonus
- Local top-10 leaderboard
- Daily completion reward + streak tracking
- Haptic feedback on supported mobile devices
- Persistent save data in `user://gravity_save.json`
- Procedural visuals with no paid asset dependency

## Verified Godot runtime

The `main` branch is automatically tested with **Godot 4.3 stable** on every relevant change. CI performs all of the following:

1. Imports the project and compiles all GDScript files.
2. Starts the main scene headlessly and fails on Godot runtime/script errors.
3. Runs `tests/runtime_smoke.gd`, which actually starts **Level 1**, **Endless**, and **Daily**, creates the player/world/gates/pickups, changes gravity, and advances physics frames.

The validated gameplay test ends with `RUNTIME_SMOKE_OK`.

## Project structure

```text
Galaxio-Game/
├── .github/workflows/godot-check.yml
├── assets/icon.svg
├── scenes/main.tscn
├── scripts/
│   ├── gate.gd
│   ├── level_factory.gd
│   ├── main.gd
│   ├── pickup.gd
│   ├── planet.gd
│   ├── save_data.gd
│   └── starfield.gd
├── tests/runtime_smoke.gd
├── project.godot
└── README.md
```

## Run it

1. Install **Godot 4.3 or newer**.
2. Use the current `main` branch of this repository.
3. In Godot Project Manager choose **Import** and select this project's `project.godot`.
4. Press **F6/F5** to run.

The default viewport is **1080 × 1920 portrait** and scales down for desktop testing.

### If you previously opened the broken version

Do not keep using the old downloaded project unchanged. Pull/clone the current `main` branch or replace the old folder with the current files. If Godot still shows stale parser/import errors after updating the files, close Godot, remove the local `.godot` cache folder inside the project, then import/open `project.godot` again. The `.godot` folder is generated locally and is not part of the source project.

## Android export

In Godot, install Android build templates and configure Android SDK/JDK under **Editor → Editor Settings → Export → Android**. Then create an Android export preset and export an `.aab` for Google Play.

Recommended release package name: `com.galaxio.gravity`

## iOS export

Export from Godot on macOS with Xcode installed. Create an iOS preset, configure bundle identifier/signing, export the Xcode project, then archive it in Xcode for TestFlight/App Store.

Recommended bundle identifier: `com.galaxio.gravity`

## Leaderboard note

The current leaderboard works locally and persists the device's top 10 runs. A real global online leaderboard still requires one production identity/backend option, for example:

- Google Play Games Services (Android)
- Game Center (iOS)
- Supabase / Firebase / PlayFab for a cross-platform leaderboard

No backend credentials or secrets are committed to this repository.

## Production polish still worth adding

The game core now opens and executes under Godot 4.3, but a store-ready release should still get a dedicated pass for sound/music, particles and VFX, onboarding/tutorial presentation, multiple real-device tests, analytics/crash reporting, accessibility/settings, and a global leaderboard service.
