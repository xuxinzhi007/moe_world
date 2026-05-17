extends RefCounted
class_name WorldSceneConfig

const WORLD_CAMERA_ZOOM := Vector2(1.0, 1.0)
const WORLD_VISUAL_RECT := Rect2(-2200.0, -1200.0, 5200.0, 3200.0)

const WORLD_SPAWN_RECT := Rect2(-520.0, -140.0, 2320.0, 1520.0)
const DECO_STRATIFY_COLS := 18
const DECO_STRATIFY_ROWS := 18
const WORLD_OFFLINE_SPAWN := Vector2(0.0, 80.0)
const DECO_SPAWN_EXCLUDE_RADIUS := 200.0

const MONSTER_MAX_COUNT := 14
const MONSTER_RESPAWN_INTERVAL := 2.8
const NEUTRAL_MAX_COUNT := 6
const NEUTRAL_RESPAWN_INTERVAL := 4.8

const REGION_STREAM_TICK_SEC := 0.35
const REGION_PRELOAD_DISTANCE := 520.0
const REGION_ACTIVATE_DISTANCE := 360.0
const REGION_UNLOAD_DISTANCE := 920.0
const REGION_STRICT_SINGLE_ACTIVE := true
const REGION_EDGE_PRELOAD_MARGIN := 26.0

const REGION_NEIGHBORS := {
	"world_main": ["east_market", "south_trail", "coming_soon"],
	"east_market": ["world_main"],
	"south_trail": ["world_main"],
	"coming_soon": ["world_main"],
}

const REGION_FALLBACK_EXITS := {
	"world_main": {"right": "east_market", "bottom": "south_trail", "top": "coming_soon"},
	"east_market": {"left": "world_main"},
	"south_trail": {"top": "world_main"},
	"coming_soon": {"bottom": "world_main"},
}

const REGION_MAP_SIZES := {
	"world_main": Vector2(2320.0, 1520.0),
	"plaza": Vector2(1600.0, 960.0),
	"east_market": Vector2(1720.0, 980.0),
	"south_trail": Vector2(1840.0, 1080.0),
	"coming_soon": Vector2(1480.0, 920.0),
}

const REGION_MAP_TITLES := {
	"world_main": "主城",
	"plaza": "主城",
	"east_market": "东市商街",
	"south_trail": "南郊野径",
	"coming_soon": "未开放区域",
}

const REGION_MAP_COLORS := {
	"world_main": Color(1.0, 0.82, 0.64, 0.46),
	"plaza": Color(1.0, 0.72, 0.82, 0.5),
	"east_market": Color(0.7, 0.88, 1.0, 0.45),
	"south_trail": Color(0.75, 1.0, 0.78, 0.42),
	"coming_soon": Color(0.72, 0.76, 0.86, 0.32),
}
