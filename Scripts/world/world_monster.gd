extends Node2D

## 史莱姆型小怪：追玩家、血条、待机动画 / 受击闪 / 死亡形变。

signal damaged(actual_damage: int, at_global: Vector2)
signal died(reward_xp: int, at_global: Vector2)

@export var max_hp: int = 40
@export var reward_xp: int = 18
@export var move_speed: float = 58.0
@export var aggro_range: float = 300.0
## 拖入 PNG / SVG / SpriteFrames 单帧等，替换默认史莱姆图。
@export var slime_visual_texture: Texture2D

var hp: int = 0
var _target: Node2D
var _dying: bool = false
var _bob_time: float = 0.0
var _bob_phase: float = 0.0
var _last_move: Vector2 = Vector2.ZERO
var _squash: Vector2 = Vector2.ONE

## --- 冲刺攻击状态机 ---
const CHARGE_RANGE: float = 90.0       ## 距离玩家此值时触发蓄力
const CHARGE_WINDUP: float = 0.28      ## 蓄力时间（玩家可见橙色膨胀）
const CHARGE_DURATION: float = 0.26    ## 冲刺持续时间
const CHARGE_SPEED_MULT: float = 4.8   ## 冲刺速度倍率
const CHARGE_COOLDOWN_SEC: float = 2.2 ## 每次冲刺后的冷却

var _cstate: int = 0        ## 0=正常 1=蓄力 2=冲刺
var _ctimer: float = 0.0    ## 当前阶段剩余时间
var _ccd: float = 0.0       ## 冲刺冷却倒计时
var _cdir: Vector2 = Vector2.ZERO

@onready var slime_root: Node2D = $SlimeRoot
@onready var body_sprite: Sprite2D = $SlimeRoot/BodySprite
@onready var hp_bar: ProgressBar = $HpBar

var _fill_style: StyleBoxFlat
var _hit_tween: Tween


func _ready() -> void:
	add_to_group("world_monster")
	z_as_relative = false
	_bob_phase = randf() * TAU
	hp = maxi(1, max_hp)
	_style_hp_bar()
	hp_bar.max_value = float(max_hp)
	hp_bar.value = float(hp)
	_update_hp_bar_visual()
	if slime_visual_texture != null:
		body_sprite.texture = slime_visual_texture
	body_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR


func set_aggro_target(t: Node2D) -> void:
	_target = t


func can_damage_player_on_contact() -> bool:
	return not _dying and hp > 0


func is_charge_attacking() -> bool:
	return _cstate == 2


## 与玩家的最小距离（软性排斥，防止完全叠加）
const PLAYER_SEPARATION: float = 28.0


func _style_hp_bar() -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.12, 0.1, 0.14, 0.92)
	bg.border_color = Color(0.42, 0.32, 0.38, 1.0)
	bg.set_border_width_all(1)
	bg.corner_radius_top_left = 4
	bg.corner_radius_top_right = 4
	bg.corner_radius_bottom_left = 4
	bg.corner_radius_bottom_right = 4
	hp_bar.add_theme_stylebox_override("background", bg)

	_fill_style = StyleBoxFlat.new()
	_fill_style.bg_color = _hp_fill_color(1.0)
	_fill_style.corner_radius_top_left = 2
	_fill_style.corner_radius_top_right = 2
	_fill_style.corner_radius_bottom_left = 2
	_fill_style.corner_radius_bottom_right = 2
	hp_bar.add_theme_stylebox_override("fill", _fill_style)


func _hp_fill_color(ratio: float) -> Color:
	ratio = clampf(ratio, 0.0, 1.0)
	var healthy := Color8(72, 210, 118)
	var danger := Color8(255, 92, 108)
	return healthy.lerp(danger, 1.0 - ratio)


func _update_hp_bar_visual() -> void:
	var ratio := 0.0
	if max_hp > 0:
		ratio = float(hp) / float(max_hp)
	if _fill_style:
		_fill_style.bg_color = _hp_fill_color(ratio)


func _refresh_hp_bar() -> void:
	hp_bar.max_value = float(maxi(1, max_hp))
	var tw := create_tween()
	tw.tween_property(hp_bar, "value", float(hp), 0.12).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_update_hp_bar_visual()


func _play_hit_feedback() -> void:
	if not is_instance_valid(slime_root):
		return
	if _hit_tween and _hit_tween.is_valid():
		_hit_tween.kill()
	_hit_tween = create_tween()
	slime_root.modulate = Color(1.35, 1.35, 1.45, 1.0)
	_hit_tween.tween_property(slime_root, "modulate", Color.WHITE, 0.14).set_ease(Tween.EASE_OUT)
	var shake := create_tween()
	var o := hp_bar.position
	shake.tween_property(hp_bar, "position", o + Vector2(3, 0), 0.04)
	shake.tween_property(hp_bar, "position", o - Vector2(2, 0), 0.04)
	shake.tween_property(hp_bar, "position", o, 0.05)


## 撞击玩家时向目标方向冲刺 + 橙色闪光弹回
func play_attack_anim(toward_dir: Vector2) -> void:
	if not is_instance_valid(slime_root) or _dying:
		return
	var lunge := toward_dir.normalized() * 10.0 if toward_dir.length_squared() > 0.01 else Vector2(0.0, -8.0)
	var orig_pos := slime_root.position
	var tw := create_tween().set_parallel(true)
	tw.tween_property(slime_root, "position", orig_pos + lunge, 0.08).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(slime_root, "modulate", Color(1.6, 0.75, 0.2, 1.0), 0.07)
	tw.tween_property(slime_root, "position", orig_pos, 0.20).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_BACK).set_delay(0.08)
	tw.tween_property(slime_root, "modulate", Color.WHITE, 0.22).set_delay(0.07)


func take_damage(amount: int) -> void:
	if is_queued_for_deletion() or _dying:
		return
	amount = maxi(1, amount)
	var prev_hp: int = hp
	hp = maxi(0, hp - amount)
	var dealt: int = prev_hp - hp
	if dealt > 0:
		damaged.emit(dealt, global_position)
	_refresh_hp_bar()
	_play_hit_feedback()
	if hp <= 0:
		_start_death()


func _start_death() -> void:
	_dying = true
	var rx: int = reward_xp
	var die_at: Vector2 = global_position
	var tw := create_tween().set_parallel(true)
	tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_property(slime_root, "scale", Vector2(1.28, 0.18), 0.32)
	tw.tween_property(slime_root, "rotation", slime_root.rotation + (PI * 0.12 if randf() > 0.5 else -PI * 0.12), 0.32)
	var tw2 := create_tween()
	tw2.tween_property(hp_bar, "modulate:a", 0.0, 0.2)
	tw2.tween_property(self, "modulate:a", 0.0, 0.38).set_delay(0.06)
	await tw.finished
	died.emit(rx, die_at)
	queue_free()


func _process(delta: float) -> void:
	if _dying:
		return
	z_index = int(floor(global_position.y))
	_bob_time += delta

	## -------- 冲刺状态机 --------
	_ccd = maxf(0.0, _ccd - delta)

	if _cstate == 1:
		## 蓄力：挤压膨胀，提示玩家"要冲了"
		_ctimer -= delta
		_squash = _squash.lerp(Vector2(1.5, 0.55), 14.0 * delta)
		if _ctimer <= 0.0:
			_cstate = 2
			_ctimer = CHARGE_DURATION
			slime_root.modulate = Color(1.7, 0.65, 0.12, 1.0)
	elif _cstate == 2:
		## 冲刺：快速移动，拉伸朝向
		_ctimer -= delta
		global_position += _cdir * move_speed * CHARGE_SPEED_MULT * delta
		var ang: float = _cdir.angle() + PI * 0.5
		slime_root.rotation = lerp_angle(slime_root.rotation, ang * 0.4, 18.0 * delta)
		_squash = _squash.lerp(Vector2(0.68, 1.45), 18.0 * delta)
		if _ctimer <= 0.0:
			_cstate = 0
			_ccd = CHARGE_COOLDOWN_SEC
			## 冲刺结束：弹回颜色
			create_tween().tween_property(slime_root, "modulate", Color.WHITE, 0.28)
	else:
		## 正常巡逻 / 追踪，检测是否进入蓄力范围
		var bob := sin(_bob_time * 3.2 + _bob_phase) * 2.2
		var breathe := 1.0 + sin(_bob_time * 2.0 + _bob_phase * 0.7) * 0.035
		var move_vec := Vector2.ZERO
		if _target != null and is_instance_valid(_target):
			var to_player: Vector2 = _target.global_position - global_position
			var dist: float = to_player.length()
			## 进入蓄力范围且冷却结束 → 开始蓄力
			if dist <= CHARGE_RANGE and dist > 14.0 and _ccd <= 0.0:
				_cstate = 1
				_ctimer = CHARGE_WINDUP
				_cdir = to_player.normalized()
				## 橙色膨胀警示
				var tw := create_tween().set_parallel(true)
				tw.tween_property(slime_root, "modulate", Color(1.8, 0.65, 0.1, 1.0), CHARGE_WINDUP * 0.55)
			elif dist <= PLAYER_SEPARATION:
				## 太近了 — 推离玩家，防止完全叠加
				global_position -= to_player.normalized() * move_speed * 0.55 * delta
				_last_move = Vector2.ZERO
			elif dist <= aggro_range and dist > 4.0:
				move_vec = to_player.normalized() * move_speed * delta
				global_position += move_vec
				_last_move = move_vec
			else:
				_last_move = Vector2.ZERO
		else:
			_last_move = Vector2.ZERO

		var speed := _last_move.length() / maxf(delta, 0.0001)
		var stretch := clampf(speed / 120.0, 0.0, 1.0)
		if move_vec.length_squared() > 0.0001:
			var dir := move_vec.normalized()
			var ang := dir.angle() + PI * 0.5
			slime_root.rotation = lerp_angle(slime_root.rotation, ang * 0.18, 6.0 * delta)
			_squash = _squash.lerp(Vector2(1.0 + stretch * 0.14, 1.0 - stretch * 0.1), 10.0 * delta)
		else:
			slime_root.rotation = lerp_angle(slime_root.rotation, 0.0, 5.0 * delta)
			_squash = _squash.lerp(Vector2.ONE * breathe, 4.0 * delta)

		slime_root.position.y = bob

	slime_root.scale = _squash
