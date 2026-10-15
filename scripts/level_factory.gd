extends RefCounted

const TOTAL_LEVELS := 120
const BASE_SPACING := 560.0

const ZONE_NAMES := [
	"ORBIT",
	"NEON STATION",
	"ASTEROID BELT",
	"SOLAR ZONE",
	"GRAVITY LAB",
	"VOID",
	"SINGULARITY",
	"CORE"
]

static func zone_index_for_level(level: int) -> int:
	return clampi(int(floor(float(clampi(level, 1, TOTAL_LEVELS) - 1) / 15.0)), 0, 7)

static func zone_name(zone_index: int) -> String:
	return ZONE_NAMES[clampi(zone_index, 0, ZONE_NAMES.size() - 1)]

static func build_level(requested_level: int) -> Dictionary:
	var level: int = clampi(requested_level, 1, TOTAL_LEVELS)
	var zone: int = zone_index_for_level(level)
	var local_level: int = ((level - 1) % 15) + 1
	var rng := RandomNumberGenerator.new()
	rng.seed = 91021 + level * 7919

	var difficulty: float = float(level - 1) / float(TOTAL_LEVELS - 1)
	var zone_progress: float = float(local_level - 1) / 14.0
	var segment_count: int = 9 + zone + int(floor(float(local_level - 1) / 5.0))
	var gap_size: float = lerpf(520.0, 302.0, difficulty)
	var base_speed: float = lerpf(350.0, 640.0, difficulty)
	var signature: bool = level % 5 == 0
	var boss: bool = level % 20 == 0
	var pattern: String = _pattern_for_level(level, zone)
	var segments: Array = []
	var last_y: float = 960.0
	var spacing: float = BASE_SPACING - minf(46.0, float(zone) * 5.0)

	for i in range(segment_count):
		var target_y: float = _pattern_y(pattern, i, segment_count, last_y, difficulty, rng)
		if i < 2:
			target_y = lerpf(960.0, target_y, float(i + 1) / 3.0)
		last_y = target_y

		var gate_type: String = _gate_type_for(zone, local_level, i, signature, rng)
		var moving: bool = gate_type == "moving"
		var move_amplitude: float = 0.0
		if moving:
			move_amplitude = rng.randf_range(65.0, lerpf(115.0, 220.0, difficulty))

		var powerup: String = ""
		if i > 1 and i % 6 == 0 and rng.randf() < 0.56:
			var options := ["magnet", "shield", "slow"]
			powerup = options[rng.randi_range(0, options.size() - 1)]

		var special: String = _special_for_segment(zone, level, i, signature, boss, rng)
		var current_gap: float = gap_size + rng.randf_range(-18.0, 30.0)
		if signature:
			current_gap -= 12.0 + zone_progress * 8.0
		if boss:
			current_gap -= 14.0
		current_gap = maxf(270.0, current_gap)

		var coin_count: int = rng.randi_range(2, 4)
		if zone >= 4:
			coin_count = rng.randi_range(2, 3)
		var coin_risk: float = clampf(0.46 + difficulty * 0.38 + (0.08 if signature else 0.0), 0.42, 0.90)
		var coin_pattern: String = _coin_pattern_for(zone, i, signature, rng)

		segments.append({
			"x": 900.0 + float(i) * spacing,
			"gap_y": target_y,
			"gap": current_gap,
			"width": rng.randf_range(116.0, 174.0),
			"moving": moving,
			"gate_type": gate_type,
			"amplitude": move_amplitude,
			"move_speed": rng.randf_range(0.78, 1.52 + difficulty * 0.18),
			"pulse_amount": rng.randf_range(42.0, 78.0),
			"pulse_speed": rng.randf_range(1.45, 2.35),
			"coin_arc": coin_count,
			"coin_pattern": coin_pattern,
			"coin_risk": coin_risk,
			"powerup": powerup,
			"special": special,
			"special_y": _special_y(special, target_y, current_gap, i, rng),
			"special_pair_y": _portal_pair_y(target_y),
			"special_strength": 0.75 + difficulty * 0.55,
			"zone": zone
		})

	return {
		"level": level,
		"speed": base_speed,
		"segments": segments,
		"reward": 55 + level * 4 + (35 if signature else 0) + (75 if boss else 0),
		"theme_index": zone,
		"zone": zone,
		"zone_name": zone_name(zone),
		"pattern": pattern,
		"signature": signature,
		"boss": boss,
		"challenge_name": _challenge_name(level, zone, signature, boss)
	}

static func build_endless_segment(index: int, seed_value: int = 44119) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + index * 6151
	var difficulty: float = clampf(float(index) / 95.0, 0.0, 1.0)
	var zone: int = int(floor(float(index) / 12.0)) % 8
	var gap_size: float = lerpf(505.0, 288.0, difficulty)
	var target_y: float = rng.randf_range(400.0, 1520.0)
	var gate_type: String = _gate_type_for(zone, mini(15, index + 1), index, index % 8 == 7, rng)
	var moving: bool = gate_type == "moving"
	var powerup: String = ""

	if index > 2 and index % 7 == 0 and rng.randf() < 0.62:
		var options := ["magnet", "shield", "slow"]
		powerup = options[rng.randi_range(0, options.size() - 1)]

	var move_amplitude: float = 0.0
	if moving:
		move_amplitude = rng.randf_range(70.0, 215.0)
	var special: String = _special_for_segment(zone, index + 1, index, index % 8 == 7, false, rng)

	return {
		"x": 0.0,
		"gap_y": target_y,
		"gap": gap_size,
		"width": rng.randf_range(110.0, 178.0),
		"moving": moving,
		"gate_type": gate_type,
		"amplitude": move_amplitude,
		"move_speed": rng.randf_range(0.74, 1.62),
		"pulse_amount": rng.randf_range(42.0, 78.0),
		"pulse_speed": rng.randf_range(1.45, 2.4),
		"coin_arc": rng.randi_range(2, 4),
		"coin_pattern": _coin_pattern_for(zone, index, false, rng),
		"coin_risk": clampf(0.50 + difficulty * 0.36, 0.50, 0.88),
		"powerup": powerup,
		"special": special,
		"special_y": _special_y(special, target_y, gap_size, index, rng),
		"special_pair_y": _portal_pair_y(target_y),
		"special_strength": 0.78 + difficulty * 0.5,
		"zone": zone
	}

static func endless_speed(index: int) -> float:
	return minf(700.0, 360.0 + float(index) * 3.4)

static func _pattern_for_level(level: int, zone: int) -> String:
	var pattern_index: int = (level + zone * 2) % 6
	return ["drift", "wave", "slalom", "stair", "sine_tunnel", "switchback"][pattern_index]

static func _pattern_y(pattern: String, index: int, _count: int, last_y: float, difficulty: float, rng: RandomNumberGenerator) -> float:
	var amplitude: float = lerpf(260.0, 520.0, difficulty)
	match pattern:
		"wave":
			return clampf(960.0 + sin(float(index) * 0.88 + 0.4) * amplitude, 370.0, 1550.0)
		"slalom":
			var side: float = -1.0 if index % 2 == 0 else 1.0
			return clampf(960.0 + side * amplitude * 0.76, 380.0, 1540.0)
		"stair":
			var step_index: int = index % 6
			var direction: float = 1.0 if int(floor(float(index) / 6.0)) % 2 == 0 else -1.0
			return clampf(960.0 + direction * (float(step_index) - 2.5) * 145.0, 370.0, 1550.0)
		"sine_tunnel":
			return clampf(960.0 + sin(float(index) * 1.18) * amplitude * 0.62 + sin(float(index) * 0.33) * 115.0, 360.0, 1560.0)
		"switchback":
			if index % 4 < 2:
				return clampf(590.0 + rng.randf_range(-90.0, 90.0), 360.0, 1560.0)
			return clampf(1330.0 + rng.randf_range(-90.0, 90.0), 360.0, 1560.0)
		_:
			var max_shift: float = lerpf(280.0, 500.0, difficulty)
			return clampf(last_y + rng.randf_range(-max_shift, max_shift), 380.0, 1540.0)

static func _gate_type_for(zone: int, local_level: int, index: int, signature: bool, rng: RandomNumberGenerator) -> String:
	if zone == 0:
		return "moving" if local_level >= 8 and index > 1 and rng.randf() < 0.24 else "basic"
	if zone == 1:
		return ["basic", "moving", "pulse", "moving"][rng.randi_range(0, 3)]
	if zone == 2:
		return ["basic", "moving", "basic", "pulse"][rng.randi_range(0, 3)]
	if zone == 3:
		return ["pulse", "laser", "basic", "pulse"][rng.randi_range(0, 3)]
	if zone == 4:
		return ["moving", "pulse", "basic", "moving"][rng.randi_range(0, 3)]
	if zone == 5:
		return ["laser", "basic", "pulse", "laser"][rng.randi_range(0, 3)]
	if zone == 6:
		return ["pulse", "laser", "moving", "laser"][rng.randi_range(0, 3)]
	var final_types := ["moving", "pulse", "laser", "basic"]
	if signature and index % 3 == 0:
		return "laser"
	return final_types[rng.randi_range(0, final_types.size() - 1)]

static func _special_for_segment(zone: int, level: int, index: int, signature: bool, boss: bool, rng: RandomNumberGenerator) -> String:
	if index < 2:
		return ""
	# Signature levels always contain authored-feeling special beats instead of relying on luck.
	if boss and index % 2 == 0:
		match level:
			20: return "spinner" if index % 4 == 0 else "speed_zone"
			40: return "asteroid"
			60: return "speed_zone" if index % 4 == 0 else "spinner"
			80: return "gravity_zone" if index % 4 == 0 else "gravity_well"
			100: return "portal" if index % 4 == 0 else "gravity_well"
			120:
				var core_choices := ["asteroid", "spinner", "gravity_zone", "gravity_well", "portal", "speed_zone"]
				return core_choices[int(index / 2) % core_choices.size()]
	if signature and index % 3 == 0:
		match zone:
			0: return ""
			1: return "spinner"
			2: return "asteroid"
			3: return "speed_zone" if index % 2 == 0 else "spinner"
			4: return "gravity_zone"
			5: return "gravity_well"
			6: return "portal"
			_: return "spinner"
	var chance: float = 0.13 + float(zone) * 0.035
	if signature:
		chance += 0.12
	if boss:
		chance += 0.10
	if rng.randf() > chance:
		return ""
	match zone:
		0:
			return ""
		1:
			return "spinner" if index % 2 == 0 else "speed_zone"
		2:
			return "asteroid"
		3:
			return "spinner" if index % 3 != 0 else "speed_zone"
		4:
			return "gravity_zone" if index % 2 == 0 else "spinner"
		5:
			return "gravity_well" if index % 2 == 0 else "asteroid"
		6:
			return "portal" if index % 3 == 0 else "gravity_well"
		_:
			var choices := ["asteroid", "spinner", "gravity_zone", "gravity_well", "portal", "speed_zone"]
			return choices[rng.randi_range(0, choices.size() - 1)]

static func _coin_pattern_for(zone: int, index: int, signature: bool, rng: RandomNumberGenerator) -> String:
	if zone <= 1 and not signature:
		return ["wave", "upper", "lower"][rng.randi_range(0, 2)]
	var patterns := ["upper", "lower", "zigzag", "wave", "edge"]
	if index % 5 == 0:
		return "zigzag"
	return patterns[rng.randi_range(0, patterns.size() - 1)]

static func _special_y(special: String, gate_y: float, gap: float, index: int, rng: RandomNumberGenerator) -> float:
	if special == "asteroid" or special == "spinner":
		var side: float = -1.0 if index % 2 == 0 else 1.0
		return clampf(gate_y + side * (gap * 0.34 + rng.randf_range(90.0, 150.0)), 220.0, 1700.0)
	if special == "gravity_well":
		return clampf(gate_y + rng.randf_range(-260.0, 260.0), 260.0, 1660.0)
	return gate_y

static func _portal_pair_y(gate_y: float) -> float:
	return 1440.0 if gate_y < 960.0 else 480.0

static func _challenge_name(level: int, zone: int, signature: bool, boss: bool) -> String:
	if boss:
		match level:
			20: return "NEON GAUNTLET"
			40: return "METEOR STORM"
			60: return "SOLAR SPRINT"
			80: return "GRAVITY STORM"
			100: return "SINGULARITY CHAIN"
			120: return "CORE GAUNTLET"
			_: return "SECTOR TRIAL"
	if signature:
		return "%s TRIAL" % zone_name(zone)
	return zone_name(zone)
