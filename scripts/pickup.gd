class_name GravityPickup
extends Area2D

signal collected(kind: String, amount: int)

var kind := "coin"
var amount := 1
var bob_time := 0.0
var base_y := 0.0
var collected_flag := false

func setup(new_kind: String, new_amount: int = 1) -> void:
    kind = new_kind
    amount = new_amount
    collision_layer = 4
    collision_mask = 1
    monitoring = true
    monitorable = true
    var collision := CollisionShape2D.new()
    var circle := CircleShape2D.new()
    circle.radius = 30.0 if kind == "coin" else 38.0
    collision.shape = circle
    add_child(collision)
    body_entered.connect(_on_body_entered)
    base_y = position.y
    queue_redraw()

func _process(delta: float) -> void:
    if collected_flag:
        return
    bob_time += delta
    if kind != "coin":
        position.y = base_y + sin(bob_time * 3.0) * 9.0
        rotation = sin(bob_time * 2.0) * 0.08
    else:
        rotation += delta * 1.8

func pull_toward(target_global: Vector2, speed: float, delta: float) -> void:
    if collected_flag or kind != "coin":
        return
    global_position = global_position.move_toward(target_global, speed * delta)

func _on_body_entered(_body: Node) -> void:
    if collected_flag:
        return
    collected_flag = true
    monitoring = false
    collected.emit(kind, amount)
    queue_free()

func _draw() -> void:
    if kind == "coin":
        draw_circle(Vector2.ZERO, 29.0, Color("ffd84a"))
        draw_circle(Vector2.ZERO, 22.0, Color("f5a623"))
        draw_circle(Vector2.ZERO, 15.0, Color("ffd84a"))
        draw_string(ThemeDB.fallback_font, Vector2(-10.0, 9.0), "G", HORIZONTAL_ALIGNMENT_CENTER, 20.0, 24, Color("5f3c00"))
    else:
        var col := Color("6effe8")
        var symbol := "M"
        if kind == "shield":
            col = Color("77a7ff")
            symbol = "S"
        elif kind == "slow":
            col = Color("d98cff")
            symbol = "T"
        draw_circle(Vector2.ZERO, 43.0, Color(col, 0.16))
        draw_circle(Vector2.ZERO, 35.0, col)
        draw_circle(Vector2.ZERO, 27.0, Color("10132f"))
        draw_string(ThemeDB.fallback_font, Vector2(-12.0, 10.0), symbol, HORIZONTAL_ALIGNMENT_CENTER, 24.0, 28, col)
