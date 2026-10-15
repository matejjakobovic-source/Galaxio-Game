# GRAVITY

Portrait mobile gravity-runner built in Godot 4.3. The game keeps the original menu/gameplay identity while adding a stronger level progression system, risk/reward coin routes, procedural sound effects, and polished planet/trail visuals.

## Core controls
- Tap upper half: gravity up
- Tap lower half: gravity down
- Desktop: W/Up, S/Down, Space to flip

## Level System 2.0
120 levels are split into eight 15-level sectors:
1. Orbit
2. Neon Station
3. Asteroid Belt
4. Solar Zone
5. Gravity Lab
6. Void
7. Singularity
8. Core

Each sector changes the generated level patterns and introduces mechanics gradually. Every fifth level is a sector trial. Levels 20, 40, 60, 80, 100 and 120 are larger signature challenges.

### Added mechanics
- moving gates
- pulse gates
- laser gates
- asteroid hazards
- rotating spinner hazards
- temporary speed zones
- gravity-strength zones
- gravity wells
- paired teleport portals
- deterministic wave/slalom/stair/switchback/tunnel patterns

## Coins and power-ups
Coins now have a smaller pickup radius and spawn on intentional upper/lower/zig-zag/edge routes inside gates. They are harder to collect safely and reward deliberate risk rather than being automatic pickups. Magnet, shield and slow-motion power-ups remain available.

## Visual polish
- enhanced per-skin planet rendering
- speed-aware trail
- zone-specific backgrounds and color palettes
- upgraded gates, coins and power-up presentation
- Perfect and Gravity Rush visual feedback

## Sound
Sound effects are generated procedurally at runtime, so there are no external audio files to manage. Effects cover gravity flips, coins, Perfect gates, Rush, hits, shields, power-ups, buttons and successful runs.

## Validation
GitHub Actions uses Godot 4.3 stable to:
- import the project and catch script/import errors
- smoke-run the main scene
- exercise Level, Endless and Daily modes
- validate zone progression and signature challenge generation
