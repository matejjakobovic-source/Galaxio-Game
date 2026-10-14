extends Node

const SCREEN := Vector2(1080.0, 1920.0)
const START := Vector2(220.0, 960.0)
const THEMES := [Color("685cff"), Color("22c8ff"), Color("ff5f8f"), Color("8f68ff"), Color("3ce0a3"), Color("ff9f45")]
const SKINS := {
    "terra": {"name":"Terra", "cost":0}, "mars": {"name":"Mars", "cost":220},
    "neon": {"name":"Neon", "cost":420}, "saturn": {"name":"Saturn", "cost":650},
    "void": {"name":"Void", "cost":900}, "sun": {"name":"Solar", "cost":1250},
    "ice": {"name":"Ice", "cost":1650}, "toxic": {"name":"Toxic", "cost":2200}
}

var state := "menu"
var mode := "level"
var level := 1
var level_data: Dictionary = {}
var world: Node2D
var player: GravityPlanet
var ui: Control
var score_label: Label
var coin_label: Label
var combo_label: Label
var power_label: Label
var progress_label: Label
var score := 0.0
var coins_run := 0
var combo := 0
var best_combo := 0
var gates := 0
var target_gates := 0
var speed := 360.0
var elapsed := 0.0
var magnet := 0.0
var slow := 0.0
var invuln := 0.0
var endless_i := 0
var next_x := 900.0
var daily: Dictionary = {}
var daily_progress := 0.0
var daily_seed := 44119

func _ready() -> void:
    var bg := GravityStarfield.new()
    bg.z_index = -50
    add_child(bg)
    var layer := CanvasLayer.new()
    layer.layer = 20
    add_child(layer)
    ui = Control.new()
    ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    layer.add_child(ui)
    show_menu()

func _process(delta: float) -> void:
    if state != "game": return
    elapsed += delta
    magnet = maxf(0.0, magnet - delta)
    slow = maxf(0.0, slow - delta)
    invuln = maxf(0.0, invuln - delta)
    if mode != "level": speed = LevelFactory.endless_speed(gates)
    var real_speed := speed * SaveData.speed_multiplier() * (0.64 if slow > 0.0 else 1.0)
    world.position.x -= real_speed * delta
    score += real_speed * delta * (0.105 + float(combo) * 0.005)
    _check_gate_passes()
    _magnet_coins(delta)
    _cleanup_world()
    if mode != "level":
        while next_x + world.position.x < 2800.0: _spawn_endless()
    if player.global_position.y < 95.0 or player.global_position.y > 1825.0: _hit()
    if mode == "daily" and str(daily.get("type", "")) == "survive":
        daily_progress = elapsed
        _check_daily()
    _update_hud()

func _unhandled_input(event: InputEvent) -> void:
    if state != "game": return
    if event is InputEventScreenTouch and event.pressed: _gravity(-1.0 if event.position.y < 960.0 else 1.0)
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed: _gravity(-1.0 if event.position.y < 960.0 else 1.0)
    elif event is InputEventKey and event.pressed and not event.echo:
        if event.keycode in [KEY_W, KEY_UP]: _gravity(-1.0)
        elif event.keycode in [KEY_S, KEY_DOWN]: _gravity(1.0)
        elif event.keycode == KEY_SPACE:
            player.toggle_gravity(); Input.vibrate_handheld(8)
        elif event.keycode == KEY_ESCAPE: _pause()

func _gravity(dir: float) -> void:
    if player:
        player.set_gravity(dir)
        Input.vibrate_handheld(8)

# ----------------------------- menus -----------------------------
func show_menu() -> void:
    state = "menu"; _destroy_game(); _clear_ui()
    _label("GRAVITY", Vector2(90,165), Vector2(900,150), 112, Color("f4f7ff"), HORIZONTAL_ALIGNMENT_CENTER)
    _label("MASTER THE PULL", Vector2(90,320), Vector2(900,55), 30, Color("77f8ff"), HORIZONTAL_ALIGNMENT_CENTER)
    _label("◆ %d COINS   •   LEVEL %d/120   •   STREAK %d" % [SaveData.coins(), SaveData.unlocked_level(), SaveData.daily_streak()], Vector2(80,485), Vector2(920,60), 23, Color("d6dcff"), HORIZONTAL_ALIGNMENT_CENTER)
    _button("CONTINUE  •  LEVEL %d" % SaveData.unlocked_level(), 650, _start_level.bind(SaveData.unlocked_level()), true)
    _button("LEVEL MAP", 785, show_levels)
    _button("∞  ENDLESS", 920, _start_endless)
    _button("DAILY CHALLENGE", 1055, show_daily)
    _button("SKINS & UPGRADES", 1190, show_shop)
    _button("LEADERBOARD", 1325, show_leaderboard)
    _label("Tap upper half = gravity ↑    •    lower half = gravity ↓", Vector2(70,1580), Vector2(940,65), 23, Color(0.75,0.8,1,0.7), HORIZONTAL_ALIGNMENT_CENTER)

func show_levels() -> void:
    state = "menu"; _clear_ui(); _header("LEVEL MAP", "120 progressively harder runs"); _back(show_menu)
    var scroll := ScrollContainer.new(); scroll.position = Vector2(90,300); scroll.size = Vector2(900,1430); ui.add_child(scroll)
    var grid := GridContainer.new(); grid.columns = 4; grid.add_theme_constant_override("h_separation",18); grid.add_theme_constant_override("v_separation",18); scroll.add_child(grid)
    var unlocked := SaveData.unlocked_level()
    for i in range(1,121):
        var b := Button.new(); b.custom_minimum_size = Vector2(205,112); b.text = str(i) if i <= unlocked else "LOCKED"; b.disabled = i > unlocked; b.add_theme_font_size_override("font_size",26); _style(b, i == unlocked)
        if i <= unlocked: b.pressed.connect(_start_level.bind(i))
        grid.add_child(b)

func show_daily() -> void:
    state = "menu"; _clear_ui(); daily = _daily_data(); _header("DAILY CHALLENGE", Time.get_date_string_from_system()); _back(show_menu)
    var claimed := SaveData.daily_is_claimed(Time.get_date_string_from_system())
    _label("TODAY'S MISSION", Vector2(100,500), Vector2(880,60), 25, Color("77f8ff"), HORIZONTAL_ALIGNMENT_CENTER)
    _label(str(daily["label"]), Vector2(100,590), Vector2(880,150), 42, Color("f4f6ff"), HORIZONTAL_ALIGNMENT_CENTER)
    _label("+%d BONUS COINS" % int(daily["reward"]), Vector2(100,770), Vector2(880,60), 28, Color("ffd85a"), HORIZONTAL_ALIGNMENT_CENTER)
    _label("Current streak: %d" % SaveData.daily_streak(), Vector2(100,850), Vector2(880,55), 24, Color("d1d7ff"), HORIZONTAL_ALIGNMENT_CENTER)
    if claimed: _label("COMPLETED TODAY ✓", Vector2(100,930), Vector2(880,55), 25, Color("72f1a8"), HORIZONTAL_ALIGNMENT_CENTER)
    _button("REPLAY DAILY" if claimed else "START DAILY", 1130, _start_daily, true)

func show_shop() -> void:
    state = "menu"; _clear_ui(); _header("HANGAR", "Skins + Velocity Core"); _back(show_menu)
    _label("◆ %d" % SaveData.coins(), Vector2(730,210), Vector2(250,55), 28, Color("ffd85a"), HORIZONTAL_ALIGNMENT_RIGHT)
    _label("VELOCITY CORE  %d/10" % SaveData.speed_upgrade(), Vector2(105,340), Vector2(500,55), 30, Color("f4f6ff"))
    _label("+1.8% speed and +5% coin yield / upgrade", Vector2(105,400), Vector2(580,45), 20, Color(0.7,0.76,1,0.75))
    var up := Button.new(); up.position = Vector2(700,330); up.size = Vector2(275,110); up.text = "MAXED" if SaveData.speed_upgrade() >= 10 else "UPGRADE\n◆ %d" % SaveData.speed_upgrade_cost(); up.disabled = SaveData.speed_upgrade() >= 10; _style(up,true); up.pressed.connect(_buy_speed); ui.add_child(up)
    var y := 520.0
    for skin_id in SKINS.keys():
        var meta: Dictionary = SKINS[skin_id]
        _label(str(meta["name"]).to_upper(), Vector2(115,y), Vector2(280,80), 27, Color("f1f4ff"))
        var status := "EQUIPPED" if SaveData.selected_skin() == skin_id else ("OWNED" if SaveData.owns_skin(skin_id) else "◆ %d" % int(meta["cost"]))
        _label(status, Vector2(390,y), Vector2(240,80), 20, Color("77f8ff"), HORIZONTAL_ALIGNMENT_CENTER)
        var b := Button.new(); b.position = Vector2(670,y+5); b.size = Vector2(280,70); b.text = "SELECT" if SaveData.owns_skin(skin_id) else "UNLOCK"; b.disabled = SaveData.selected_skin() == skin_id; _style(b,false); b.pressed.connect(_skin_action.bind(skin_id)); ui.add_child(b)
        y += 135.0

func show_leaderboard() -> void:
    state = "menu"; _clear_ui(); _header("LEADERBOARD", "Local device top 10"); _back(show_menu)
    var board := SaveData.leaderboard()
    if board.is_empty():
        _label("No records yet.\nPlay Endless and set the first score.", Vector2(120,650), Vector2(840,180), 34, Color(0.8,0.84,1,0.8), HORIZONTAL_ALIGNMENT_CENTER); return
    var y := 340.0
    for i in range(board.size()):
        var e: Dictionary = board[i]
        _label("#%d   %s" % [i+1, str(e.get("mode","run")).to_upper()], Vector2(110,y), Vector2(430,70), 25, Color("d6dcff"))
        _label("%07d" % int(e.get("score",0)), Vector2(540,y), Vector2(420,70), 30, Color("ffffff"), HORIZONTAL_ALIGNMENT_RIGHT)
        y += 115.0

# ----------------------------- run setup -----------------------------
func _start_level(n: int) -> void:
    mode = "level"; level = clampi(n,1,120); level_data = LevelFactory.build_level(level); _begin(); speed = float(level_data["speed"])
    var segs: Array = level_data["segments"]; target_gates = segs.size()
    for i in range(segs.size()): _spawn_segment(segs[i], i)
    _hud()

func _start_endless() -> void:
    mode = "endless"; level = 0; daily_seed = 44119; _begin()
    for i in range(8): _spawn_endless()
    _hud()

func _start_daily() -> void:
    mode = "daily"; level = 0; daily = _daily_data(); daily_seed = abs(Time.get_date_string_from_system().hash()) + 7727; _begin()
    for i in range(8): _spawn_endless()
    _hud()

func _begin() -> void:
    _destroy_game(); _clear_ui(); state = "game"; score = 0.0; coins_run = 0; combo = 0; best_combo = 0; gates = 0; target_gates = 0; elapsed = 0.0; magnet = 0.0; slow = 0.0; invuln = 0.0; endless_i = 0; next_x = 900.0; daily_progress = 0.0
    world = Node2D.new(); add_child(world)
    player = GravityPlanet.new(); add_child(player); player.reset(START, SaveData.selected_skin())

func _spawn_segment(cfg: Dictionary, idx: int) -> void:
    var gate := GravityGate.new(); world.add_child(gate); gate.setup(cfg, THEMES[(idx / 12) % THEMES.size()]); gate.collided.connect(_hit)
    var count := int(cfg.get("coin_arc",4)); var gx := float(cfg.get("x",0)); var gy := float(cfg.get("gap_y",960))
    for c in range(count):
        var spread := float(c - (count-1)*0.5); _spawn_pickup("coin", Vector2(gx-210.0+spread*58.0, gy+sin(float(c)*1.25)*70.0))
    var p := str(cfg.get("powerup",""));
    if not p.is_empty(): _spawn_pickup(p, Vector2(gx+225.0,gy))

func _spawn_endless() -> void:
    var cfg := LevelFactory.build_endless_segment(endless_i,daily_seed); cfg["x"] = next_x; _spawn_segment(cfg,endless_i); next_x += LevelFactory.BASE_SPACING + minf(90.0,float(endless_i)*0.7); endless_i += 1

func _spawn_pickup(kind: String, pos: Vector2) -> void:
    var p := GravityPickup.new(); p.position = pos; world.add_child(p); p.setup(kind); p.collected.connect(_pickup)

func _check_gate_passes() -> void:
    for child in world.get_children():
        if child is GravityGate:
            var g: GravityGate = child
            if not g.passed and g.global_position.x <= player.global_position.x:
                g.passed = true; gates += 1; var perfect := absf(player.global_position.y-g.center_y()) <= g.gap_size*0.17; _passed(perfect)
    if mode == "level" and target_gates > 0 and gates >= target_gates: _finish(true,"LEVEL CLEARED")

func _passed(perfect: bool) -> void:
    if perfect:
        combo += 1; best_combo = maxi(best_combo,combo); score += 120.0*(1.0+float(combo)*0.18); Input.vibrate_handheld(14)
    else:
        combo = 0; score += 45.0
    if mode == "daily" and str(daily.get("type","")) == "combo": daily_progress = float(best_combo); _check_daily()

func _hit() -> void:
    if state != "game" or invuln > 0.0: return
    if player.consume_shield():
        invuln = 1.0; combo = 0; score = maxf(0.0,score-180.0); player.velocity.y *= -0.32; player.global_position.y = clampf(player.global_position.y,150.0,1770.0); Input.vibrate_handheld(65); return
    Input.vibrate_handheld(140); _finish(false,"GRAVITY LOST")

func _pickup(kind: String, amount: int) -> void:
    if kind == "coin":
        var gained := maxi(1,roundi(float(amount)*SaveData.coin_multiplier())); coins_run += gained; score += 35.0*float(gained)
        if mode == "daily" and str(daily.get("type","")) == "coins": daily_progress += gained; _check_daily()
    elif kind == "magnet": magnet = maxf(magnet,7.5)
    elif kind == "shield": player.add_shield()
    elif kind == "slow": slow = maxf(slow,6.0)
    Input.vibrate_handheld(10)

func _magnet_coins(delta: float) -> void:
    if magnet <= 0.0: return
    for child in world.get_children():
        if child is GravityPickup and child.kind == "coin" and child.global_position.distance_to(player.global_position) < 390.0: child.pull_toward(player.global_position,980.0,delta)

func _cleanup_world() -> void:
    for child in world.get_children():
        if child is Node2D and child.global_position.x < -320.0: child.queue_free()

func _finish(ok: bool, title: String) -> void:
    if state != "game": return
    state = "result"; player.active = false; var earned := coins_run; var bonus := 0
    if mode == "level" and ok:
        bonus = int(level_data.get("reward",0)); earned += bonus; SaveData.unlock_level(mini(120,level+1))
    SaveData.add_coins(earned)
    if mode == "daily" and ok:
        var reward := int(daily.get("reward",0))
        if SaveData.claim_daily(Time.get_date_string_from_system(),reward): bonus += reward
    SaveData.record_score(mode if mode != "level" else "level %d" % level,int(score)); _clear_ui()
    _label(title,Vector2(100,380),Vector2(880,100),58,Color("72f1a8") if ok else Color("ff728e"),HORIZONTAL_ALIGNMENT_CENTER)
    _label("%07d" % int(score),Vector2(100,515),Vector2(880,90),52,Color("ffffff"),HORIZONTAL_ALIGNMENT_CENTER)
    _label("◆ %d RUN   +   ◆ %d BONUS" % [coins_run,bonus],Vector2(100,680),Vector2(880,60),27,Color("ffd85a"),HORIZONTAL_ALIGNMENT_CENTER)
    _label("BEST PERFECT COMBO  x%d" % best_combo,Vector2(100,760),Vector2(880,55),23,Color("77f8ff"),HORIZONTAL_ALIGNMENT_CENTER)
    if mode == "level" and ok and level < 120: _button("NEXT LEVEL",980,_start_level.bind(level+1),true)
    elif mode == "level": _button("RETRY",980,_start_level.bind(level),true)
    elif mode == "daily": _button("REPLAY DAILY",980,_start_daily,true)
    else: _button("RETRY ENDLESS",980,_start_endless,true)
    _button("HOME",1120,show_menu)

func _pause() -> void:
    if state != "game": return
    state = "paused"; player.active = false; _clear_ui(); _label("PAUSED",Vector2(100,500),Vector2(880,100),62,Color("ffffff"),HORIZONTAL_ALIGNMENT_CENTER); _button("RESUME",760,_resume,true); _button("HOME",900,show_menu)

func _resume() -> void:
    if state != "paused": return
    state = "game"; player.active = true; _hud()

# ----------------------------- daily -----------------------------
func _daily_data() -> Dictionary:
    var h := abs(Time.get_date_string_from_system().hash()); var k := h % 3
    if k == 0:
        var n := 24 + h % 13; return {"type":"coins","target":n,"reward":180+h%80,"label":"Collect %d coins in one run" % n}
    if k == 1:
        var n := 5 + h % 5; return {"type":"combo","target":n,"reward":200+h%90,"label":"Reach a Perfect combo of x%d" % n}
    var n := 45 + h % 31; return {"type":"survive","target":n,"reward":210+h%90,"label":"Survive for %d seconds" % n}

func _check_daily() -> void:
    if state == "game" and mode == "daily" and daily_progress >= float(daily.get("target",1)): score += 1200.0; _finish(true,"DAILY COMPLETE")

# ----------------------------- hud -----------------------------
func _hud() -> void:
    _clear_ui(); score_label = _label("0000000",Vector2(390,50),Vector2(300,60),30,Color("ffffff"),HORIZONTAL_ALIGNMENT_CENTER); coin_label = _label("◆ 0",Vector2(55,52),Vector2(250,55),25,Color("ffd85a")); combo_label = _label("",Vector2(720,130),Vector2(300,48),22,Color("77f8ff"),HORIZONTAL_ALIGNMENT_RIGHT); power_label = _label("",Vector2(45,130),Vector2(520,48),20,Color("d9b0ff")); progress_label = _label("",Vector2(220,1760),Vector2(640,55),21,Color(0.82,0.86,1,0.75),HORIZONTAL_ALIGNMENT_CENTER)
    var b := Button.new(); b.position = Vector2(918,45); b.size = Vector2(110,72); b.text = "Ⅱ"; _style(b,false); b.pressed.connect(_pause); ui.add_child(b); _update_hud()

func _update_hud() -> void:
    if not is_instance_valid(score_label): return
    score_label.text = "%07d" % int(score); coin_label.text = "◆ %d" % coins_run; combo_label.text = "PERFECT x%d" % combo if combo > 1 else ""
    var p: Array[String] = []
    if player.shield_charges > 0: p.append("SHIELD")
    if magnet > 0.0: p.append("MAGNET %.1f" % magnet)
    if slow > 0.0: p.append("SLOW %.1f" % slow)
    power_label.text = "  •  ".join(p)
    if mode == "level": progress_label.text = "LEVEL %d   %d / %d GATES" % [level,gates,target_gates]
    elif mode == "daily": progress_label.text = "DAILY • %s   %.0f / %.0f" % [str(daily.get("type","")).to_upper(),daily_progress,float(daily.get("target",1))]
    else: progress_label.text = "ENDLESS   %d GATES   %.1fs" % [gates,elapsed]

# ----------------------------- shop -----------------------------
func _buy_speed() -> void: SaveData.buy_speed_upgrade(); show_shop()
func _skin_action(id: String) -> void:
    if SaveData.owns_skin(id): SaveData.select_skin(id)
    else: SaveData.buy_skin(id,int(SKINS[id]["cost"]))
    show_shop()

# ----------------------------- ui helpers -----------------------------
func _destroy_game() -> void:
    if is_instance_valid(player): player.queue_free()
    if is_instance_valid(world): world.queue_free()
    player = null; world = null

func _clear_ui() -> void:
    for c in ui.get_children(): c.queue_free()

func _header(title: String, sub: String) -> void:
    _label(title,Vector2(90,105),Vector2(900,90),54,Color("f4f7ff"),HORIZONTAL_ALIGNMENT_CENTER); _label(sub,Vector2(90,200),Vector2(900,50),22,Color(0.68,0.74,0.95,0.75),HORIZONTAL_ALIGNMENT_CENTER)

func _back(call: Callable) -> void:
    var b := Button.new(); b.position = Vector2(55,55); b.size = Vector2(190,74); b.text = "‹ BACK"; _style(b,false); b.pressed.connect(call); ui.add_child(b)

func _label(text: String, pos: Vector2, size: Vector2, fs: int, color: Color, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
    var l := Label.new(); l.text = text; l.position = pos; l.size = size; l.add_theme_font_size_override("font_size",fs); l.add_theme_color_override("font_color",color); l.horizontal_alignment = align; l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; ui.add_child(l); return l

func _button(text: String, y: float, call: Callable, primary: bool = false) -> Button:
    var b := Button.new(); b.position = Vector2(135,y); b.size = Vector2(810,105); b.text = text; b.add_theme_font_size_override("font_size",27); _style(b,primary); b.pressed.connect(call); ui.add_child(b); return b

func _style(b: Button, primary: bool) -> void:
    var s := StyleBoxFlat.new(); s.bg_color = Color("4e50db") if primary else Color(0.07,0.09,0.22,0.96); s.corner_radius_top_left = 24; s.corner_radius_top_right = 24; s.corner_radius_bottom_left = 24; s.corner_radius_bottom_right = 24; s.border_width_left = 1; s.border_width_top = 1; s.border_width_right = 1; s.border_width_bottom = 1; s.border_color = Color("777cff") if primary else Color(0.55,0.65,1.0,0.2); b.add_theme_stylebox_override("normal",s); var h := s.duplicate(); h.bg_color = s.bg_color.lightened(0.1); b.add_theme_stylebox_override("hover",h); b.add_theme_color_override("font_color",Color("f5f6ff")); b.focus_mode = Control.FOCUS_NONE
