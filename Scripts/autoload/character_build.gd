extends Node

## 单机成长：职业、属性点、攻速/移速、玩家生命、强击。持久化到 user://。

const SAVE_PATH := "user://character_build.cfg"
const SAVE_DEBOUNCE_SEC := 0.35

const CLASS_WARRIOR := 0
const CLASS_ARCHER := 1
const CLASS_MAGE := 2
const CLASS_PRIEST := 3

signal build_changed()

var unspent_points: int = 2
var atk_speed_level: int = 0
var move_level: int = 0

## 0 战士 · 1 弓箭 · 2 法师 · 3 牧师
var combat_class: int = CLASS_WARRIOR
## 弓箭 / 法师：true=自动锁最近怪；false=朝摇杆/WASD 面朝方向
var ranged_auto_lock: bool = true
## 已装备武器（来自商店），用于下次进入世界时恢复
var equipped_weapon_id: String = ""
## 已购买武器列表（限购1把）
var owned_weapon_ids: PackedStringArray = PackedStringArray()

var _surge_cooldown: float = 0.0
var _stored_melee_multiplier: float = 1.0
var _had_surge_cd: bool = false

## 玩家生命（单机）；-1 表示未初始化
var player_hp: int = -1
## 世界 / 试炼战斗等级与当前段经验，由 WorldScene、SurvivorArena 同步并持久化（避免进副本再回大世界被清零）。
var runtime_combat_level: int = 1
var runtime_combat_xp: int = 0
var _save_dirty: bool = false
var _save_countdown: float = 0.0


func _ready() -> void:
	_load()
	set_process(true)


func _process(delta: float) -> void:
	_surge_cooldown = maxf(0.0, _surge_cooldown - delta)
	var has_cd: bool = _surge_cooldown > 0.01
	if _had_surge_cd and not has_cd:
		build_changed.emit()
	_had_surge_cd = has_cd
	if _save_dirty:
		_save_countdown = maxf(0.0, _save_countdown - delta)
		if _save_countdown <= 0.0:
			_flush_save()


func _exit_tree() -> void:
	_flush_save()


func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var cf := ConfigFile.new()
	if cf.load(SAVE_PATH) != OK:
		return
	unspent_points = int(cf.get_value("build", "unspent", unspent_points))
	atk_speed_level = int(cf.get_value("build", "atk_speed_level", 0))
	move_level = int(cf.get_value("build", "move_level", 0))
	combat_class = clampi(int(cf.get_value("build", "combat_class", CLASS_WARRIOR)), 0, 3)
	ranged_auto_lock = bool(cf.get_value("build", "ranged_auto_lock", true))
	equipped_weapon_id = str(cf.get_value("build", "equipped_weapon_id", ""))
	var owned_v: Variant = cf.get_value("build", "owned_weapon_ids", PackedStringArray())
	if owned_v is PackedStringArray:
		owned_weapon_ids = owned_v as PackedStringArray
	elif owned_v is Array:
		owned_weapon_ids = PackedStringArray(owned_v as Array)
	else:
		owned_weapon_ids = PackedStringArray()
	player_hp = int(cf.get_value("build", "player_hp", -1))
	runtime_combat_level = maxi(1, int(cf.get_value("build", "runtime_combat_level", runtime_combat_level)))
	runtime_combat_xp = maxi(0, int(cf.get_value("build", "runtime_combat_xp", 0)))
	_normalize_runtime_combat()


func _save() -> void:
	_queue_save()


func _queue_save(immediate: bool = false) -> void:
	_save_dirty = true
	_save_countdown = 0.0 if immediate else SAVE_DEBOUNCE_SEC


func _flush_save() -> void:
	if not _save_dirty:
		return
	var cf := ConfigFile.new()
	cf.set_value("build", "unspent", unspent_points)
	cf.set_value("build", "atk_speed_level", atk_speed_level)
	cf.set_value("build", "move_level", move_level)
	cf.set_value("build", "combat_class", combat_class)
	cf.set_value("build", "ranged_auto_lock", ranged_auto_lock)
	cf.set_value("build", "equipped_weapon_id", equipped_weapon_id)
	cf.set_value("build", "owned_weapon_ids", owned_weapon_ids)
	cf.set_value("build", "player_hp", player_hp)
	cf.set_value("build", "runtime_combat_level", runtime_combat_level)
	cf.set_value("build", "runtime_combat_xp", runtime_combat_xp)
	cf.save(SAVE_PATH)
	_save_dirty = false
	_save_countdown = 0.0


func _normalize_runtime_combat() -> void:
	var lv: int = maxi(1, runtime_combat_level)
	var cap: int = combat_xp_to_next_level(lv)
	while runtime_combat_xp >= cap:
		runtime_combat_xp -= cap
		lv += 1
		cap = combat_xp_to_next_level(lv)
	runtime_combat_level = lv
	runtime_combat_xp = maxi(0, runtime_combat_xp)


## 同步大世界 / 试炼共用的等级与「本段」经验，并写入存档。
func set_runtime_combat_progress(level: int, xp: int) -> void:
	var lv: int = maxi(1, level)
	var x: int = maxi(0, xp)
	var cap: int = combat_xp_to_next_level(lv)
	while x >= cap:
		x -= cap
		lv += 1
		cap = combat_xp_to_next_level(lv)
	if lv == runtime_combat_level and x == runtime_combat_xp:
		return
	runtime_combat_level = lv
	runtime_combat_xp = x
	ensure_player_hp()
	_save()
	build_changed.emit()


func set_runtime_combat_level(lv: int) -> void:
	var nl: int = maxi(1, lv)
	var cap: int = combat_xp_to_next_level(nl)
	var x: int = clampi(runtime_combat_xp, 0, maxi(0, cap - 1))
	set_runtime_combat_progress(nl, x)


## 战斗等级（大世界 / 试炼）：当前等级 → 下一级所需本段经验总量。旧式约 28+lv*22，整体放缓并略带上扬曲线。
func combat_xp_to_next_level(current_combat_level: int) -> int:
	var lv := maxi(1, current_combat_level)
	return 45 + lv * 34 + (lv * lv * 5) / 2


func get_combat_class() -> int:
	return combat_class


func set_combat_class(c: int) -> void:
	var nc := clampi(c, 0, 3)
	if nc == combat_class:
		return
	combat_class = nc
	_save()
	build_changed.emit()


func get_equipped_weapon_id() -> String:
	return equipped_weapon_id


func has_owned_weapon(weapon_id: String) -> bool:
	var wid: String = weapon_id.strip_edges()
	return owned_weapon_ids.has(wid)


func add_owned_weapon(weapon_id: String) -> void:
	var wid: String = weapon_id.strip_edges()
	if wid.is_empty():
		return
	if owned_weapon_ids.has(wid):
		return
	owned_weapon_ids.append(wid)
	_save()
	build_changed.emit()


func equip_weapon(weapon_id: String, cls: int) -> void:
	var wid: String = weapon_id.strip_edges()
	var ncls: int = clampi(cls, 0, 3)
	var changed: bool = false
	if equipped_weapon_id != wid:
		equipped_weapon_id = wid
		changed = true
	if combat_class != ncls:
		combat_class = ncls
		changed = true
	if not changed:
		return
	_save()
	build_changed.emit()


func toggle_ranged_auto_lock() -> void:
	ranged_auto_lock = not ranged_auto_lock
	_save()
	build_changed.emit()


func class_display_name() -> String:
	match combat_class:
		CLASS_ARCHER:
			return "弓箭手"
		CLASS_MAGE:
			return "法师"
		CLASS_PRIEST:
			return "牧师"
		_:
			return "战士"


func weapon_display_name() -> String:
	match combat_class:
		CLASS_ARCHER:
			return "长弓（远程）"
		CLASS_MAGE:
			return "法杖（范围）"
		CLASS_PRIEST:
			return "圣典（治疗）"
		_:
			return "长剑（近战）"


func attack_power_display(combat_lv: int) -> int:
	return 12 + combat_lv * 4


func move_speed_percent_display() -> float:
	return (move_speed_multiplier() - 1.0) * 100.0


func attack_speed_percent_display() -> float:
	return (1.0 / melee_cooldown_multiplier() - 1.0) * 100.0


func get_max_hp() -> int:
	return 88 + move_level * 8 + atk_speed_level * 3


func ensure_player_hp() -> void:
	var mx := get_max_hp()
	if player_hp < 0:
		player_hp = mx
	else:
		player_hp = clampi(player_hp, 0, mx)


func get_player_hp() -> int:
	ensure_player_hp()
	return player_hp


func damage_player(amount: int) -> bool:
	ensure_player_hp()
	amount = maxi(1, amount)
	player_hp = maxi(0, player_hp - amount)
	_save()
	build_changed.emit()
	return player_hp <= 0


func full_heal_player() -> void:
	ensure_player_hp()
	player_hp = get_max_hp()
	_save()
	build_changed.emit()


func grant_points_for_levels(levels_gained: int) -> void:
	if levels_gained <= 0:
		return
	unspent_points += levels_gained
	ensure_player_hp()
	_save()
	build_changed.emit()


func melee_cooldown_multiplier() -> float:
	return 1.0 / (1.0 + 0.055 * float(atk_speed_level))


func move_speed_multiplier() -> float:
	return 1.0 + 0.045 * float(move_level)


func try_spend_attack_speed() -> bool:
	if unspent_points <= 0:
		return false
	unspent_points -= 1
	atk_speed_level += 1
	ensure_player_hp()
	_save()
	build_changed.emit()
	return true


func try_spend_move_speed() -> bool:
	if unspent_points <= 0:
		return false
	unspent_points -= 1
	move_level += 1
	ensure_player_hp()
	_save()
	build_changed.emit()
	return true


func surge_cooldown_remaining() -> float:
	return _surge_cooldown


## 成长面板等用的完整技能名（机制仍是下一击倍率 + 8s 冷却）。
func surge_skill_display_name() -> String:
	match combat_class:
		CLASS_ARCHER:
			return "万箭齐发"
		CLASS_MAGE:
			return "法力爆发"
		CLASS_PRIEST:
			return "神恩祷言"
		_:
			return "强击"


## 圆形技能按钮用短文案（可含换行）；与 `surge_skill_display_name` 同义不同排版。
func surge_skill_button_caption() -> String:
	match combat_class:
		CLASS_ARCHER:
			return "万箭\n齐发"
		CLASS_MAGE:
			return "法力\n爆发"
		CLASS_PRIEST:
			return "神恩\n祷言"
		_:
			return "强击"


## 成长面板等：技能效果一句说明（不含冷却）。
func surge_skill_effect_hint() -> String:
	match combat_class:
		CLASS_ARCHER:
			return "向四周射出箭阵（多支独立箭矢）"
		CLASS_MAGE:
			return "下一记范围伤害 +38%"
		CLASS_PRIEST:
			return "下一次治疗 +38%"
		_:
			return "下一次挥砍伤害 +38%"


func can_activate_surge() -> bool:
	return _surge_cooldown <= 0.01


func activate_surge() -> bool:
	if not can_activate_surge():
		return false
	## 弓箭「万箭齐发」为多箭齐射，不再叠加强击倍率；其它职业仍为下一次 +38%。
	if combat_class == CLASS_ARCHER:
		_stored_melee_multiplier = 1.0
	else:
		_stored_melee_multiplier = 1.38
	_surge_cooldown = 8.0
	build_changed.emit()
	return true


func consume_melee_damage_multiplier() -> float:
	var m: float = _stored_melee_multiplier
	_stored_melee_multiplier = 1.0
	return m


func primary_cooldown_base() -> float:
	match combat_class:
		CLASS_ARCHER:
			return 0.42
		CLASS_MAGE:
			return 0.56
		CLASS_PRIEST:
			return 0.64
		_:
			return 0.38


func effective_primary_cooldown() -> float:
	return primary_cooldown_base() * melee_cooldown_multiplier()


func bow_range() -> float:
	return 300.0


## 弓箭「自动锁敌」仅用于取朝向时的索敌半径；箭实际飞行由弹射物脚本按时间与碰撞处理。
func archer_auto_lock_search_radius() -> float:
	return 5600.0


func mage_aoe_radius() -> float:
	return 92.0


func priest_heal_base(combat_lv: int) -> int:
	return 14 + combat_lv * 5


func heal_priest_with_multiplier(combat_lv: int, mult: float) -> int:
	ensure_player_hp()
	var base: int = priest_heal_base(combat_lv)
	var amt: int = maxi(1, int(round(float(base) * mult)))
	var mx := get_max_hp()
	var before := player_hp
	player_hp = mini(mx, player_hp + amt)
	var gained: int = player_hp - before
	_save()
	build_changed.emit()
	return gained
