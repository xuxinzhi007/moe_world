extends Node

## 单机成长：职业、属性点、攻速/移速、玩家生命、强击。持久化到 user://。

const SAVE_PATH := "user://character_build.cfg"

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

var _surge_cooldown: float = 0.0
var _stored_melee_multiplier: float = 1.0
var _had_surge_cd: bool = false

## 玩家生命（单机）；-1 表示未初始化
var player_hp: int = -1
## 世界战斗等级由 WorldScene 同步，用于面板与牧师治疗量
var runtime_combat_level: int = 1


func _ready() -> void:
	_load()
	set_process(true)


func _process(delta: float) -> void:
	_surge_cooldown = maxf(0.0, _surge_cooldown - delta)
	var has_cd: bool = _surge_cooldown > 0.01
	if _had_surge_cd and not has_cd:
		build_changed.emit()
	_had_surge_cd = has_cd


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
	player_hp = int(cf.get_value("build", "player_hp", -1))


func _save() -> void:
	var cf := ConfigFile.new()
	cf.set_value("build", "unspent", unspent_points)
	cf.set_value("build", "atk_speed_level", atk_speed_level)
	cf.set_value("build", "move_level", move_level)
	cf.set_value("build", "combat_class", combat_class)
	cf.set_value("build", "ranged_auto_lock", ranged_auto_lock)
	cf.set_value("build", "player_hp", player_hp)
	cf.save(SAVE_PATH)


func set_runtime_combat_level(lv: int) -> void:
	var v := maxi(1, lv)
	ensure_player_hp()
	if v == runtime_combat_level:
		return
	runtime_combat_level = v
	build_changed.emit()



func get_combat_class() -> int:
	return combat_class


func set_combat_class(c: int) -> void:
	var nc := clampi(c, 0, 3)
	if nc == combat_class:
		return
	combat_class = nc
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


func can_activate_surge() -> bool:
	return _surge_cooldown <= 0.01


func activate_surge() -> bool:
	if not can_activate_surge():
		return false
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
