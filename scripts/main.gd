extends Node

const PlanetScript = preload("res://scripts/planet.gd")
const GateScript = preload("res://scripts/gate.gd")
const PickupScript = preload("res://scripts/pickup.gd")
const StarfieldScript = preload("res://scripts/starfield.gd")
const LevelFactory = preload("res://scripts/level_factory.gd")
const HazardScript = preload("res://scripts/hazard.gd")
const AudioManagerScript = preload("res://scripts/audio_manager.gd")

const VIEWPORT_SIZE := Vector2(1080.0, 1920.0)
const PLAYER_START := Vector2(220.0, 960.0)
const TOP_LIMIT := 95.0
const BOTTOM_LIMIT := 1825.0

const THEME_COLORS := [
	Color("685cff"), Color("22c8ff"), Color("9a718f"), Color("ff7a45"),
	Color("3ce0d0"), Color("7a5bd9"), Color("d15cff"), Color("ff9f45")
]

const SKINS := {
	"terra": {"name": "Terra", "cost": 0},
	"mars": {"name": "Mars", "cost": 220},
	"neon": {"name": "Neon", "cost": 420},
	"saturn": {"name": "Saturn", "cost": 650},
	"void": {"name": "Void", "cost": 900},
	"sun": {"name": "Solar", "cost": 1250},
	"ice": {"name": "Ice", "cost": 1650},
	"toxic": {"name": "Toxic", "cost": 2200}
}

var state: String = "menu"
var mode: String = "level"
var current_level: int = 1
var level_data: Dictionary = {}
var world: Node2D = null
var player: CharacterBody2D = null
var ui: Control = null
var background: Node2D = null
var audio_manager: Node = null
var score_label: Label = null
var coin_label: Label = null
var combo_label: Label = null
var power_label: Label = null
var progress_label: Label = null
var score: float = 0.0
var run_coins: int = 0
var combo: int = 0
var best_combo: int = 0
var passed_gates: int = 0
var target_gates: int = 0
var world_speed: float = 360.0
var elapsed: float = 0.0
var magnet_time: float = 0.0
var slow_time: float = 0.0
var invulnerable_time: float = 0.0
var rush_time: float = 0.0
var endless_index: int = 0
var next_gate_x: float = 900.0
var daily_data: Dictionary = {}
var daily_progress: float = 0.0
var daily_seed: int = 44119
var current_zone_index: int = 0
var special_speed_multiplier: float = 1.0

func _ready() -> void:
	background = StarfieldScript.new()
	background.z_index = -50
	add_child(background)
	audio_manager = AudioManagerScript.new()
	add_child(audio_manager)
	var canvas := CanvasLayer.new()
	canvas.layer = 20
	add_child(canvas)
	ui = Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(ui)
	show_menu()

func _process(delta: float) -> void:
	if state != "game" or world == null or player == null:
		return
	elapsed += delta
	magnet_time = maxf(0.0, magnet_time - delta)
	slow_time = maxf(0.0, slow_time - delta)
	invulnerable_time = maxf(0.0, invulnerable_time - delta)
	rush_time = maxf(0.0, rush_time - delta)
	if mode != "level":
		world_speed = LevelFactory.endless_speed(passed_gates)
		var endless_zone: int = int(floor(float(passed_gates) / 12.0)) % 8
		if endless_zone != current_zone_index:
			current_zone_index = endless_zone
			if background != null:
				background.call("set_zone", current_zone_index)
	player.set_environment_gravity_multiplier(1.0)
	_apply_environment_hazards(delta)
	special_speed_multiplier = _environment_speed_multiplier()
	var slow_factor: float = 0.64 if slow_time > 0.0 else 1.0
	var rush_factor: float = 1.08 if rush_time > 0.0 else 1.0
	var actual_speed: float = world_speed * SaveData.speed_multiplier() * slow_factor * rush_factor * special_speed_multiplier
	player.set_visual_speed(actual_speed)
	world.position.x -= actual_speed * delta
	score += actual_speed * delta * (0.105 + float(combo) * 0.005)
	_check_gate_passes()
	_apply_magnet(delta)
	_cleanup_world()
	if mode != "level":
		while next_gate_x + world.position.x < 2800.0:
			_spawn_endless_segment()
	if player.global_position.y < TOP_LIMIT or player.global_position.y > BOTTOM_LIMIT:
		_handle_hit()
	if mode == "daily" and str(daily_data.get("type", "")) == "survive":
		daily_progress = elapsed
		_check_daily_completion()
	_update_hud()

func _unhandled_input(event: InputEvent) -> void:
	if state != "game" or player == null:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			_apply_touch_gravity(event.position.y)
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_apply_touch_gravity(event.position.y)
		return
	if event is InputEventKey:
		if not event.pressed or event.echo:
			return
		if event.keycode == KEY_W or event.keycode == KEY_UP:
			_set_gravity(-1.0)
		elif event.keycode == KEY_S or event.keycode == KEY_DOWN:
			_set_gravity(1.0)
		elif event.keycode == KEY_SPACE:
			player.toggle_gravity()
			_play_sfx("flip")
			_haptic(8)
		elif event.keycode == KEY_ESCAPE:
			_pause_game()

func _apply_touch_gravity(touch_y: float) -> void:
	var middle_y: float = get_viewport().get_visible_rect().size.y * 0.5
	_set_gravity(-1.0 if touch_y < middle_y else 1.0)

func _set_gravity(direction: float) -> void:
	if player != null:
		player.set_gravity(direction)
		_play_sfx("flip")
		_haptic(8)

func _play_sfx(name: String) -> void:
	if audio_manager != null and audio_manager.has_method("play_sfx"):
		audio_manager.call("play_sfx", name)

func _haptic(duration_ms: int) -> void:
	Input.vibrate_handheld(duration_ms)

func show_menu() -> void:
	state = "menu"
	current_zone_index = 0
	if background != null:
		background.call("set_zone", 0)
	_destroy_game()
	_clear_ui()
	_add_label("GRAVITY", Vector2(90, 165), Vector2(900, 150), 112, Color("f4f7ff"), HORIZONTAL_ALIGNMENT_CENTER)
	_add_label("MASTER THE PULL", Vector2(90, 320), Vector2(900, 55), 30, Color("77f8ff"), HORIZONTAL_ALIGNMENT_CENTER)
	var status_text: String = "◆ %d COINS   •   LEVEL %d/120   •   STREAK %d" % [SaveData.coins(), SaveData.unlocked_level(), SaveData.daily_streak()]
	_add_label(status_text, Vector2(80, 485), Vector2(920, 60), 23, Color("d6dcff"), HORIZONTAL_ALIGNMENT_CENTER)
	_add_button("CONTINUE  •  LEVEL %d" % SaveData.unlocked_level(), 650, _start_level.bind(SaveData.unlocked_level()), true)
	_add_button("LEVEL MAP", 785, show_levels)
	_add_button("∞  ENDLESS", 920, _start_endless)
	_add_button("DAILY CHALLENGE", 1055, show_daily)
	_add_button("SKINS & UPGRADES", 1190, show_shop)
	_add_button("LEADERBOARD", 1325, show_leaderboard)
	_add_label("Tap upper half = gravity ↑    •    lower half = gravity ↓", Vector2(70, 1580), Vector2(940, 65), 23, Color(0.75, 0.8, 1.0, 0.7), HORIZONTAL_ALIGNMENT_CENTER)

func show_levels() -> void:
	state = "menu"
	_clear_ui()
	_add_header("LEVEL MAP", "120 runs across 8 evolving space zones")
	_add_back_button(show_menu)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(90, 300)
	scroll.size = Vector2(900, 1430)
	ui.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 18)
	scroll.add_child(grid)
	var unlocked: int = SaveData.unlocked_level()
	for level_number in range(1, 121):
		var button := Button.new()
		button.custom_minimum_size = Vector2(205, 112)
		button.add_theme_font_size_override("font_size", 26)
		button.disabled = level_number > unlocked
		if button.disabled:
			button.text = "LOCKED"
		else:
			button.text = str(level_number)
			button.pressed.connect(_start_level.bind(level_number))
		_style_button(button, level_number == unlocked)
		grid.add_child(button)

func show_daily() -> void:
	state = "menu"
	_clear_ui()
	daily_data = _create_daily_data()
	var today: String = Time.get_date_string_from_system()
	var claimed: bool = SaveData.daily_is_claimed(today)
	_add_header("DAILY CHALLENGE", today)
	_add_back_button(show_menu)
	_add_label("TODAY'S MISSION", Vector2(100, 500), Vector2(880, 60), 25, Color("77f8ff"), HORIZONTAL_ALIGNMENT_CENTER)
	_add_label(str(daily_data["label"]), Vector2(100, 590), Vector2(880, 150), 42, Color("f4f6ff"), HORIZONTAL_ALIGNMENT_CENTER)
	_add_label("+%d BONUS COINS" % int(daily_data["reward"]), Vector2(100, 770), Vector2(880, 60), 28, Color("ffd85a"), HORIZONTAL_ALIGNMENT_CENTER)
	_add_label("Current streak: %d" % SaveData.daily_streak(), Vector2(100, 850), Vector2(880, 55), 24, Color("d1d7ff"), HORIZONTAL_ALIGNMENT_CENTER)
	if claimed:
		_add_label("COMPLETED TODAY ✓", Vector2(100, 930), Vector2(880, 55), 25, Color("72f1a8"), HORIZONTAL_ALIGNMENT_CENTER)
		_add_button("REPLAY DAILY", 1130, _start_daily, true)
	else:
		_add_button("START DAILY", 1130, _start_daily, true)

func show_shop() -> void:
	state = "menu"
	_clear_ui()
	_add_header("HANGAR", "Skins + Velocity Core")
	_add_back_button(show_menu)
	_add_label("◆ %d" % SaveData.coins(), Vector2(730, 210), Vector2(250, 55), 28, Color("ffd85a"), HORIZONTAL_ALIGNMENT_RIGHT)
	_add_label("VELOCITY CORE  %d/10" % SaveData.speed_upgrade(), Vector2(105, 340), Vector2(500, 55), 30, Color("f4f6ff"))
	_add_label("+1.8% speed and +5% coin yield / upgrade", Vector2(105, 400), Vector2(580, 45), 20, Color(0.7, 0.76, 1.0, 0.75))
	var upgrade_button := Button.new()
	upgrade_button.position = Vector2(700, 330)
	upgrade_button.size = Vector2(275, 110)
	upgrade_button.add_theme_font_size_override("font_size", 22)
	if SaveData.speed_upgrade() >= 10:
		upgrade_button.text = "MAXED"
		upgrade_button.disabled = true
	else:
		upgrade_button.text = "UPGRADE\n◆ %d" % SaveData.speed_upgrade_cost()
		upgrade_button.pressed.connect(_buy_speed_upgrade)
	_style_button(upgrade_button, true)
	ui.add_child(upgrade_button)
	var skin_ids: Array[String] = ["terra", "mars", "neon", "saturn", "void", "sun", "ice", "toxic"]
	var y: float = 520.0
	for skin_id in skin_ids:
		var skin_meta: Dictionary = SKINS[skin_id]
		_add_label(str(skin_meta["name"]).to_upper(), Vector2(115, y), Vector2(280, 80), 27, Color("f1f4ff"))
		var status: String = "◆ %d" % int(skin_meta["cost"])
		if SaveData.selected_skin() == skin_id:
			status = "EQUIPPED"
		elif SaveData.owns_skin(skin_id):
			status = "OWNED"
		_add_label(status, Vector2(390, y), Vector2(240, 80), 20, Color("77f8ff"), HORIZONTAL_ALIGNMENT_CENTER)
		var skin_button := Button.new()
		skin_button.position = Vector2(670, y + 5)
		skin_button.size = Vector2(280, 70)
		skin_button.text = "SELECT" if SaveData.owns_skin(skin_id) else "UNLOCK"
		skin_button.disabled = SaveData.selected_skin() == skin_id
		skin_button.pressed.connect(_skin_action.bind(skin_id))
		_style_button(skin_button, false)
		ui.add_child(skin_button)
		y += 135.0

func show_leaderboard() -> void:
	state = "menu"
	_clear_ui()
	_add_header("LEADERBOARD", "Local device top 10")
	_add_back_button(show_menu)
	var board: Array = SaveData.leaderboard()
	if board.is_empty():
		_add_label("No records yet.\nPlay Endless and set the first score.", Vector2(120, 650), Vector2(840, 180), 34, Color(0.8, 0.84, 1.0, 0.8), HORIZONTAL_ALIGNMENT_CENTER)
		return
	var y: float = 340.0
	for index in range(board.size()):
		var entry: Dictionary = board[index]
		_add_label("#%d   %s" % [index + 1, str(entry.get("mode", "run")).to_upper()], Vector2(110, y), Vector2(430, 70), 25, Color("d6dcff"))
		_add_label("%07d" % int(entry.get("score", 0)), Vector2(540, y), Vector2(420, 70), 30, Color("ffffff"), HORIZONTAL_ALIGNMENT_RIGHT)
		y += 115.0

func _start_level(level_number: int) -> void:
	mode = "level"
	current_level = clampi(level_number, 1, 120)
	level_data = LevelFactory.build_level(current_level)
	current_zone_index = int(level_data.get("zone", 0))
	if background != null:
		background.call("set_zone", current_zone_index)
	_begin_run()
	world_speed = float(level_data["speed"])
	var segments: Array = level_data["segments"]
	target_gates = segments.size()
	for index in range(segments.size()):
		var segment: Dictionary = segments[index]
		_spawn_segment(segment, index)
	_build_hud()

func _start_endless() -> void:
	mode = "endless"
	current_level = 0
	daily_seed = 44119
	current_zone_index = 0
	if background != null:
		background.call("set_zone", current_zone_index)
	_begin_run()
	for _i in range(8):
		_spawn_endless_segment()
	_build_hud()

func _start_daily() -> void:
	mode = "daily"
	current_level = 0
	daily_data = _create_daily_data()
	daily_seed = absi(Time.get_date_string_from_system().hash()) + 7727
	current_zone_index = daily_seed % 8
	if background != null:
		background.call("set_zone", current_zone_index)
	_begin_run()
	for _i in range(8):
		_spawn_endless_segment()
	_build_hud()

func _begin_run() -> void:
	_play_sfx("button")
	_destroy_game()
	_clear_ui()
	state = "game"
	score = 0.0
	run_coins = 0
	combo = 0
	best_combo = 0
	passed_gates = 0
	target_gates = 0
	elapsed = 0.0
	magnet_time = 0.0
	slow_time = 0.0
	invulnerable_time = 0.0
	rush_time = 0.0
	endless_index = 0
	next_gate_x = 900.0
	daily_progress = 0.0
	world = Node2D.new()
	world.name = "World"
	add_child(world)
	player = PlanetScript.new()
	player.name = "Player"
	add_child(player)
	player.reset_player(PLAYER_START, SaveData.selected_skin())

func _spawn_segment(config: Dictionary, _segment_index: int) -> void:
	if world == null:
		return
	var zone_index: int = int(config.get("zone", current_zone_index))
	var theme_index: int = clampi(zone_index, 0, THEME_COLORS.size() - 1)
	var gate := GateScript.new()
	world.add_child(gate)
	gate.setup(config, THEME_COLORS[theme_index])
	gate.collided.connect(_handle_hit)

	var coin_count: int = int(config.get("coin_arc", 3))
	var gate_x: float = float(config.get("x", 0.0))
	var gate_y: float = float(config.get("gap_y", 960.0))
	var gap_size: float = float(config.get("gap", 460.0))
	var coin_pattern: String = str(config.get("coin_pattern", "wave"))
	var coin_risk: float = float(config.get("coin_risk", 0.55))
	for coin_index in range(coin_count):
		var coin_position: Vector2 = _coin_position(gate_x, gate_y, gap_size, coin_pattern, coin_risk, coin_index, coin_count)
		_spawn_pickup("coin", coin_position)

	var powerup: String = str(config.get("powerup", ""))
	if not powerup.is_empty():
		_spawn_pickup(powerup, Vector2(gate_x + 225.0, gate_y))

	var special: String = str(config.get("special", ""))
	if not special.is_empty():
		_spawn_hazard(config, THEME_COLORS[theme_index])

func _coin_position(gate_x: float, gate_y: float, gap_size: float, pattern: String, risk: float, coin_index: int, coin_count: int) -> Vector2:
	var centered_index: float = float(coin_index) - float(coin_count - 1) * 0.5
	var x: float = gate_x - 225.0 + centered_index * 68.0
	var max_offset: float = maxf(40.0, gap_size * 0.5 - 72.0)
	var risky_offset: float = max_offset * clampf(risk, 0.0, 1.0)
	var y: float = gate_y
	match pattern:
		"upper":
			y = gate_y - risky_offset + sin(float(coin_index) * 1.4) * 20.0
		"lower":
			y = gate_y + risky_offset + sin(float(coin_index) * 1.4) * 20.0
		"zigzag":
			y = gate_y + (-risky_offset if coin_index % 2 == 0 else risky_offset)
		"edge":
			var side: float = -1.0 if int(floor(float(coin_index) / 2.0)) % 2 == 0 else 1.0
			y = gate_y + side * risky_offset
		_:
			y = gate_y + sin(float(coin_index) * 1.55 - 0.6) * risky_offset
	return Vector2(x, clampf(y, 150.0, 1770.0))

func _spawn_hazard(config: Dictionary, hazard_tint: Color) -> void:
	if world == null:
		return
	var hazard := HazardScript.new()
	world.add_child(hazard)
	hazard.setup(config, hazard_tint)
	hazard.collided.connect(_handle_hit)

func _spawn_endless_segment() -> void:
	var config: Dictionary = LevelFactory.build_endless_segment(endless_index, daily_seed)
	config["x"] = next_gate_x
	_spawn_segment(config, endless_index)
	next_gate_x += LevelFactory.BASE_SPACING + minf(90.0, float(endless_index) * 0.7)
	endless_index += 1

func _spawn_pickup(kind: String, pickup_position: Vector2) -> void:
	if world == null:
		return
	var pickup := PickupScript.new()
	pickup.position = pickup_position
	world.add_child(pickup)
	pickup.setup(kind)
	pickup.collected.connect(_on_pickup_collected)

func _apply_environment_hazards(delta: float) -> void:
	if world == null or player == null:
		return
	for child in world.get_children():
		if str(child.get_meta("entity_type", "")) == "hazard" and child.has_method("apply_to_player"):
			child.apply_to_player(player, delta)

func _environment_speed_multiplier() -> float:
	if world == null or player == null:
		return 1.0
	var multiplier: float = 1.0
	for child in world.get_children():
		if str(child.get_meta("entity_type", "")) == "hazard" and child.has_method("speed_multiplier_for"):
			multiplier = maxf(multiplier, float(child.speed_multiplier_for(player.global_position)))
	return multiplier

func _check_gate_passes() -> void:
	if world == null or player == null:
		return
	for child in world.get_children():
		if str(child.get_meta("entity_type", "")) != "gate" or child.was_passed() or child.global_position.x > player.global_position.x:
			continue
		child.mark_passed()
		passed_gates += 1
		var distance_to_center: float = absf(player.global_position.y - float(child.get_center_y()))
		var perfect: bool = distance_to_center <= float(child.get_gap_size()) * 0.17
		_on_gate_passed(perfect)
	if mode == "level" and target_gates > 0 and passed_gates >= target_gates:
		_finish_run(true, "LEVEL CLEARED")

func _on_gate_passed(perfect: bool) -> void:
	if perfect:
		combo += 1
		_play_sfx("perfect")
		if player != null:
			player.trigger_perfect_visual()
		best_combo = maxi(best_combo, combo)
		score += 120.0 * (1.0 + float(combo) * 0.18)
		_haptic(14)
		if combo > 0 and combo % 5 == 0:
			rush_time = 4.0
			_play_sfx("rush")
			score += 500.0
			run_coins += 2
	else:
		combo = 0
		score += 45.0
	if mode == "daily" and str(daily_data.get("type", "")) == "combo":
		daily_progress = float(best_combo)
		_check_daily_completion()

func _handle_hit() -> void:
	if state != "game" or player == null or invulnerable_time > 0.0:
		return
	if player.consume_shield():
		_play_sfx("shield")
		invulnerable_time = 1.0
		combo = 0
		score = maxf(0.0, score - 180.0)
		player.velocity.y *= -0.32
		player.global_position.y = clampf(player.global_position.y, 150.0, 1770.0)
		_haptic(65)
		return
	_play_sfx("hit")
	_haptic(140)
	_finish_run(false, "GRAVITY LOST")

func _on_pickup_collected(kind: String, amount: int) -> void:
	if kind == "coin":
		_play_sfx("coin")
		var gained: int = maxi(1, roundi(float(amount) * SaveData.coin_multiplier()))
		run_coins += gained
		score += 35.0 * float(gained)
		if mode == "daily" and str(daily_data.get("type", "")) == "coins":
			daily_progress += float(gained)
			_check_daily_completion()
	elif kind == "magnet":
		_play_sfx("power")
		magnet_time = maxf(magnet_time, 7.5)
	elif kind == "shield" and player != null:
		_play_sfx("shield")
		player.add_shield()
	elif kind == "slow":
		_play_sfx("power")
		slow_time = maxf(slow_time, 6.0)
	_haptic(10)

func _apply_magnet(delta: float) -> void:
	if magnet_time <= 0.0 or world == null or player == null:
		return
	for child in world.get_children():
		if str(child.get_meta("entity_type", "")) == "pickup" and child.get_pickup_kind() == "coin" and child.global_position.distance_to(player.global_position) < 390.0:
			child.pull_toward(player.global_position, 980.0, delta)

func _cleanup_world() -> void:
	if world == null:
		return
	for child in world.get_children():
		if child is Node2D and child.global_position.x < -320.0:
			child.queue_free()

func _finish_run(success: bool, title: String) -> void:
	if state != "game":
		return
	state = "result"
	if success:
		_play_sfx("win")
	if player != null:
		player.active = false
	if world != null:
		world.process_mode = Node.PROCESS_MODE_DISABLED
	var earned: int = run_coins
	var bonus: int = 0
	if mode == "level" and success:
		bonus = int(level_data.get("reward", 0))
		earned += bonus
		SaveData.unlock_level(mini(120, current_level + 1))
	SaveData.add_coins(earned)
	if mode == "daily" and success:
		var daily_reward: int = int(daily_data.get("reward", 0))
		if SaveData.claim_daily(Time.get_date_string_from_system(), daily_reward):
			bonus += daily_reward
	var score_mode: String = mode
	if mode == "level":
		score_mode = "level %d" % current_level
	SaveData.record_score(score_mode, int(score))
	_clear_ui()
	var title_color: Color = Color("72f1a8") if success else Color("ff728e")
	_add_label(title, Vector2(100, 380), Vector2(880, 100), 58, title_color, HORIZONTAL_ALIGNMENT_CENTER)
	_add_label("%07d" % int(score), Vector2(100, 515), Vector2(880, 90), 52, Color("ffffff"), HORIZONTAL_ALIGNMENT_CENTER)
	_add_label("◆ %d RUN   +   ◆ %d BONUS" % [run_coins, bonus], Vector2(100, 680), Vector2(880, 60), 27, Color("ffd85a"), HORIZONTAL_ALIGNMENT_CENTER)
	_add_label("BEST PERFECT COMBO  x%d" % best_combo, Vector2(100, 760), Vector2(880, 55), 23, Color("77f8ff"), HORIZONTAL_ALIGNMENT_CENTER)
	if mode == "level" and success and current_level < 120:
		_add_button("NEXT LEVEL", 980, _start_level.bind(current_level + 1), true)
	elif mode == "level":
		_add_button("RETRY", 980, _start_level.bind(current_level), true)
	elif mode == "daily":
		_add_button("REPLAY DAILY", 980, _start_daily, true)
	else:
		_add_button("RETRY ENDLESS", 980, _start_endless, true)
	_add_button("HOME", 1120, show_menu)

func _pause_game() -> void:
	if state != "game":
		return
	state = "paused"
	if player != null:
		player.active = false
	if world != null:
		world.process_mode = Node.PROCESS_MODE_DISABLED
	_clear_ui()
	_add_label("PAUSED", Vector2(100, 500), Vector2(880, 100), 62, Color("ffffff"), HORIZONTAL_ALIGNMENT_CENTER)
	_add_button("RESUME", 760, _resume_game, true)
	_add_button("HOME", 900, show_menu)

func _resume_game() -> void:
	if state != "paused":
		return
	state = "game"
	if player != null:
		player.active = true
	if world != null:
		world.process_mode = Node.PROCESS_MODE_INHERIT
	_build_hud()

func _create_daily_data() -> Dictionary:
	var hash_value: int = absi(Time.get_date_string_from_system().hash())
	var challenge_type: int = hash_value % 3
	if challenge_type == 0:
		var coin_target: int = 24 + hash_value % 13
		return {"type": "coins", "target": coin_target, "reward": 180 + hash_value % 80, "label": "Collect %d coins in one run" % coin_target}
	if challenge_type == 1:
		var combo_target: int = 5 + hash_value % 5
		return {"type": "combo", "target": combo_target, "reward": 200 + hash_value % 90, "label": "Reach a Perfect combo of x%d" % combo_target}
	var survival_target: int = 45 + hash_value % 31
	return {"type": "survive", "target": survival_target, "reward": 210 + hash_value % 90, "label": "Survive for %d seconds" % survival_target}

func _check_daily_completion() -> void:
	if state == "game" and mode == "daily" and daily_progress >= float(daily_data.get("target", 1)):
		score += 1200.0
		_finish_run(true, "DAILY COMPLETE")

func _build_hud() -> void:
	_clear_ui()
	score_label = _add_label("0000000", Vector2(390, 50), Vector2(300, 60), 30, Color("ffffff"), HORIZONTAL_ALIGNMENT_CENTER)
	coin_label = _add_label("◆ 0", Vector2(55, 52), Vector2(250, 55), 25, Color("ffd85a"))
	combo_label = _add_label("", Vector2(720, 130), Vector2(300, 48), 22, Color("77f8ff"), HORIZONTAL_ALIGNMENT_RIGHT)
	power_label = _add_label("", Vector2(45, 130), Vector2(650, 48), 20, Color("d9b0ff"))
	progress_label = _add_label("", Vector2(220, 1760), Vector2(640, 55), 21, Color(0.82, 0.86, 1.0, 0.75), HORIZONTAL_ALIGNMENT_CENTER)
	var pause_button := Button.new()
	pause_button.position = Vector2(918, 45)
	pause_button.size = Vector2(110, 72)
	pause_button.text = "Ⅱ"
	_style_button(pause_button, false)
	pause_button.pressed.connect(_pause_game)
	ui.add_child(pause_button)
	_update_hud()

func _update_hud() -> void:
	if score_label == null or not is_instance_valid(score_label):
		return
	score_label.text = "%07d" % int(score)
	coin_label.text = "◆ %d" % run_coins
	combo_label.text = "PERFECT x%d" % combo if combo > 1 else ""
	var powers: Array[String] = []
	if player != null and player.shield_charges > 0:
		powers.append("SHIELD")
	if magnet_time > 0.0:
		powers.append("MAGNET %.1f" % magnet_time)
	if slow_time > 0.0:
		powers.append("SLOW %.1f" % slow_time)
	if rush_time > 0.0:
		powers.append("RUSH %.1f" % rush_time)
	power_label.text = "  •  ".join(powers)
	if mode == "level":
		var zone_label: String = str(level_data.get("zone_name", LevelFactory.zone_name(current_zone_index)))
		var challenge_label: String = str(level_data.get("challenge_name", zone_label))
		progress_label.text = "%s • LEVEL %d   %d / %d" % [challenge_label, current_level, passed_gates, target_gates]
	elif mode == "daily":
		progress_label.text = "DAILY • %s   %.0f / %.0f" % [str(daily_data.get("type", "")).to_upper(), daily_progress, float(daily_data.get("target", 1))]
	else:
		progress_label.text = "ENDLESS   %d GATES   %.1fs" % [passed_gates, elapsed]

func _buy_speed_upgrade() -> void:
	_play_sfx("button")
	SaveData.buy_speed_upgrade()
	show_shop()

func _skin_action(skin_id: String) -> void:
	_play_sfx("button")
	if SaveData.owns_skin(skin_id):
		SaveData.select_skin(skin_id)
	else:
		var skin_meta: Dictionary = SKINS[skin_id]
		SaveData.buy_skin(skin_id, int(skin_meta["cost"]))
	show_shop()

func _destroy_game() -> void:
	if player != null and is_instance_valid(player):
		player.queue_free()
	if world != null and is_instance_valid(world):
		world.queue_free()
	player = null
	world = null

func _clear_ui() -> void:
	if ui == null:
		return
	for child in ui.get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
			child.visible = false
		child.queue_free()
	score_label = null
	coin_label = null
	combo_label = null
	power_label = null
	progress_label = null

func _add_header(title: String, subtitle: String) -> void:
	_add_label(title, Vector2(90, 105), Vector2(900, 90), 54, Color("f4f7ff"), HORIZONTAL_ALIGNMENT_CENTER)
	_add_label(subtitle, Vector2(90, 200), Vector2(900, 50), 22, Color(0.68, 0.74, 0.95, 0.75), HORIZONTAL_ALIGNMENT_CENTER)

func _add_back_button(callback: Callable) -> void:
	var button := Button.new()
	button.position = Vector2(55, 55)
	button.size = Vector2(190, 74)
	button.text = "‹ BACK"
	_style_button(button, false)
	button.pressed.connect(callback)
	ui.add_child(button)

func _add_label(text: String, position_value: Vector2, size_value: Vector2, font_size: int, color: Color, alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.text = text
	label.position = position_value
	label.size = size_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ui.add_child(label)
	return label

func _add_button(text: String, y: float, callback: Callable, primary: bool = false) -> Button:
	var button := Button.new()
	button.position = Vector2(135, y)
	button.size = Vector2(810, 105)
	button.text = text
	button.add_theme_font_size_override("font_size", 27)
	_style_button(button, primary)
	button.pressed.connect(callback)
	ui.add_child(button)
	return button

func _style_button(button: Button, primary: bool) -> void:
	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = Color("4e50db") if primary else Color(0.07, 0.09, 0.22, 0.96)
	normal_style.border_color = Color("777cff") if primary else Color(0.55, 0.65, 1.0, 0.2)
	normal_style.corner_radius_top_left = 24
	normal_style.corner_radius_top_right = 24
	normal_style.corner_radius_bottom_left = 24
	normal_style.corner_radius_bottom_right = 24
	normal_style.border_width_left = 1
	normal_style.border_width_top = 1
	normal_style.border_width_right = 1
	normal_style.border_width_bottom = 1
	button.add_theme_stylebox_override("normal", normal_style)
	var hover_style: StyleBoxFlat = normal_style.duplicate()
	hover_style.bg_color = normal_style.bg_color.lightened(0.1)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", hover_style)
	button.add_theme_color_override("font_color", Color("f5f6ff"))
	button.focus_mode = Control.FOCUS_NONE
