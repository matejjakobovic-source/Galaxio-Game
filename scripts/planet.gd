extends CharacterBody2D

const PLAYER_X := 220.0
const GRAVITY_STRENGTH := 2350.0
const MAX_VERTICAL_SPEED := 1450.0

var gravity_direction: float = 1.0
var active: bool = false
var shield_charges: int = 0
var skin_id: String = "terra"
var pulse: float = 0.0

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
	var collision_shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 42.0
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
	active = true
	visible = true
	queue_redraw()

func set_gravity(direction: float) -> void:
	if not active:
		return
	var normalized_direction := sign(direction)
	if normalized_direction == 0.0:
		return
	gravity_direction = normalized_direction
	velocity.y = velocity.y * 0.42 + gravity_direction * 155.0
	pulse = 1.0
	queue_redraw()

func toggle_gravity() -> void:
	set_gravity(-gravity_direction)

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
	if not active:
		return
	velocity.x = 0.0
	velocity.y += gravity_direction * GRAVITY_STRENGTH * delta
	velocity.y = clamp(velocity.y, -MAX_VERTICAL_SPEED, MAX_VERTICAL_SPEED)
	move_and_slide()
	global_position.x = PLAYER_X
	pulse = max(0.0, pulse - delta * 2.8)
	if pulse > 0.0:
		queue_redraw()

func _draw() -> void:
	var skin: Dictionary = SKINS.get(skin_id, SKINS["terra"])
	var base: Color = skin["base"]
	var accent: Color = skin["accent"]
	var glow_radius := 52.0 + pulse * 8.0

	draw_circle(Vector2.ZERO, glow_radius, Color(accent.r, accent.g, accent.b, 0.10 + pulse * 0.08))
	draw_circle(Vector2.ZERO, 42.0, base)
	draw_circle(Vector2(-13.0, -11.0), 13.0, Color(accent.r, accent.g, accent.b, 0.82))
	draw_circle(Vector2(15.0, 8.0), 9.0, Color(accent.r, accent.g, accent.b, 0.55))
	draw_arc(Vector2.ZERO, 34.0, -2.4, -0.5, 22, Color(1.0, 1.0, 1.0, 0.46), 4.0)

	if skin_id == "saturn":
		draw_arc(Vector2.ZERO, 58.0, -0.25, 3.0, 40, accent, 7.0)
		draw_arc(Vector2.ZERO, 58.0, 3.0, 6.0, 40, Color(accent.r, accent.g, accent.b, 0.42), 5.0)
	elif skin_id == "void":
		draw_circle(Vector2.ZERO, 19.0, Color("090816"))
		draw_arc(Vector2.ZERO, 27.0, 0.0, TAU, 42, accent, 5.0)
	elif skin_id == "sun":
		for i in range(12):
			var angle := TAU * float(i) / 12.0
			var ray := Vector2(cos(angle), sin(angle))
			draw_line(ray * 48.0, ray * 60.0, accent, 4.0)

	if shield_charges > 0:
		draw_arc(Vector2.ZERO, 59.0, 0.0, TAU, 64, Color("76f7ff"), 6.0)
		draw_arc(Vector2.ZERO, 66.0, -0.7, 1.3, 18, Color(1.0, 1.0, 1.0, 0.65), 3.0)
