extends Node

## 单机成长：属性点、攻速/移速加成、强击（下一击增伤 + 冷却）。持久化到 user://。

const SAVE_PATH := "user://character_build.cfg"

signal build_changed()

var unspent_points: int = 2
var atk_speed_level: int = 0
var move_level: int = 0

var _surge_cooldown: float = 0.0
var _stored_melee_multiplier: float = 1.0
var _had_surge_cd: bool = false


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


func _save() -> void:
	var cf := ConfigFile.new()
	cf.set_value("build", "unspent", unspent_points)
	cf.set_value("build", "atk_speed_level", atk_speed_level)
	cf.set_value("build", "move_level", move_level)
	cf.save(SAVE_PATH)


func grant_points_for_levels(levels_gained: int) -> void:
	if levels_gained <= 0:
		return
	unspent_points += levels_gained
	_save()
	build_changed.emit()


func melee_cooldown_multiplier() -> float:
	# 等级越高冷却越短
	return 1.0 / (1.0 + 0.055 * float(atk_speed_level))


func move_speed_multiplier() -> float:
	return 1.0 + 0.045 * float(move_level)


func try_spend_attack_speed() -> bool:
	if unspent_points <= 0:
		return false
	unspent_points -= 1
	atk_speed_level += 1
	_save()
	build_changed.emit()
	return true


func try_spend_move_speed() -> bool:
	if unspent_points <= 0:
		return false
	unspent_points -= 1
	move_level += 1
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
