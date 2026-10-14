class_name GravityStarfield
extends Node2D

var stars: Array[Dictionary] = []
var drift := 0.0

func _ready() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = 728319
    for i in range(95):
        stars.append({
            "p": Vector2(rng.randf_range(0.0, 1080.0), rng.randf_range(0.0, 1920.0)),
            "r": rng.randf_range(1.0, 3.6),
            "a": rng.randf_range(0.25, 0.9),
            "s": rng.randf_range(5.0, 18.0)
        })
    queue_redraw()

func _process(delta: float) -> void:
    drift += delta
    for star in stars:
        var p: Vector2 = star["p"]
        p.x -= float(star["s"]) * delta
        if p.x < -8.0:
            p.x = 1088.0
        star["p"] = p
    queue_redraw()

func _draw() -> void:
    draw_rect(Rect2(0.0, 0.0, 1080.0, 1920.0), Color("07091b"))
    draw_circle(Vector2(850.0, 360.0), 330.0, Color(0.22, 0.08, 0.38, 0.12))
    draw_circle(Vector2(160.0, 1500.0), 420.0, Color(0.02, 0.34, 0.42, 0.10))
    for star in stars:
        var twinkle := 0.75 + sin(drift * 2.0 + float(star["p"].x) * 0.02) * 0.2
        draw_circle(star["p"], float(star["r"]), Color(0.86, 0.93, 1.0, float(star["a"]) * twinkle))
