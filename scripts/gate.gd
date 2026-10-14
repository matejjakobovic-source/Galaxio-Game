class_name GravityGate
extends Node2D

signal collided

var gap_center := 960.0
var gap_size := 460.0
var gate_width := 140.0
var moving := false
var amplitude := 0.0
var move_speed := 1.0
var phase := 0.0
var base_gap_center := 960.0
var passed := false
var time_alive := 0.0
var tint := Color("6c63ff")

func setup(config: Dictionary, gate_tint: Color) -> void:
    position.x = float(config.get("x", 0.0))
    gap_center = float(config.get("gap_y", 960.0))
    base_gap_center = gap_center
    gap_size = float(config.get("gap", 460.0))
    gate_width = float(config.get("width", 140.0))
    moving = bool(config.get("moving", false))
    amplitude = float(config.get("amplitude", 0.0))
    move_speed = float(config.get("move_speed", 1.0))
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
    var collision := CollisionShape2D.new()
    var rect := RectangleShape2D.new()
    rect.size = Vector2(gate_width, 1900.0)
    collision.shape = rect
    area.add_child(collision)
    area.set_meta("is_top", is_top)
    add_child(area)
    area.body_entered.connect(_on_body_entered)
    _update_area_position(area)

func _process(delta: float) -> void:
    time_alive += delta
    if moving:
        gap_center = base_gap_center + sin(time_alive * move_speed + phase) * amplitude
        for child in get_children():
            if child is Area2D:
                _update_area_position(child)
        queue_redraw()

func _update_area_position(area: Area2D) -> void:
    var is_top := bool(area.get_meta("is_top", false))
    if is_top:
        area.position = Vector2(0.0, gap_center - gap_size * 0.5 - 950.0)
    else:
        area.position = Vector2(0.0, gap_center + gap_size * 0.5 + 950.0)

func _on_body_entered(_body: Node) -> void:
    collided.emit()

func center_y() -> float:
    return gap_center

func _draw() -> void:
    var top_bottom := gap_center - gap_size * 0.5
    var bottom_top := gap_center + gap_size * 0.5
    var left := -gate_width * 0.5
    var c1 := Color(tint, 0.78)
    var c2 := Color(tint.lightened(0.28), 0.96)
    draw_rect(Rect2(left, -120.0, gate_width, top_bottom + 120.0), c1)
    draw_rect(Rect2(left, bottom_top, gate_width, 2040.0 - bottom_top), c1)
    draw_rect(Rect2(left - 7.0, top_bottom - 22.0, gate_width + 14.0, 22.0), c2)
    draw_rect(Rect2(left - 7.0, bottom_top, gate_width + 14.0, 22.0), c2)
    draw_line(Vector2(left, top_bottom - 40.0), Vector2(left + gate_width, top_bottom - 40.0), Color(c2, 0.22), 3.0)
    draw_line(Vector2(left, bottom_top + 40.0), Vector2(left + gate_width, bottom_top + 40.0), Color(c2, 0.22), 3.0)
