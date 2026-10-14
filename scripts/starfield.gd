extends Node2D

var stars: Array = []
var drift: float = 0.0

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
	draw_rect(Rect2(0.0, 0.0, 1080.0, 1920.0), Color("07091b"))
	draw_circle(Vector2(850.0, 360.0), 330.0, Color(0.22, 0.08, 0.38, 0.12))
	draw_circle(Vector2(160.0, 1500.0), 420.0, Color(0.02, 0.34, 0.42, 0.10))
	for star_variant in stars:
		var star: Dictionary = star_variant
		var star_position: Vector2 = star["position"]
		var twinkle := 0.75 + sin(drift * 2.0 + star_position.x * 0.02) * 0.2
		var alpha := float(star["alpha"]) * twinkle
		draw_circle(star_position, float(star["radius"]), Color(0.86, 0.93, 1.0, alpha))
