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
		circle.radius = 30.0
	else:
		circle.radius = 38.0
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
		rotation += delta * 1.8
	else:
		position.y = base_y + sin(bob_time * 3.0) * 9.0
		rotation = sin(bob_time * 2.0) * 0.08

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
		draw_circle(Vector2.ZERO, 29.0, Color("ffd84a"))
		draw_circle(Vector2.ZERO, 22.0, Color("f5a623"))
		draw_circle(Vector2.ZERO, 15.0, Color("ffd84a"))
		draw_string(ThemeDB.fallback_font, Vector2(-10.0, 9.0), "G", HORIZONTAL_ALIGNMENT_CENTER, 20.0, 24, Color("5f3c00"))
		return

	var color := Color("6effe8")
	var symbol := "M"
	if kind == "shield":
		color = Color("77a7ff")
		symbol = "S"
	elif kind == "slow":
		color = Color("d98cff")
		symbol = "T"

	draw_circle(Vector2.ZERO, 43.0, Color(color.r, color.g, color.b, 0.16))
	draw_circle(Vector2.ZERO, 35.0, color)
	draw_circle(Vector2.ZERO, 27.0, Color("10132f"))
	draw_string(ThemeDB.fallback_font, Vector2(-12.0, 10.0), symbol, HORIZONTAL_ALIGNMENT_CENTER, 24.0, 28, color)
