extends Node2D

var stars: Array = []
var dust: Array = []
var drift: float = 0.0
var zone_index: int = 0

const PALETTES := [
	{"bg": Color("07091b"), "nebula_a": Color(0.22, 0.08, 0.38, 0.12), "nebula_b": Color(0.02, 0.34, 0.42, 0.10), "star": Color("dcecff")},
	{"bg": Color("09071c"), "nebula_a": Color(0.45, 0.04, 0.42, 0.15), "nebula_b": Color(0.02, 0.42, 0.55, 0.11), "star": Color("f1dcff")},
	{"bg": Color("0b0b16"), "nebula_a": Color(0.24, 0.20, 0.16, 0.14), "nebula_b": Color(0.20, 0.12, 0.08, 0.10), "star": Color("e8e0d5")},
	{"bg": Color("17090b"), "nebula_a": Color(0.58, 0.16, 0.03, 0.15), "nebula_b": Color(0.44, 0.04, 0.18, 0.10), "star": Color("fff0d8")},
	{"bg": Color("07151a"), "nebula_a": Color(0.02, 0.44, 0.44, 0.13), "nebula_b": Color(0.16, 0.10, 0.52, 0.10), "star": Color("d9fffb")},
	{"bg": Color("05050d"), "nebula_a": Color(0.16, 0.04, 0.26, 0.14), "nebula_b": Color(0.02, 0.10, 0.20, 0.11), "star": Color("d9d8ed")},
	{"bg": Color("090510"), "nebula_a": Color(0.35, 0.02, 0.30, 0.15), "nebula_b": Color(0.04, 0.18, 0.42, 0.11), "star": Color("f0dfff")},
	{"bg": Color("10080c"), "nebula_a": Color(0.52, 0.12, 0.04, 0.15), "nebula_b": Color(0.30, 0.04, 0.30, 0.12), "star": Color("fff4e4")}
]

func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 728319
	for _i in range(95):
		stars.append({
			"position": Vector2(rng.randf_range(0.0, 1080.0), rng.randf_range(0.0, 1920.0)),
			"radius": rng.randf_range(1.0, 3.6),
			"alpha": rng.randf_range(0.25, 0.9),
			"speed": rng.randf_range(5.0, 18.0)
		})
	for _i in range(20):
		dust.append({"position": Vector2(rng.randf_range(0.0, 1080.0), rng.randf_range(0.0, 1920.0)), "size": rng.randf_range(5.0, 18.0)})
	queue_redraw()

func set_zone(new_zone_index: int) -> void:
	zone_index = clampi(new_zone_index, 0, PALETTES.size() - 1)
	queue_redraw()

func _process(delta: float) -> void:
	drift += delta
	for i in range(stars.size()):
		var star: Dictionary = stars[i]
		var star_position: Vector2 = star["position"]
		star_position.x -= float(star["speed"]) * delta
		if star_position.x < -8.0:
			star_position.x = 1088.0
		star["position"] = star_position
		stars[i] = star
	queue_redraw()

func _draw() -> void:
	var palette: Dictionary = PALETTES[zone_index]
	draw_rect(Rect2(0.0, 0.0, 1080.0, 1920.0), palette["bg"])
	draw_circle(Vector2(850.0, 360.0), 330.0, palette["nebula_a"])
	draw_circle(Vector2(160.0, 1500.0), 420.0, palette["nebula_b"])
	_draw_zone_landmark()
	var star_color: Color = palette["star"]
	for star_variant in stars:
		var star: Dictionary = star_variant
		var star_position: Vector2 = star["position"]
		var twinkle: float = 0.75 + sin(drift * 2.0 + star_position.x * 0.02) * 0.2
		var alpha: float = float(star["alpha"]) * twinkle
		draw_circle(star_position, float(star["radius"]), Color(star_color.r, star_color.g, star_color.b, alpha))
	if zone_index == 2 or zone_index == 7:
		for entry in dust:
			var p: Vector2 = entry["position"]
			var shifted_x: float = fposmod(p.x - drift * (18.0 + float(entry["size"])), 1120.0)
			draw_circle(Vector2(shifted_x, p.y), float(entry["size"]) * 0.18, Color(0.62, 0.56, 0.50, 0.20))

func _draw_zone_landmark() -> void:
	match zone_index:
		0:
			draw_circle(Vector2(925.0, 1450.0), 118.0, Color(0.12, 0.32, 0.58, 0.12))
		1:
			for x in range(120, 1080, 220):
				draw_line(Vector2(float(x), 0.0), Vector2(float(x) - 120.0, 1920.0), Color(0.48, 0.22, 0.95, 0.025), 2.0)
		2:
			draw_arc(Vector2(860.0, 620.0), 250.0, 0.15, 2.9, 50, Color(0.45, 0.39, 0.32, 0.10), 14.0)
		3:
			draw_circle(Vector2(950.0, 300.0), 145.0, Color(1.0, 0.36, 0.08, 0.12))
		4:
			draw_arc(Vector2(860.0, 620.0), 220.0, 0.0, TAU, 70, Color(0.16, 0.86, 0.86, 0.08), 3.0)
		5:
			draw_circle(Vector2(910.0, 430.0), 100.0, Color(0.02, 0.02, 0.04, 0.65))
			draw_arc(Vector2(910.0, 430.0), 130.0, 0.0, TAU, 60, Color(0.55, 0.24, 0.80, 0.10), 7.0)
		6:
			draw_arc(Vector2(860.0, 420.0), 165.0, drift * 0.08, drift * 0.08 + PI * 1.6, 70, Color(0.50, 0.22, 0.95, 0.10), 6.0)
		7:
			draw_circle(Vector2(920.0, 360.0), 90.0, Color(1.0, 0.26, 0.10, 0.08))
			draw_arc(Vector2(920.0, 360.0), 145.0, 0.0, TAU, 70, Color(1.0, 0.56, 0.16, 0.08), 4.0)
