extends Node2D

signal collided

var hazard_type: String = "asteroid"
var tint: Color = Color("9a718f")
var time_alive: float = 0.0
var base_position: Vector2 = Vector2.ZERO
var radius: float = 54.0
var length: float = 240.0
var strength: float = 1.0
var paired_y: float = 480.0
var portal_cooldown: float = 0.0
var rotation_speed: float = 1.2
var asteroid_points: PackedVector2Array = PackedVector2Array()

func _ready() -> void:
	set_meta("entity_type", "hazard")

func setup(config: Dictionary, hazard_tint: Color) -> void:
	hazard_type = str(config.get("special", "asteroid"))
	position = Vector2(float(config.get("x", 0.0)), float(config.get("special_y", 960.0)))
	base_position = position
	paired_y = float(config.get("special_pair_y", 480.0))
	strength = float(config.get("special_strength", 1.0))
	tint = hazard_tint
	rotation_speed = 0.95 + strength * 0.42

	match hazard_type:
		"asteroid":
			radius = 48.0 + strength * 10.0
			_create_circle_hazard(radius)
			_build_asteroid_shape()
		"spinner":
			length = 210.0 + strength * 65.0
			radius = 28.0
			_create_spinner_hazards()
		"gravity_zone":
			_create_zone_visual_meta()
		"gravity_well":
			radius = 96.0
		"portal":
			radius = 58.0
		"speed_zone":
			_create_zone_visual_meta()
	queue_redraw()

func _process(delta: float) -> void:
	time_alive += delta
	portal_cooldown = maxf(0.0, portal_cooldown - delta)
	if hazard_type == "asteroid":
		rotation += delta * rotation_speed
	elif hazard_type == "spinner":
		rotation += delta * rotation_speed * 1.35
	queue_redraw()

func _create_circle_hazard(circle_radius: float) -> void:
	var area := Area2D.new()
	area.collision_layer = 2
	area.collision_mask = 1
	area.monitoring = true
	var shape_node := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = circle_radius
	shape_node.shape = circle
	area.add_child(shape_node)
	area.body_entered.connect(_on_body_entered)
	add_child(area)

func _create_spinner_hazards() -> void:
	for side in [-1.0, 1.0]:
		var area := Area2D.new()
		area.position = Vector2(length * 0.5 * side, 0.0)
		area.collision_layer = 2
		area.collision_mask = 1
		area.monitoring = true
		var shape_node := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = radius
		shape_node.shape = circle
		area.add_child(shape_node)
		area.body_entered.connect(_on_body_entered)
		add_child(area)

func _create_zone_visual_meta() -> void:
	set_meta("zone_width", 310.0)

func _build_asteroid_shape() -> void:
	asteroid_points.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = int(base_position.x * 31.0 + base_position.y * 17.0) + 551
	for i in range(12):
		var angle: float = TAU * float(i) / 12.0
		var local_radius: float = radius * rng.randf_range(0.76, 1.08)
		asteroid_points.append(Vector2(cos(angle), sin(angle)) * local_radius)

func _on_body_entered(_body: Node2D) -> void:
	collided.emit()

func apply_to_player(player: Node2D, delta: float) -> void:
	if player == null:
		return
	var distance_x: float = absf(global_position.x - player.global_position.x)
	match hazard_type:
		"gravity_zone":
			if distance_x < 170.0:
				player.call("set_environment_gravity_multiplier", 1.0 + 0.50 * strength)
		"gravity_well":
			var distance: float = global_position.distance_to(player.global_position)
			if distance < 430.0 and distance > 10.0:
				var direction_y: float = signf(global_position.y - player.global_position.y)
				var pull: float = (1.0 - distance / 430.0) * 820.0 * strength
				var current_velocity: Vector2 = player.get("velocity")
				current_velocity.y += direction_y * pull * delta
				player.set("velocity", current_velocity)
		"portal":
			if portal_cooldown <= 0.0 and distance_x < 58.0 and absf(player.global_position.y - global_position.y) < 78.0:
				player.global_position.y = paired_y
				var current_velocity: Vector2 = player.get("velocity")
				current_velocity.y *= 0.58
				player.set("velocity", current_velocity)
				portal_cooldown = 0.8

func speed_multiplier_for(player_position: Vector2) -> float:
	if hazard_type != "speed_zone":
		return 1.0
	if absf(global_position.x - player_position.x) < 175.0:
		return 1.16 + 0.08 * strength
	return 1.0

func _draw() -> void:
	match hazard_type:
		"asteroid":
			_draw_asteroid()
		"spinner":
			_draw_spinner()
		"gravity_zone":
			_draw_gravity_zone()
		"gravity_well":
			_draw_gravity_well()
		"portal":
			_draw_portal()
		"speed_zone":
			_draw_speed_zone()

func _draw_asteroid() -> void:
	if asteroid_points.size() < 3:
		return
	draw_colored_polygon(asteroid_points, Color("443947"))
	var outline: PackedVector2Array = asteroid_points.duplicate()
	outline.append(asteroid_points[0])
	draw_polyline(outline, tint.lightened(0.18), 5.0, true)
	draw_circle(Vector2(-13.0, -10.0), radius * 0.20, Color("241d2a"))
	draw_arc(Vector2(-13.0, -10.0), radius * 0.16, 3.6, 5.9, 12, Color(1.0, 1.0, 1.0, 0.12), 2.0)
	draw_circle(Vector2(18.0, 12.0), radius * 0.12, Color("2f2635"))

func _draw_spinner() -> void:
	var glow := Color(tint.r, tint.g, tint.b, 0.12)
	draw_line(Vector2(-length * 0.5, 0.0), Vector2(length * 0.5, 0.0), glow, 22.0, true)
	draw_line(Vector2(-length * 0.5, 0.0), Vector2(length * 0.5, 0.0), tint.lightened(0.24), 6.0, true)
	draw_circle(Vector2.ZERO, 18.0, tint)
	draw_circle(Vector2(-length * 0.5, 0.0), radius + 9.0, Color(tint.r, tint.g, tint.b, 0.13))
	draw_circle(Vector2(length * 0.5, 0.0), radius + 9.0, Color(tint.r, tint.g, tint.b, 0.13))
	draw_circle(Vector2(-length * 0.5, 0.0), radius, tint.lightened(0.10))
	draw_circle(Vector2(length * 0.5, 0.0), radius, tint.lightened(0.10))

func _draw_gravity_zone() -> void:
	var alpha: float = 0.08 + sin(time_alive * 4.0) * 0.025
	draw_rect(Rect2(-155.0, -330.0, 310.0, 660.0), Color(tint.r, tint.g, tint.b, alpha), true)
	for i in range(5):
		var y: float = -260.0 + float(i) * 130.0
		draw_line(Vector2(-100.0, y), Vector2(100.0, y), Color(tint.r, tint.g, tint.b, 0.30), 3.0)
		draw_line(Vector2(70.0, y - 22.0), Vector2(100.0, y), tint, 3.0)
		draw_line(Vector2(70.0, y + 22.0), Vector2(100.0, y), tint, 3.0)

func _draw_gravity_well() -> void:
	var pulse_radius: float = 82.0 + sin(time_alive * 2.7) * 8.0
	draw_circle(Vector2.ZERO, pulse_radius + 34.0, Color(tint.r, tint.g, tint.b, 0.06))
	draw_circle(Vector2.ZERO, 48.0, Color("070711"))
	for i in range(3):
		draw_arc(Vector2.ZERO, 64.0 + float(i) * 15.0, time_alive * (0.8 + i * 0.2), time_alive * (0.8 + i * 0.2) + 4.5, 36, Color(tint.r, tint.g, tint.b, 0.55 - i * 0.10), 4.0)

func _draw_portal() -> void:
	var spin: float = time_alive * 2.0
	draw_circle(Vector2.ZERO, radius + 18.0, Color(tint.r, tint.g, tint.b, 0.08))
	draw_arc(Vector2.ZERO, radius, spin, spin + 4.5, 38, tint.lightened(0.22), 8.0)
	draw_arc(Vector2.ZERO, radius - 12.0, -spin * 0.8, -spin * 0.8 + 4.7, 38, Color(1.0, 1.0, 1.0, 0.48), 4.0)
	draw_circle(Vector2.ZERO, radius - 24.0, Color("11142c"))

func _draw_speed_zone() -> void:
	var alpha: float = 0.07 + sin(time_alive * 5.0) * 0.02
	draw_rect(Rect2(-165.0, -300.0, 330.0, 600.0), Color(tint.r, tint.g, tint.b, alpha), true)
	for y in [-180.0, 0.0, 180.0]:
		for x in [-75.0, 0.0, 75.0]:
			var p := Vector2(x, y)
			draw_line(p + Vector2(-34.0, -22.0), p, Color(tint.r, tint.g, tint.b, 0.40), 4.0)
			draw_line(p + Vector2(-34.0, 22.0), p, Color(tint.r, tint.g, tint.b, 0.40), 4.0)
