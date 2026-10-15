extends SceneTree

const LevelFactory = preload("res://scripts/level_factory.gd")

func _initialize() -> void:
	call_deferred("_run_tests")

func _fail(message: String) -> void:
	printerr("TEST_FAILURE: " + message)
	quit(1)

func _count_entity_type(world: Node, entity_type: String) -> int:
	var count: int = 0
	for child in world.get_children():
		if str(child.get_meta("entity_type", "")) == entity_type:
			count += 1
	return count

func _validate_level_factory() -> bool:
	if LevelFactory.zone_index_for_level(1) != 0 or LevelFactory.zone_index_for_level(16) != 1 or LevelFactory.zone_index_for_level(120) != 7:
		_fail("Zone progression is incorrect")
		return false
	var boss_levels := [20, 40, 60, 80, 100, 120]
	for level_number in boss_levels:
		var data: Dictionary = LevelFactory.build_level(level_number)
		if not bool(data.get("signature", false)):
			_fail("Signature flag missing for level %d" % level_number)
			return false
		if not bool(data.get("boss", false)):
			_fail("Boss/challenge flag missing for level %d" % level_number)
			return false
		var segments: Array = data.get("segments", [])
		if segments.is_empty():
			_fail("No segments generated for level %d" % level_number)
			return false
		var specials: int = 0
		for segment_variant in segments:
			var segment: Dictionary = segment_variant
			if not str(segment.get("special", "")).is_empty():
				specials += 1
			var coin_count: int = int(segment.get("coin_arc", 0))
			if coin_count < 2 or coin_count > 4:
				_fail("Coin route count outside intended range")
				return false
		if specials <= 0:
			_fail("Challenge level %d contains no special mechanics" % level_number)
			return false
	return true

func _run_tests() -> void:
	if not _validate_level_factory():
		return

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
	game._start_level(40)
	await process_frame
	await physics_frame
	if game.current_zone_index != 2:
		_fail("Level 40 did not enter Asteroid Belt zone")
		return
	if _count_entity_type(game.world, "hazard") <= 0:
		_fail("Level 40 did not spawn special hazards")
		return
	for _i in range(4):
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
