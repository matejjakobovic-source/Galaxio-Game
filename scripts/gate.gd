extends Node2D

signal collided

var gap_center: float = 960.0
var gap_size: float = 460.0
var base_gap_size: float = 460.0
var gate_width: float = 140.0
var gate_type: String = "basic"
var is_moving: bool = false
var amplitude: float = 0.0
var move_speed: float = 1.0
var pulse_amount: float = 56.0
var pulse_speed: float = 1.8
var phase: float = 0.0
var base_gap_center: float = 960.0
var passed: bool = false
var time_alive: float = 0.0
var tint: Color = Color("6c63ff")

func _ready() -> void:
	set_meta("entity_type", "gate")

func setup(config: Dictionary, gate_tint: Color) -> void:
	position.x = float(config.get("x", 0.0))
	gap_center = float(config.get("gap_y", 960.0))
	base_gap_center = gap_center
	gap_size = float(config.get("gap", 460.0))
	base_gap_size = gap_size
	gate_width = float(config.get("width", 140.0))
	gate_type = str(config.get("gate_type", "moving" if bool(config.get("moving", false)) else "basic"))
	is_moving = gate_type == "moving" or bool(config.get("moving", false))
	amplitude = float(config.get("amplitude", 0.0))
	move_speed = float(config.get("move_speed", 1.0))
	pulse_amount = float(config.get("pulse_amount", 56.0))
	pulse_speed = float(config.get("pulse_speed", 1.8))
	phase = fmod(position.x * 0.013, TAU)
	tint = gate_tint
	_create_hazard(true)
	_create_hazard(false)
	queue_redraw()

func _create_hazard(is_top: bool) -> void:
	var area := Area2D.new()
	area.collision_layer = 2
	area.collision_mask = 1
	area.monitoring = true
	area.monitorable = true
	area.set_meta("is_top", is_top)

	var collision_shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(gate_width, 1900.0)
	collision_shape.shape = rectangle
	area.add_child(collision_shape)
	add_child(area)

	area.body_entered.connect(_on_body_entered)
	_update_area_position(area)

func _process(delta: float) -> void:
	time_alive += delta
	if is_moving:
		gap_center = base_gap_center + sin(time_alive * move_speed + phase) * amplitude
	if gate_type == "pulse":
		gap_size = maxf(245.0, base_gap_size + sin(time_alive * pulse_speed + phase) * pulse_amount)
	for child in get_children():
		if child is Area2D:
			_update_area_position(child)
	queue_redraw()

func _update_area_position(area: Area2D) -> void:
	var is_top: bool = bool(area.get_meta("is_top", false))
	if is_top:
		area.position = Vector2(0.0, gap_center - gap_size * 0.5 - 950.0)
	else:
		area.position = Vector2(0.0, gap_center + gap_size * 0.5 + 950.0)

func _on_body_entered(_body: Node2D) -> void:
	collided.emit()

func get_center_y() -> float:
	return gap_center

func get_gap_size() -> float:
	return gap_size

func was_passed() -> bool:
	return passed

func mark_passed() -> void:
	passed = true

func _draw() -> void:
	var top_bottom: float = gap_center - gap_size * 0.5
	var bottom_top: float = gap_center + gap_size * 0.5
	var left: float = -gate_width * 0.5
	var primary := Color(tint.r, tint.g, tint.b, 0.74)
	var light := tint.lightened(0.30)
	var edge := Color(light.r, light.g, light.b, 0.98)
	var pulse: float = 0.5 + 0.5 * sin(time_alive * 4.0 + phase)
	var glow_alpha: float = 0.07 + pulse * 0.045

	if gate_type == "laser":
		primary = tint.darkened(0.28)
		edge = Color(light.r, light.g, light.b, 0.92)
	elif gate_type == "pulse":
		primary = tint.lightened(0.04)
	elif gate_type == "moving":
		primary = tint.darkened(0.06)

	draw_rect(Rect2(left - 14.0, -120.0, gate_width + 28.0, top_bottom + 120.0), Color(tint.r, tint.g, tint.b, glow_alpha))
	draw_rect(Rect2(left - 14.0, bottom_top, gate_width + 28.0, 2040.0 - bottom_top), Color(tint.r, tint.g, tint.b, glow_alpha))
	draw_rect(Rect2(left, -120.0, gate_width, top_bottom + 120.0), primary)
	draw_rect(Rect2(left, bottom_top, gate_width, 2040.0 - bottom_top), primary)
	draw_rect(Rect2(left - 7.0, top_bottom - 22.0, gate_width + 14.0, 22.0), edge)
	draw_rect(Rect2(left - 7.0, bottom_top, gate_width + 14.0, 22.0), edge)

	for stripe in range(3):
		var stripe_x: float = left + 22.0 + float(stripe) * maxf(22.0, (gate_width - 44.0) / 2.0)
		draw_line(Vector2(stripe_x, maxf(-80.0, top_bottom - 180.0)), Vector2(stripe_x, top_bottom - 34.0), Color(1.0, 1.0, 1.0, 0.08), 2.0)
		draw_line(Vector2(stripe_x, bottom_top + 34.0), Vector2(stripe_x, minf(2000.0, bottom_top + 180.0)), Color(1.0, 1.0, 1.0, 0.08), 2.0)

	if gate_type == "laser":
		var beam_alpha: float = 0.40 + pulse * 0.44
		draw_line(Vector2(left - 58.0, top_bottom), Vector2(-left + 58.0, top_bottom), Color(light.r, light.g, light.b, beam_alpha), 5.0, true)
		draw_line(Vector2(left - 58.0, bottom_top), Vector2(-left + 58.0, bottom_top), Color(light.r, light.g, light.b, beam_alpha), 5.0, true)
	elif gate_type == "moving":
		draw_line(Vector2(left - 28.0, gap_center), Vector2(left - 8.0, gap_center - 14.0), edge, 4.0)
		draw_line(Vector2(left - 28.0, gap_center), Vector2(left - 8.0, gap_center + 14.0), edge, 4.0)
	elif gate_type == "pulse":
		draw_circle(Vector2(0.0, top_bottom), 8.0 + pulse * 5.0, Color(edge.r, edge.g, edge.b, 0.65))
		draw_circle(Vector2(0.0, bottom_top), 8.0 + pulse * 5.0, Color(edge.r, edge.g, edge.b, 0.65))
