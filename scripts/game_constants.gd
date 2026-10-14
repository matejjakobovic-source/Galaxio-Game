class_name GameConstants
extends RefCounted

const VIEWPORT_SIZE := Vector2(1080.0, 1920.0)
const PLAYER_X := 220.0
const PLAYER_START := Vector2(PLAYER_X, 960.0)
const TOP_LIMIT := 95.0
const BOTTOM_LIMIT := 1825.0
const TOTAL_LEVELS := 120
const BASE_GATE_SPACING := 560.0

const THEME_COLORS := [
	Color("685cff"),
	Color("22c8ff"),
	Color("ff5f8f"),
	Color("8f68ff"),
	Color("3ce0a3"),
	Color("ff9f45")
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
