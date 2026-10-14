extends SceneTree

func _initialize() -> void:
	call_deferred("_run_tests")

func _fail(message: String) -> void:
	printerr("TEST_FAILURE: " + message)
	quit(1)

func _run_tests() -> void:
	var packed_scene: PackedScene = load("res://scenes/main.tscn")
	if packed_scene == null:
		_fail("Could not load main scene")
		return

	var game: Node = packed_scene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame

	if game.state != "menu":
		_fail("Game did not enter menu state")
		return

	game._start_level(1)
	await process_frame
	await physics_frame
	if game.state != "game":
		_fail("Level 1 did not start")
		return
	if game.player == null or game.world == null:
		_fail("Level 1 did not create player/world")
		return
	if game.target_gates <= 0:
		_fail("Level 1 did not create gates")
		return
	game._set_gravity(-1.0)
	for _i in range(8):
		await physics_frame

	game.show_menu()
	await process_frame
	game._start_endless()
	await process_frame
	await physics_frame
	if game.state != "game" or game.mode != "endless":
		_fail("Endless mode did not start")
		return
	if game.world.get_child_count() == 0:
		_fail("Endless mode spawned no world objects")
		return
	for _i in range(5):
		await physics_frame

	game.show_menu()
	await process_frame
	game._start_daily()
	await process_frame
	await physics_frame
	if game.state != "game" or game.mode != "daily":
		_fail("Daily mode did not start")
		return
	if game.daily_data.is_empty():
		_fail("Daily challenge data was not generated")
		return
	for _i in range(5):
		await physics_frame

	print("RUNTIME_SMOKE_OK")
	quit(0)
