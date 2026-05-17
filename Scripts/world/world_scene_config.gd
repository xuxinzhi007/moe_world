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
	"plaza": ["east_market", "south_trail"],
	"east_market": ["plaza"],
	"south_trail": ["plaza"],
}

const REGION_FALLBACK_EXITS := {
	"plaza": {"left": "south_trail", "right": "east_market"},
	"east_market": {"left": "plaza"},
	"south_trail": {"right": "plaza"},
}

const REGION_MAP_SIZES := {
	"plaza": Vector2(2200.0, 1300.0),
	"east_market": Vector2(2200.0, 1300.0),
	"south_trail": Vector2(2200.0, 1300.0),
}

const REGION_MAP_TITLES := {
	"plaza": "传送广场",
	"east_market": "东市商街",
	"south_trail": "南郊野径",
}

const REGION_MAP_COLORS := {
	"plaza": Color(1.0, 0.72, 0.82, 0.5),
	"east_market": Color(0.7, 0.88, 1.0, 0.45),
	"south_trail": Color(0.75, 1.0, 0.78, 0.42),
}
