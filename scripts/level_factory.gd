extends RefCounted

const TOTAL_LEVELS := 120
const BASE_SPACING := 560.0

static func build_level(requested_level: int) -> Dictionary:
	var level := clampi(requested_level, 1, TOTAL_LEVELS)
	var rng := RandomNumberGenerator.new()
	rng.seed = 91021 + level * 7919

	var difficulty := float(level - 1) / float(TOTAL_LEVELS - 1)
	var segment_count := 10 + int(floor(float(level - 1) / 8.0))
	var gap_size := lerp(520.0, 300.0, difficulty)
	var base_speed := lerp(350.0, 640.0, difficulty)
	var segments: Array = []
	var last_y := 960.0

	for i in range(segment_count):
		var max_shift := lerp(300.0, 510.0, difficulty)
		var target_y := clamp(last_y + rng.randf_range(-max_shift, max_shift), 390.0, 1530.0)
		if i < 2:
			target_y = lerp(960.0, target_y, float(i + 1) / 3.0)
		last_y = target_y

		var moving := level >= 14 and i > 1 and rng.randf() < lerp(0.08, 0.46, difficulty)
		var move_amplitude := 0.0
		if moving:
			move_amplitude = rng.randf_range(70.0, lerp(120.0, 230.0, difficulty))

		var powerup := ""
		if i > 1 and i % 5 == 0 and rng.randf() < 0.72:
			var options := ["magnet", "shield", "slow"]
			powerup = options[rng.randi_range(0, options.size() - 1)]

		segments.append({
			"x": 900.0 + float(i) * BASE_SPACING,
			"gap_y": target_y,
			"gap": gap_size + rng.randf_range(-24.0, 36.0),
			"width": rng.randf_range(115.0, 175.0),
			"moving": moving,
			"amplitude": move_amplitude,
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
	var difficulty := clamp(float(index) / 90.0, 0.0, 1.0)
	var gap_size := lerp(510.0, 285.0, difficulty)
	var target_y := rng.randf_range(400.0, 1520.0)
	var moving := index > 6 and rng.randf() < lerp(0.12, 0.52, difficulty)
	var powerup := ""

	if index > 2 and index % 6 == 0 and rng.randf() < 0.8:
		var options := ["magnet", "shield", "slow"]
		powerup = options[rng.randi_range(0, options.size() - 1)]

	var move_amplitude := 0.0
	if moving:
		move_amplitude = rng.randf_range(70.0, 220.0)

	return {
		"x": 0.0,
		"gap_y": target_y,
		"gap": gap_size,
		"width": rng.randf_range(110.0, 180.0),
		"moving": moving,
		"amplitude": move_amplitude,
		"move_speed": rng.randf_range(0.7, 1.55),
		"coin_arc": rng.randi_range(3, 6),
		"powerup": powerup
	}

static func endless_speed(index: int) -> float:
	return min(700.0, 360.0 + float(index) * 3.4)
