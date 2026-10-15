extends Area2D

signal collected(kind: String, amount: int)

var kind: String = "coin"
var amount: int = 1
var bob_time: float = 0.0
var base_y: float = 0.0
var already_collected: bool = false

func setup(new_kind: String, new_amount: int = 1) -> void:
	kind = new_kind
	amount = new_amount
	set_meta("entity_type", "pickup")

	collision_layer = 4
	collision_mask = 1
	monitoring = true
	monitorable = true

	var collision_shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	if kind == "coin":
		circle.radius = 22.0
	else:
		circle.radius = 36.0
	collision_shape.shape = circle
	add_child(collision_shape)
	body_entered.connect(_on_body_entered)
	base_y = position.y
	queue_redraw()

func _process(delta: float) -> void:
	if already_collected:
		return
	bob_time += delta
	if kind == "coin":
		rotation += delta * 2.25
		position.y = base_y + sin(bob_time * 4.0) * 3.5
	else:
		position.y = base_y + sin(bob_time * 3.0) * 9.0
		rotation = sin(bob_time * 2.0) * 0.08
	queue_redraw()

func pull_toward(target_global_position: Vector2, pull_speed: float, delta: float) -> void:
	if already_collected or kind != "coin":
		return
	global_position = global_position.move_toward(target_global_position, pull_speed * delta)

func get_pickup_kind() -> String:
	return kind

func _on_body_entered(_body: Node2D) -> void:
	if already_collected:
		return
	already_collected = true
	monitoring = false
	collected.emit(kind, amount)
	queue_free()

func _draw() -> void:
	if kind == "coin":
		_draw_coin()
		return

	var color := Color("6effe8")
	var symbol := "M"
	if kind == "shield":
		color = Color("77a7ff")
		symbol = "S"
	elif kind == "slow":
		color = Color("d98cff")
		symbol = "T"

	var pulse: float = 0.5 + 0.5 * sin(bob_time * 4.0)
	draw_circle(Vector2.ZERO, 48.0 + pulse * 4.0, Color(color.r, color.g, color.b, 0.08 + pulse * 0.05))
	draw_circle(Vector2.ZERO, 37.0, color.darkened(0.18))
	draw_arc(Vector2.ZERO, 34.0, 0.0, TAU, 36, color.lightened(0.22), 4.0)
	draw_circle(Vector2.ZERO, 26.0, Color("10132f"))
	draw_arc(Vector2.ZERO, 20.0, -1.7, 0.3, 18, Color(1.0, 1.0, 1.0, 0.28), 3.0)
	draw_string(ThemeDB.fallback_font, Vector2(-12.0, 10.0), symbol, HORIZONTAL_ALIGNMENT_CENTER, 24.0, 28, color)

func _draw_coin() -> void:
	var shimmer: float = 0.5 + 0.5 * sin(bob_time * 7.0)
	var gold := Color("ffc83f")
	var bright := Color("fff1a6")
	var dark := Color("9a5d00")
	draw_circle(Vector2.ZERO, 34.0 + shimmer * 3.0, Color(gold.r, gold.g, gold.b, 0.08 + shimmer * 0.05))
	draw_circle(Vector2.ZERO, 26.0, dark)
	draw_circle(Vector2.ZERO, 23.0, gold)
	draw_arc(Vector2.ZERO, 20.0, 0.0, TAU, 32, bright, 3.0)
	draw_circle(Vector2(-7.0, -8.0), 6.0, Color(1.0, 1.0, 1.0, 0.24 + shimmer * 0.18))
	draw_string(ThemeDB.fallback_font, Vector2(-9.0, 8.0), "G", HORIZONTAL_ALIGNMENT_CENTER, 18.0, 22, dark)
	var flare_alpha: float = 0.18 + shimmer * 0.35
	draw_line(Vector2(26.0, -15.0), Vector2(37.0, -15.0), Color(1.0, 0.95, 0.65, flare_alpha), 2.0)
	draw_line(Vector2(31.5, -20.5), Vector2(31.5, -9.5), Color(1.0, 0.95, 0.65, flare_alpha), 2.0)
