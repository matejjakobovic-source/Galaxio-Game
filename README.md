# 🪐 GRAVITY — Galaxio Game

A portrait-first mobile gravity runner built in **Godot 4.x**. The player controls a small planet and changes its gravity by tapping the screen:

- Tap the **upper half** → gravity pulls **up**
- Tap the **lower half** → gravity pulls **down**
- Desktop testing: **W / ↑**, **S / ↓**, **Space** toggles gravity

## Included now

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
- Procedural visuals, so the prototype has no dependency on paid art assets

## Project structure

```text
Galaxio-Game/
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
├── project.godot
└── README.md
```

## Run it

1. Install **Godot 4.3+**.
2. Import this folder as a Godot project.
3. Open `project.godot`.
4. Press **F6/F5** to run.

The default viewport is **1080 × 1920 portrait** and scales down for desktop testing.

## Android export

In Godot, install Android build templates and configure Android SDK/JDK under **Editor → Editor Settings → Export → Android**. Then create an Android export preset and export an `.aab` for Google Play.

Recommended release package name: `com.galaxio.gravity`

## iOS export

Export from Godot on macOS with Xcode installed. Create an iOS preset, configure bundle identifier/signing, export the Xcode project, then archive it in Xcode for TestFlight/App Store.

Recommended bundle identifier: `com.galaxio.gravity`

## Leaderboard note

The current leaderboard is **fully functional locally** and persists the device's top 10 runs. A global online leaderboard needs credentials/configuration for one of these production options:

- Google Play Games Services (Android)
- Game Center (iOS)
- Supabase / Firebase / PlayFab cross-platform backend

Keeping online identity/backend out of the base project means the game runs immediately without committing secrets to GitHub.

## Next production pass

Before store release, the highest-value additions are sound/music, polished particle/VFX assets, onboarding/tutorial animation, device testing, analytics/crash reporting, and a real online leaderboard service.
