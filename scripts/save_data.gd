extends Node

const SAVE_PATH := "user://gravity_save.json"

var data: Dictionary = {}

func _ready() -> void:
    load_save()

func defaults() -> Dictionary:
    return {
        "coins": 0,
        "unlocked_level": 1,
        "selected_skin": "terra",
        "owned_skins": ["terra"],
        "speed_upgrade": 0,
        "leaderboard": [],
        "daily_claimed": {},
        "daily_streak": 0,
        "last_daily_date": ""
    }

func load_save() -> void:
    data = defaults()
    if not FileAccess.file_exists(SAVE_PATH):
        save()
        return
    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file == null:
        return
    var parsed = JSON.parse_string(file.get_as_text())
    if typeof(parsed) != TYPE_DICTIONARY:
        return
    for key in data.keys():
        if parsed.has(key):
            data[key] = parsed[key]

func save() -> void:
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file:
        file.store_string(JSON.stringify(data))

func coins() -> int:
    return int(data.get("coins", 0))

func add_coins(amount: int) -> void:
    data["coins"] = max(0, coins() + amount)
    save()

func spend_coins(amount: int) -> bool:
    if coins() < amount:
        return false
    data["coins"] = coins() - amount
    save()
    return true

func unlocked_level() -> int:
    return clampi(int(data.get("unlocked_level", 1)), 1, 120)

func unlock_level(level: int) -> void:
    data["unlocked_level"] = max(unlocked_level(), clampi(level, 1, 120))
    save()

func selected_skin() -> String:
    return str(data.get("selected_skin", "terra"))

func owns_skin(skin_id: String) -> bool:
    return skin_id in data.get("owned_skins", [])

func buy_skin(skin_id: String, cost: int) -> bool:
    if owns_skin(skin_id) or not spend_coins(cost):
        return false
    var owned: Array = data.get("owned_skins", [])
    owned.append(skin_id)
    data["owned_skins"] = owned
    data["selected_skin"] = skin_id
    save()
    return true

func select_skin(skin_id: String) -> bool:
    if not owns_skin(skin_id):
        return false
    data["selected_skin"] = skin_id
    save()
    return true

func speed_upgrade() -> int:
    return clampi(int(data.get("speed_upgrade", 0)), 0, 10)

func speed_upgrade_cost() -> int:
    var level := speed_upgrade()
    return 120 + level * level * 55 + level * 40

func buy_speed_upgrade() -> bool:
    if speed_upgrade() >= 10:
        return false
    var cost := speed_upgrade_cost()
    if not spend_coins(cost):
        return false
    data["speed_upgrade"] = speed_upgrade() + 1
    save()
    return true

func speed_multiplier() -> float:
    return 1.0 + float(speed_upgrade()) * 0.018

func coin_multiplier() -> float:
    return 1.0 + float(speed_upgrade()) * 0.05

func record_score(mode_name: String, score: int) -> void:
    var board: Array = data.get("leaderboard", [])
    board.append({
        "mode": mode_name,
        "score": score,
        "date": Time.get_date_string_from_system()
    })
    board.sort_custom(_score_desc)
    if board.size() > 10:
        board.resize(10)
    data["leaderboard"] = board
    save()

func _score_desc(a: Dictionary, b: Dictionary) -> bool:
    return int(a.get("score", 0)) > int(b.get("score", 0))

func leaderboard() -> Array:
    return data.get("leaderboard", [])

func daily_is_claimed(date_key: String) -> bool:
    var claimed: Dictionary = data.get("daily_claimed", {})
    return bool(claimed.get(date_key, false))

func claim_daily(date_key: String, reward: int) -> bool:
    if daily_is_claimed(date_key):
        return false
    var claimed: Dictionary = data.get("daily_claimed", {})
    claimed[date_key] = true
    data["daily_claimed"] = claimed
    add_coins(reward)
    _update_daily_streak(date_key)
    save()
    return true

func _update_daily_streak(date_key: String) -> void:
    var previous := str(data.get("last_daily_date", ""))
    if previous == date_key:
        return
    if previous.is_empty():
        data["daily_streak"] = 1
    else:
        var prev_parts := previous.split("-")
        var now_parts := date_key.split("-")
        if prev_parts.size() == 3 and now_parts.size() == 3:
            var prev_unix := Time.get_unix_time_from_datetime_dict({
                "year": int(prev_parts[0]), "month": int(prev_parts[1]), "day": int(prev_parts[2]),
                "hour": 12, "minute": 0, "second": 0
            })
            var now_unix := Time.get_unix_time_from_datetime_dict({
                "year": int(now_parts[0]), "month": int(now_parts[1]), "day": int(now_parts[2]),
                "hour": 12, "minute": 0, "second": 0
            })
            if int(now_unix - prev_unix) == 86400:
                data["daily_streak"] = int(data.get("daily_streak", 0)) + 1
            else:
                data["daily_streak"] = 1
    data["last_daily_date"] = date_key

func daily_streak() -> int:
    return int(data.get("daily_streak", 0))
