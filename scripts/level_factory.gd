class_name LevelFactory
extends RefCounted

const TOTAL_LEVELS := 120
const BASE_SPACING := 560.0

static func build_level(level: int) -> Dictionary:
    level = clampi(level, 1, TOTAL_LEVELS)
    var rng := RandomNumberGenerator.new()
    rng.seed = 91021 + level * 7919
    var t := float(level - 1) / float(TOTAL_LEVELS - 1)
    var segment_count := 10 + int(floor(float(level - 1) / 8.0))
    var gap_size := lerpf(520.0, 300.0, t)
    var base_speed := lerpf(350.0, 640.0, t)
    var segments: Array = []
    var last_y := 960.0

    for i in range(segment_count):
        var max_shift := lerpf(300.0, 510.0, t)
        var target_y := clampf(last_y + rng.randf_range(-max_shift, max_shift), 390.0, 1530.0)
        if i < 2:
            target_y = lerpf(960.0, target_y, float(i + 1) / 3.0)
        last_y = target_y
        var moving := level >= 14 and i > 1 and rng.randf() < lerpf(0.08, 0.46, t)
        var amp := 0.0
        if moving:
            amp = rng.randf_range(70.0, lerpf(120.0, 230.0, t))
        var powerup := ""
        if i > 1 and i % 5 == 0 and rng.randf() < 0.72:
            powerup = ["magnet", "shield", "slow"][rng.randi_range(0, 2)]
        segments.append({
            "x": 900.0 + float(i) * BASE_SPACING,
            "gap_y": target_y,
            "gap": gap_size + rng.randf_range(-24.0, 36.0),
            "width": rng.randf_range(115.0, 175.0),
            "moving": moving,
            "amplitude": amp,
            "move_speed": rng.randf_range(0.75, 1.45),
            "coin_arc": rng.randi_range(3, 6),
            "powerup": powerup
        })

    return {
        "level": level,
        "speed": base_speed,
        "segments": segments,
        "reward": 45 + level * 3,
        "theme_index": int(floor(float(level - 1) / 20.0)) % 6
    }

static func build_endless_segment(index: int, seed_value: int = 44119) -> Dictionary:
    var rng := RandomNumberGenerator.new()
    rng.seed = seed_value + index * 6151
    var d := clampf(float(index) / 90.0, 0.0, 1.0)
    var gap := lerpf(510.0, 285.0, d)
    var y := rng.randf_range(400.0, 1520.0)
    var moving := index > 6 and rng.randf() < lerpf(0.12, 0.52, d)
    var powerup := ""
    if index > 2 and index % 6 == 0 and rng.randf() < 0.8:
        powerup = ["magnet", "shield", "slow"][rng.randi_range(0, 2)]
    return {
        "x": 0.0,
        "gap_y": y,
        "gap": gap,
        "width": rng.randf_range(110.0, 180.0),
        "moving": moving,
        "amplitude": rng.randf_range(70.0, 220.0) if moving else 0.0,
        "move_speed": rng.randf_range(0.7, 1.55),
        "coin_arc": rng.randi_range(3, 6),
        "powerup": powerup
    }

static func endless_speed(index: int) -> float:
    return minf(700.0, 360.0 + float(index) * 3.4)
