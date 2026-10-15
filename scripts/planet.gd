extends CharacterBody2D

const PLAYER_X: float = 220.0
const GRAVITY_STRENGTH: float = 2350.0
const MAX_VERTICAL_SPEED: float = 1450.0
const PLANET_RADIUS: float = 42.0
const TRAIL_LIFETIME: float = 0.52
const TRAIL_EMIT_INTERVAL: float = 0.018

var gravity_direction: float = 1.0
var active: bool = false
var shield_charges: int = 0
var skin_id: String = "terra"
var pulse: float = 0.0
var perfect_flash: float = 0.0
var visual_scroll_speed: float = 360.0
var rush_visual: bool = false
var visual_time: float = 0.0
var trail_emit_accumulator: float = 0.0
var trail_points: Array[Vector2] = []
var trail_ages: Array[float] = []
var last_combo_seen: int = 0

const SKINS := {
	"terra": {"base": Color("4ad5ff"), "accent": Color("66ff9a")},
	"mars": {"base": Color("ff765f"), "accent": Color("ffcf7c")},
	"neon": {"base": Color("c55cff"), "accent": Color("34f5ff")},
	"saturn": {"base": Color("f8d88b"), "accent": Color("c49cff")},
	"void": {"base": Color("35335c"), "accent": Color("ff4ecb")},
	"sun": {"base": Color("ffb22e"), "accent": Color("fff18b")},
	"ice": {"base": Color("b8f6ff"), "accent": Color("6ea8ff")},
	"toxic": {"base": Color("9dff4f"), "accent": Color("ffe64f")}
}

func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	var collision_shape: CollisionShape2D = CollisionShape2D.new()
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = PLANET_RADIUS
	collision_shape.shape = circle
	add_child(collision_shape)
	queue_redraw()

func reset_player(start_position: Vector2, new_skin_id: String) -> void:
	global_position = start_position
	velocity = Vector2.ZERO
	gravity_direction = 1.0
	shield_charges = 0
	skin_id = new_skin_id
	pulse = 0.0
	perfect_flash = 0.0
	visual_time = 0.0
	trail_emit_accumulator = 0.0
	trail_points.clear()
	trail_ages.clear()
	last_combo_seen = 0
	active = true
	visible = true
	queue_redraw()

func set_gravity(direction: float) -> void:
	if not active:
		return
	var normalized_direction: float = signf(direction)
	if normalized_direction == 0.0:
		return
	gravity_direction = normalized_direction
	velocity.y = velocity.y * 0.42 + gravity_direction * 155.0
	pulse = 1.0
	queue_redraw()

func toggle_gravity() -> void:
	set_gravity(-gravity_direction)

func set_visual_speed(speed: float) -> void:
	visual_scroll_speed = clampf(speed, 250.0, 900.0)

func set_rush_visual(enabled: bool) -> void:
	rush_visual = enabled

func trigger_perfect_visual() -> void:
	perfect_flash = 1.0
	pulse = maxf(pulse, 0.7)
	queue_redraw()

func add_shield() -> void:
	shield_charges = 1
	pulse = 1.0
	queue_redraw()

func consume_shield() -> bool:
	if shield_charges <= 0:
		return false
	shield_charges -= 1
	pulse = 1.0
	queue_redraw()
	return true

func _physics_process(delta: float) -> void:
	_sync_parent_visual_state()
	visual_time += delta
	perfect_flash = maxf(0.0, perfect_flash - delta * 2.7)
	pulse = maxf(0.0, pulse - delta * 2.8)

	if not active:
		_update_trail(delta, 0.0, false)
		queue_redraw()
		return

	var previous_y: float = global_position.y
	velocity.x = 0.0
	velocity.y += gravity_direction * GRAVITY_STRENGTH * delta
	velocity.y = clampf(velocity.y, -MAX_VERTICAL_SPEED, MAX_VERTICAL_SPEED)
	move_and_slide()
	global_position.x = PLAYER_X
	var vertical_delta: float = global_position.y - previous_y
	_update_trail(delta, vertical_delta, true)
	queue_redraw()

func _sync_parent_visual_state() -> void:
	var parent_node: Node = get_parent()
	if parent_node == null:
		return

	var speed_value: Variant = parent_node.get("world_speed")
	var slow_value: Variant = parent_node.get("slow_time")
	var rush_value: Variant = parent_node.get("rush_time")
	var combo_value: Variant = parent_node.get("combo")

	var speed_base: float = visual_scroll_speed
	if typeof(speed_value) == TYPE_FLOAT or typeof(speed_value) == TYPE_INT:
		speed_base = float(speed_value)
	var slow_factor: float = 1.0
	if typeof(slow_value) == TYPE_FLOAT or typeof(slow_value) == TYPE_INT:
		if float(slow_value) > 0.0:
			slow_factor = 0.64
	var rush_factor: float = 1.0
	rush_visual = false
	if typeof(rush_value) == TYPE_FLOAT or typeof(rush_value) == TYPE_INT:
		rush_visual = float(rush_value) > 0.0
		if rush_visual:
			rush_factor = 1.08
	visual_scroll_speed = clampf(speed_base * SaveData.speed_multiplier() * slow_factor * rush_factor, 250.0, 900.0)

	if typeof(combo_value) == TYPE_INT or typeof(combo_value) == TYPE_FLOAT:
		var current_combo: int = int(combo_value)
		if current_combo > last_combo_seen:
			perfect_flash = 1.0
		last_combo_seen = current_combo

func _update_trail(delta: float, vertical_delta: float, emit_new: bool) -> void:
	for i in range(trail_points.size()):
		var point: Vector2 = trail_points[i]
		point.x -= visual_scroll_speed * delta
		point.y -= vertical_delta
		trail_points[i] = point
		trail_ages[i] = trail_ages[i] + delta

	for i in range(trail_points.size() - 1, -1, -1):
		if trail_ages[i] > TRAIL_LIFETIME or trail_points[i].x < -360.0:
			trail_points.remove_at(i)
			trail_ages.remove_at(i)

	if not emit_new:
		return

	trail_emit_accumulator += delta
	while trail_emit_accumulator >= TRAIL_EMIT_INTERVAL:
		trail_emit_accumulator -= TRAIL_EMIT_INTERVAL
		trail_points.append(Vector2(-PLANET_RADIUS + 4.0, 0.0))
		trail_ages.append(0.0)
		if trail_points.size() > 34:
			trail_points.remove_at(0)
			trail_ages.remove_at(0)

func _draw() -> void:
	var skin: Dictionary = SKINS.get(skin_id, SKINS["terra"])
	var base: Color = skin["base"]
	var accent: Color = skin["accent"]
	_draw_trail(accent)
	_draw_planet(base, accent)
	_draw_gravity_hint(accent)
	_draw_shield()

func _draw_trail(accent: Color) -> void:
	if trail_points.size() < 2:
		return
	var rush_multiplier: float = 1.45 if rush_visual else 1.0
	for i in range(1, trail_points.size()):
		var age_a: float = trail_ages[i - 1]
		var age_b: float = trail_ages[i]
		var life_a: float = clampf(1.0 - age_a / TRAIL_LIFETIME, 0.0, 1.0)
		var life_b: float = clampf(1.0 - age_b / TRAIL_LIFETIME, 0.0, 1.0)
		var life: float = minf(life_a, life_b)
		var glow_alpha: float = life * life * 0.16 * rush_multiplier
		var core_alpha: float = life * life * 0.48 * rush_multiplier
		var width_glow: float = 20.0 * life + 3.0
		var width_core: float = 8.0 * life + 1.5
		draw_line(trail_points[i - 1], trail_points[i], Color(accent.r, accent.g, accent.b, glow_alpha), width_glow, true)
		draw_line(trail_points[i - 1], trail_points[i], Color(1.0, 1.0, 1.0, core_alpha * 0.38), width_core, true)
		if i % 5 == 0 and life > 0.22:
			var sparkle_radius: float = 1.5 + life * 2.4
			draw_circle(trail_points[i] + Vector2(0.0, sin(visual_time * 7.0 + float(i)) * 5.0), sparkle_radius, Color(accent.r, accent.g, accent.b, life * 0.55))

func _draw_planet(base: Color, accent: Color) -> void:
	var spin: float = visual_time * 0.34
	var glow_boost: float = perfect_flash * 0.20 + (0.08 if rush_visual else 0.0)
	var glow_radius: float = 54.0 + pulse * 7.0 + perfect_flash * 5.0

	if skin_id == "sun":
		_draw_solar_corona(accent)
	elif skin_id == "saturn":
		_draw_saturn_ring_back(accent)

	draw_circle(Vector2.ZERO, glow_radius + 8.0, Color(accent.r, accent.g, accent.b, 0.035 + glow_boost * 0.5))
	draw_circle(Vector2.ZERO, glow_radius, Color(accent.r, accent.g, accent.b, 0.11 + pulse * 0.06 + glow_boost))
	draw_circle(Vector2.ZERO, PLANET_RADIUS + 2.0, base.darkened(0.42))
	draw_circle(Vector2.ZERO, PLANET_RADIUS, base.darkened(0.18))
	draw_circle(Vector2(-3.0, -4.0), 37.0, base)
	draw_circle(Vector2(-7.0, -8.0), 31.0, base.lightened(0.08))

	var shadow_color: Color = base.darkened(0.45)
	shadow_color.a = 0.40
	draw_circle(Vector2(10.0, 12.0), 27.0, shadow_color)

	match skin_id:
		"terra":
			_draw_terra_surface(accent, spin)
		"mars":
			_draw_mars_surface(base, accent, spin)
		"neon":
			_draw_neon_surface(accent, spin)
		"saturn":
			_draw_saturn_surface(accent, spin)
		"void":
			_draw_void_surface(accent, spin)
		"sun":
			_draw_sun_surface(accent, spin)
		"ice":
			_draw_ice_surface(accent, spin)
		"toxic":
			_draw_toxic_surface(accent, spin)

	draw_circle(Vector2(-16.0, -17.0), 8.5, Color(1.0, 1.0, 1.0, 0.18 + perfect_flash * 0.14))
	draw_arc(Vector2.ZERO, 34.5, -2.55, -0.75, 24, Color(1.0, 1.0, 1.0, 0.34 + perfect_flash * 0.18), 3.0)

	if skin_id == "saturn":
		_draw_saturn_ring_front(accent)

	if perfect_flash > 0.0:
		draw_arc(Vector2.ZERO, 52.0 + perfect_flash * 7.0, 0.0, TAU, 56, Color(1.0, 0.90, 0.48, perfect_flash * 0.72), 3.0)

func _draw_terra_surface(accent: Color, spin: float) -> void:
	var land: Color = Color(accent.r, accent.g, accent.b, 0.82)
	var continent_a := PackedVector2Array([
		_rotate_point(Vector2(-22.0, -7.0), spin * 0.25),
		_rotate_point(Vector2(-12.0, -18.0), spin * 0.25),
		_rotate_point(Vector2(1.0, -15.0), spin * 0.25),
		_rotate_point(Vector2(7.0, -6.0), spin * 0.25),
		_rotate_point(Vector2(-1.0, 2.0), spin * 0.25),
		_rotate_point(Vector2(-13.0, 3.0), spin * 0.25)
	])
	var continent_b := PackedVector2Array([
		_rotate_point(Vector2(7.0, 10.0), spin * 0.18),
		_rotate_point(Vector2(19.0, 5.0), spin * 0.18),
		_rotate_point(Vector2(25.0, 13.0), spin * 0.18),
		_rotate_point(Vector2(16.0, 23.0), spin * 0.18),
		_rotate_point(Vector2(6.0, 20.0), spin * 0.18)
	])
	draw_colored_polygon(continent_a, land)
	draw_colored_polygon(continent_b, Color(land.r, land.g, land.b, 0.62))
	draw_arc(Vector2(-2.0, -1.0), 30.0, 3.5, 5.3, 18, Color(1.0, 1.0, 1.0, 0.19), 2.5)
	draw_arc(Vector2(5.0, 5.0), 23.0, 0.2, 1.5, 14, Color(1.0, 1.0, 1.0, 0.12), 2.0)

func _draw_mars_surface(base: Color, accent: Color, spin: float) -> void:
	var crater_color: Color = base.darkened(0.34)
	var crater_light: Color = Color(accent.r, accent.g, accent.b, 0.32)
	var c1: Vector2 = _rotate_point(Vector2(-14.0, -7.0), spin * 0.18)
	var c2: Vector2 = _rotate_point(Vector2(15.0, 9.0), spin * 0.12)
	var c3: Vector2 = _rotate_point(Vector2(4.0, -22.0), spin * 0.15)
	draw_circle(c1, 8.0, crater_color)
	draw_arc(c1 + Vector2(-1.0, -1.0), 6.0, 3.6, 5.9, 12, crater_light, 2.0)
	draw_circle(c2, 5.5, crater_color)
	draw_arc(c2, 4.2, 3.4, 5.7, 10, crater_light, 1.6)
	draw_circle(c3, 4.0, Color(crater_color.r, crater_color.g, crater_color.b, 0.75))

func _draw_neon_surface(accent: Color, spin: float) -> void:
	var pulse_alpha: float = 0.52 + sin(visual_time * 4.0) * 0.12
	draw_arc(Vector2.ZERO, 26.0, spin, spin + 2.1, 24, Color(accent.r, accent.g, accent.b, pulse_alpha), 4.5)
	draw_arc(Vector2.ZERO, 18.0, spin + 2.6, spin + 5.2, 22, Color(1.0, 1.0, 1.0, 0.34), 2.5)
	draw_circle(_rotate_point(Vector2(22.0, 0.0), spin), 4.5, Color(accent.r, accent.g, accent.b, 0.88))

func _draw_saturn_surface(accent: Color, spin: float) -> void:
	draw_arc(Vector2.ZERO, 24.0, 3.35 + spin * 0.08, 5.65 + spin * 0.08, 20, Color(accent.r, accent.g, accent.b, 0.28), 4.0)
	draw_arc(Vector2.ZERO, 14.0, 0.25, 2.35, 18, Color(1.0, 1.0, 1.0, 0.13), 2.0)

func _draw_void_surface(accent: Color, spin: float) -> void:
	draw_circle(Vector2.ZERO, 20.0, Color("090816"))
	draw_arc(Vector2.ZERO, 27.0, spin, spin + 4.9, 44, Color(accent.r, accent.g, accent.b, 0.82), 4.0)
	draw_arc(Vector2.ZERO, 14.0, -spin * 1.4, -spin * 1.4 + 4.2, 34, Color(1.0, 1.0, 1.0, 0.26), 2.0)
	draw_circle(_rotate_point(Vector2(26.0, 0.0), spin), 3.0, accent)

func _draw_sun_surface(accent: Color, spin: float) -> void:
	for i in range(5):
		var angle: float = spin + float(i) * TAU / 5.0
		var hot_spot: Vector2 = Vector2(cos(angle), sin(angle)) * 19.0
		draw_circle(hot_spot, 5.5, Color(accent.r, accent.g, accent.b, 0.30))
	draw_arc(Vector2.ZERO, 26.0, spin, spin + 2.6, 24, Color(1.0, 1.0, 1.0, 0.23), 3.0)

func _draw_ice_surface(accent: Color, spin: float) -> void:
	var crack: Color = Color(accent.r, accent.g, accent.b, 0.58)
	var center: Vector2 = _rotate_point(Vector2(4.0, -2.0), spin * 0.10)
	var p1: Vector2 = center + _rotate_point(Vector2(15.0, -13.0), spin * 0.16)
	var p2: Vector2 = center + _rotate_point(Vector2(20.0, 8.0), spin * 0.12)
	var p3: Vector2 = center + _rotate_point(Vector2(-10.0, 20.0), spin * 0.14)
	draw_line(center, p1, crack, 2.2)
	draw_line(center, p2, crack, 2.0)
	draw_line(center, p3, crack, 2.0)
	draw_line(p1, p1 + Vector2(-5.0, -7.0), Color(1.0, 1.0, 1.0, 0.28), 1.4)

func _draw_toxic_surface(accent: Color, spin: float) -> void:
	for i in range(5):
		var angle: float = spin * 0.24 + float(i) * 1.19
		var radius: float = 11.0 + float((i * 7) % 15)
		var bubble_pos: Vector2 = Vector2(cos(angle), sin(angle)) * radius
		var bubble_radius: float = 3.5 + float(i % 3) * 1.7
		draw_circle(bubble_pos, bubble_radius, Color(accent.r, accent.g, accent.b, 0.48))
		draw_circle(bubble_pos + Vector2(-1.0, -1.0), bubble_radius * 0.35, Color(1.0, 1.0, 1.0, 0.34))

func _draw_solar_corona(accent: Color) -> void:
	for i in range(12):
		var angle: float = visual_time * 0.22 + TAU * float(i) / 12.0
		var ray: Vector2 = Vector2(cos(angle), sin(angle))
		var ray_length: float = 10.0 + sin(visual_time * 3.0 + float(i)) * 3.0
		draw_line(ray * 47.0, ray * (57.0 + ray_length), Color(accent.r, accent.g, accent.b, 0.52), 3.0)

func _draw_saturn_ring_back(accent: Color) -> void:
	draw_arc(Vector2.ZERO, 58.0, 3.15, TAU, 36, Color(accent.r, accent.g, accent.b, 0.34), 8.0)
	draw_arc(Vector2.ZERO, 64.0, 3.15, TAU, 36, Color(1.0, 1.0, 1.0, 0.12), 2.0)

func _draw_saturn_ring_front(accent: Color) -> void:
	draw_arc(Vector2.ZERO, 58.0, 0.0, 3.15, 36, Color(accent.r, accent.g, accent.b, 0.82), 7.0)
	draw_arc(Vector2.ZERO, 64.0, 0.0, 3.15, 36, Color(1.0, 1.0, 1.0, 0.22), 2.0)

func _draw_gravity_hint(accent: Color) -> void:
	var hint_y: float = -53.0 if gravity_direction < 0.0 else 53.0
	var hint_alpha: float = 0.24 + pulse * 0.36
	draw_circle(Vector2(0.0, hint_y), 4.0 + pulse * 2.0, Color(accent.r, accent.g, accent.b, hint_alpha))

func _draw_shield() -> void:
	if shield_charges <= 0:
		return
	var orbit: float = visual_time * 1.5
	draw_arc(Vector2.ZERO, 59.0, 0.0, TAU, 64, Color("76f7ff"), 5.0)
	draw_arc(Vector2.ZERO, 66.0, orbit, orbit + 1.7, 18, Color(1.0, 1.0, 1.0, 0.70), 3.0)
	var spark: Vector2 = Vector2(cos(orbit), sin(orbit)) * 59.0
	draw_circle(spark, 4.0, Color("d9fdff"))

func _rotate_point(point: Vector2, angle: float) -> Vector2:
	return point.rotated(angle)
