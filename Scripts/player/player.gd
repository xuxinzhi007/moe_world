extends CharacterBody2D

const _FALLBACK_CHARACTER_PATH := "res://Assets/characters/拿刀武夫.png"
const _NAME_TO_HP_GAP := 3.0
const _HP_TO_EXP_GAP := 2.0

@export var move_speed: float = 200.0
@export var player_color: Color = Color(0.3, 0.6, 1, 1)
## 角色展示用图（PNG / SVG / 图集单帧等）；可在 Player 场景里指定，留空则从路径加载内置立绘。
@export var character_texture: Texture2D
## 立绘在世界中的目标高度（像素）；不同分辨率角色图会按这个高度自动缩放。
@export_range(48.0, 240.0, 2.0) var character_target_height: float = 108.0
## 与 player_color 混合程度；0 保留原画色彩，1 完全乘上色。
@export_range(0.0, 1.0, 0.05) var character_color_tint_strength: float = 0.0

var is_in_dialog: bool = false
var nearby_npcs: Array = []

var mobile_input_dir: Vector2 = Vector2.ZERO
var use_mobile_controls: bool = false

var _sync_pos: Vector2 = Vector2.ZERO
var _name_label: Label
var _level_exp_label: Label
var _overhead_hp_bar: ProgressBar
var _overhead_hp_value: Label
var _overhead_exp_bar: ProgressBar
## 动画基准 scale/offset — 在 _setup_visuals 之后记录，防止 tween kill 导致累积变形
var _base_scale: Vector2 = Vector2.ONE
var _base_offset: Vector2 = Vector2.ZERO


func _ready() -> void:
	add_to_group("player")
	collision_layer = 1
	collision_mask = 1
	z_as_relative = false
	_setup_visuals()
	## 记录视觉节点的初始 scale/offset，供动画函数使用
	var spr_init := _get_visual_node()
	if is_instance_valid(spr_init):
		_base_scale = spr_init.scale
		_initial_scale = spr_init.scale
		if spr_init is Sprite2D:
			_base_offset = (spr_init as Sprite2D).offset
		elif spr_init is AnimatedSprite2D:
			_base_offset = (spr_init as AnimatedSprite2D).offset
	_ensure_nameplate()
	_ensure_combat_caption()
	_ensure_overhead_hp_bar()
	_ensure_overhead_exp_bar()
	_sync_pos = global_position
	_refresh_overhead_layout()


func _ensure_nameplate() -> void:
	if is_instance_valid(_name_label):
		return
	_name_label = Label.new()
	_name_label.name = "Nameplate"
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_name_label.position = Vector2(-80, -56)
	_name_label.custom_minimum_size = Vector2(160, 22)
	_name_label.add_theme_font_size_override("font_size", 15)
	_name_label.add_theme_color_override("font_color", Color8(75, 50, 62))
	_name_label.add_theme_color_override("font_outline_color", Color8(255, 248, 252))
	_name_label.add_theme_constant_override("outline_size", 4)
	_name_label.z_index = 6
	_name_label.z_as_relative = true
	add_child(_name_label)


func set_display_name(text: String) -> void:
	_ensure_nameplate()
	var label_text := text.strip_edges()
	if label_text.is_empty():
		label_text = str(name)
	_name_label.text = label_text


func _ensure_combat_caption() -> void:
	if is_instance_valid(_level_exp_label):
		return
	_level_exp_label = Label.new()
	_level_exp_label.name = "LevelExpOverhead"
	_level_exp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_level_exp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_level_exp_label.position = Vector2(-90, -104)
	_level_exp_label.custom_minimum_size = Vector2(36, 18)
	_level_exp_label.add_theme_font_size_override("font_size", 10)
	_level_exp_label.add_theme_color_override("font_color", Color8(255, 252, 240))
	_level_exp_label.add_theme_color_override("font_outline_color", Color8(35, 22, 38))
	_level_exp_label.add_theme_constant_override("outline_size", 3)
	_level_exp_label.z_index = 7
	_level_exp_label.z_as_relative = true
	_level_exp_label.text = "Lv.1"
	_level_exp_label.visible = not WorldNetwork.is_cloud()
	add_child(_level_exp_label)


func _ensure_overhead_hp_bar() -> void:
	if is_instance_valid(_overhead_hp_bar):
		return
	_overhead_hp_bar = ProgressBar.new()
	_overhead_hp_bar.name = "OverheadHpBar"
	_overhead_hp_bar.min_value = 0.0
	_overhead_hp_bar.max_value = 100.0
	_overhead_hp_bar.value = 100.0
	_overhead_hp_bar.show_percentage = false
	_overhead_hp_bar.custom_minimum_size = Vector2(124, 11)
	_overhead_hp_bar.position = Vector2(-52.0, -122.0)
	_overhead_hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overhead_hp_bar.z_index = 8
	_overhead_hp_bar.z_as_relative = true
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.10, 0.08, 0.16, 0.88)
	bg.corner_radius_top_left = 6
	bg.corner_radius_top_right = 6
	bg.corner_radius_bottom_left = 6
	bg.corner_radius_bottom_right = 6
	bg.set_border_width_all(1)
	bg.border_color = Color(0.40, 0.30, 0.56, 0.82)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.97, 0.37, 0.46, 0.96)
	fill.corner_radius_top_left = 5
	fill.corner_radius_top_right = 5
	fill.corner_radius_bottom_left = 5
	fill.corner_radius_bottom_right = 5
	_overhead_hp_bar.add_theme_stylebox_override("background", bg)
	_overhead_hp_bar.add_theme_stylebox_override("fill", fill)
	add_child(_overhead_hp_bar)
	_overhead_hp_value = Label.new()
	_overhead_hp_value.name = "HpValue"
	_overhead_hp_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_overhead_hp_value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_overhead_hp_value.custom_minimum_size = _overhead_hp_bar.custom_minimum_size
	_overhead_hp_value.position = Vector2.ZERO
	_overhead_hp_value.add_theme_font_size_override("font_size", 9)
	_overhead_hp_value.add_theme_color_override("font_color", Color8(255, 247, 253))
	_overhead_hp_value.add_theme_color_override("font_outline_color", Color8(30, 16, 36))
	_overhead_hp_value.add_theme_constant_override("outline_size", 3)
	_overhead_hp_value.text = "100/100"
	_overhead_hp_bar.add_child(_overhead_hp_value)


func set_overhead_hp(current_hp: int, max_hp: int, show_bar: bool = true) -> void:
	_ensure_overhead_hp_bar()
	var mx: int = maxi(1, max_hp)
	var cur: int = clampi(current_hp, 0, mx)
	_overhead_hp_bar.max_value = float(mx)
	_overhead_hp_bar.value = float(cur)
	_overhead_hp_value.text = "%d/%d" % [cur, mx]
	_overhead_hp_bar.visible = show_bar and not WorldNetwork.is_cloud()
	var ratio := float(cur) / float(mx)
	var fill := _overhead_hp_bar.get_theme_stylebox("fill") as StyleBoxFlat
	if is_instance_valid(fill):
		fill.bg_color = Color(0.97, 0.37, 0.46, 0.96).lerp(Color(0.35, 0.88, 0.52, 0.96), ratio)


func _ensure_overhead_exp_bar() -> void:
	if is_instance_valid(_overhead_exp_bar):
		return
	_overhead_exp_bar = ProgressBar.new()
	_overhead_exp_bar.name = "OverheadExpBar"
	_overhead_exp_bar.min_value = 0.0
	_overhead_exp_bar.max_value = 100.0
	_overhead_exp_bar.value = 0.0
	_overhead_exp_bar.show_percentage = false
	_overhead_exp_bar.custom_minimum_size = Vector2(124, 7)
	_overhead_exp_bar.position = Vector2(-52.0, -106.0)
	_overhead_exp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overhead_exp_bar.z_index = 8
	_overhead_exp_bar.z_as_relative = true
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.11, 0.09, 0.18, 0.86)
	bg.corner_radius_top_left = 4
	bg.corner_radius_top_right = 4
	bg.corner_radius_bottom_left = 4
	bg.corner_radius_bottom_right = 4
	bg.set_border_width_all(1)
	bg.border_color = Color(0.28, 0.30, 0.52, 0.82)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.42, 0.78, 1.0, 0.96)
	fill.corner_radius_top_left = 3
	fill.corner_radius_top_right = 3
	fill.corner_radius_bottom_left = 3
	fill.corner_radius_bottom_right = 3
	_overhead_exp_bar.add_theme_stylebox_override("background", bg)
	_overhead_exp_bar.add_theme_stylebox_override("fill", fill)
	add_child(_overhead_exp_bar)


func set_level_exp_progress(level: int, current_exp: int, next_exp: int) -> void:
	_ensure_combat_caption()
	_ensure_overhead_exp_bar()
	var lv: int = maxi(1, level)
	var nx: int = maxi(1, next_exp)
	var cur: int = clampi(current_exp, 0, nx)
	_level_exp_label.text = "Lv.%d" % lv
	_overhead_exp_bar.max_value = float(nx)
	_overhead_exp_bar.value = float(cur)


func set_level_exp_caption(text: String) -> void:
	_ensure_combat_caption()
	_level_exp_label.text = text


func set_level_exp_visible(vis: bool) -> void:
	_ensure_combat_caption()
	_level_exp_label.visible = vis and not WorldNetwork.is_cloud()
	if is_instance_valid(_overhead_hp_bar):
		_overhead_hp_bar.visible = vis and not WorldNetwork.is_cloud()
	if is_instance_valid(_overhead_exp_bar):
		_overhead_exp_bar.visible = vis and not WorldNetwork.is_cloud()


func _setup_visuals() -> void:
	# 若场景里已放 AnimatedSprite2D（编辑器摆序列帧），则不再用代码新建 Sprite2D，避免叠两层图。
	var anim_spr := get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if anim_spr != null:
		anim_spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		anim_spr.z_index = 1
		var tint_anim := Color.WHITE.lerp(player_color, character_color_tint_strength)
		anim_spr.modulate = tint_anim
	else:
		var tex: Texture2D = character_texture
		if tex == null and ResourceLoader.exists(_FALLBACK_CHARACTER_PATH):
			var loaded := ResourceLoader.load(_FALLBACK_CHARACTER_PATH)
			if loaded is Texture2D:
				tex = loaded as Texture2D
		if tex != null:
			var spr := Sprite2D.new()
			spr.name = "CharacterSprite"
			spr.texture = tex
			spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			spr.centered = true
			spr.offset = Vector2(0, -30)
			var h: float = maxf(1.0, float(tex.get_height()))
			var s: float = clampf(character_target_height / h, 0.08, 3.0)
			spr.scale = Vector2.ONE * s
			spr.z_index = 1
			var tint := Color.WHITE.lerp(player_color, character_color_tint_strength)
			spr.modulate = tint
			add_child(spr)
		else:
			push_warning("Player: 未设置 character_texture 且无法加载 %s" % _FALLBACK_CHARACTER_PATH)
	# 场景里已有 CollisionShape2D 时不再添加，避免双碰撞体。
	if get_node_or_null("CollisionShape2D") == null:
		var collision_shape := CollisionShape2D.new()
		collision_shape.name = "CollisionShape2D"
		var rect_shape := RectangleShape2D.new()
		rect_shape.size = Vector2(34, 44)
		collision_shape.shape = rect_shape
		collision_shape.position = Vector2(0, -10)
		add_child(collision_shape)
	_refresh_overhead_layout()


## 头顶 UI 使用稳定锚点：基于静态贴图尺寸 + 初始缩放，避免攻击动画的 offset/scale 抖动传导到 UI。


func _refresh_overhead_layout() -> void:
	if not is_instance_valid(_name_label):
		return
	var head_top: float = _stable_head_top_local()
	var bars_left := -52.0
	var hp_h: float = maxf(11.0, _overhead_hp_bar.custom_minimum_size.y) if is_instance_valid(_overhead_hp_bar) else 11.0
	var exp_h: float = maxf(7.0, _overhead_exp_bar.custom_minimum_size.y) if is_instance_valid(_overhead_exp_bar) else 7.0
	var hp_top: float = head_top - (hp_h + exp_h + _HP_TO_EXP_GAP) * 0.5
	var exp_top: float = hp_top + hp_h + _HP_TO_EXP_GAP
	if is_instance_valid(_overhead_hp_bar):
		_overhead_hp_bar.position = Vector2(bars_left, hp_top)
	if is_instance_valid(_overhead_exp_bar):
		_overhead_exp_bar.position = Vector2(bars_left, exp_top)
	if is_instance_valid(_level_exp_label):
		var lv_h: float = maxf(16.0, _level_exp_label.custom_minimum_size.y)
		var lv_center_y: float = hp_top + (hp_h + _HP_TO_EXP_GAP + exp_h) * 0.5
		_level_exp_label.position = Vector2(bars_left - 40.0, lv_center_y - lv_h * 0.5)
	var nm_h: float = maxf(18.0, _name_label.custom_minimum_size.y)
	var name_top: float = hp_top - _NAME_TO_HP_GAP - nm_h
	_name_label.position = Vector2(-64.0, name_top)


func _stable_head_top_local() -> float:
	var anim := get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if anim != null:
		var tex: Texture2D = anim.sprite_frames.get_frame_texture(anim.animation, anim.frame) if anim.sprite_frames != null and anim.sprite_frames.has_animation(anim.animation) else null
		if tex != null:
			var sz := tex.get_size()
			return _base_offset.y - 0.5 * sz.y * absf(_initial_scale.y)
	var spr := get_node_or_null("CharacterSprite") as Sprite2D
	if spr != null and spr.texture != null:
		var ssz := spr.texture.get_size()
		return _base_offset.y - 0.5 * ssz.y * absf(_initial_scale.y)
	return -88.0


func apply_remote_visual() -> void:
	var spr := get_node_or_null("CharacterSprite") as Sprite2D
	if spr:
		spr.modulate = Color(0.98, 0.55, 0.74, 1.0)
		return
	var anim := get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if anim:
		anim.modulate = Color(0.98, 0.55, 0.74, 1.0)


func apply_sync_position(pos: Vector2) -> void:
	_sync_pos = pos


func set_mobile_input(direction: Vector2) -> void:
	mobile_input_dir = direction
	use_mobile_controls = true


func _physics_process(_delta: float) -> void:
	_refresh_overhead_layout()
	if _is_remote_player():
		global_position = global_position.lerp(_sync_pos, clampf(14.0 * _delta, 0.0, 1.0))
		velocity = Vector2.ZERO
		return

	if is_in_dialog:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var input_dir := Vector2.ZERO
	if use_mobile_controls:
		input_dir = mobile_input_dir
	else:
		input_dir.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
		input_dir.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")

	if input_dir != Vector2.ZERO:
		input_dir = input_dir.normalized()

	velocity = input_dir * move_speed * CharacterBuild.move_speed_multiplier()
	move_and_slide()
	_update_facing(velocity.x)

	if WorldNetwork.is_cloud() and str(name) == WorldNetwork.cloud_my_user_id:
		WorldNetwork.send_cloud_move(global_position)


func is_local_controllable() -> bool:
	return not _is_remote_player()


func _is_remote_player() -> bool:
	if WorldNetwork.is_cloud():
		return str(name) != WorldNetwork.cloud_my_user_id
	return false


func _process(_delta: float) -> void:
	## 每帧以插值后的视觉坐标更新 z_index（物理插值开启时 global_position 在 _process 里
	## 返回的是插值后位置，能与画面视觉完全同步；+22 以脚底为基准，保证站在装饰物上时玩家显示在前面）
	z_index = int(floor(global_position.y + 22))
	if _is_remote_player():
		return
	if not get_tree().get_nodes_in_group("world_map_open").is_empty():
		return
	if Input.is_action_just_pressed("interact"):
		var ws: Node = get_tree().get_first_node_in_group("world_scene")
		if ws != null and ws.has_method("try_interact_survivor_portal") and bool(ws.call("try_interact_survivor_portal")):
			return
		_try_interact_with_npc()


func try_interact_nearby() -> void:
	if _is_remote_player():
		return
	_try_interact_with_npc()


func _try_interact_with_npc() -> void:
	if is_in_dialog:
		return
	if MoeDialogBus.is_dialog_open():
		return
	if nearby_npcs.is_empty():
		return
	var nearest_npc: Node2D = nearby_npcs[0]
	for npc in nearby_npcs:
		if (global_position - (npc as Node2D).global_position).length() < (global_position - nearest_npc.global_position).length():
			nearest_npc = npc
	if nearest_npc and nearest_npc.has_method("try_interact"):
		nearest_npc.try_interact()


var _anim_tween: Tween = null
## 当前朝向，true = 面朝右（+X），false = 面朝左。初始与立绘素材默认朝向一致（向右）。
var _facing_right: bool = true
## 立绘初始 scale（_ready 时记录，不含朝向翻转）；朝向翻转通过调整 _base_scale.x 实现，
## 以保证攻击/受伤 tween 在翻转后仍以正确基准做形变。
var _initial_scale: Vector2 = Vector2.ONE


## 攻击时前冲 + 挤压弹回动画（不修改碰撞体位置，只动视觉 offset + scale）
func play_attack_animation(attack_dir: Vector2 = Vector2.ZERO) -> void:
	var spr := _get_visual_node()
	if not is_instance_valid(spr):
		return
	var lunge_dir := attack_dir.normalized() if attack_dir.length_squared() > 0.01 else Vector2(1.0, 0.0)
	var lunge := lunge_dir * 14.0
	if is_instance_valid(_anim_tween):
		_anim_tween.kill()
	## 先强制归位，避免 kill 后残留变形
	spr.scale = _base_scale
	if spr is Sprite2D:
		(spr as Sprite2D).offset = _base_offset
	elif spr is AnimatedSprite2D:
		(spr as AnimatedSprite2D).offset = _base_offset
	_anim_tween = create_tween().set_parallel(true)
	_anim_tween.tween_property(spr, "offset", _base_offset + lunge, 0.07).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_anim_tween.tween_property(spr, "scale", _base_scale * Vector2(1.18, 0.84), 0.07).set_ease(Tween.EASE_OUT)
	_anim_tween.tween_property(spr, "offset", _base_offset, 0.18).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_BACK).set_delay(0.07)
	_anim_tween.tween_property(spr, "scale", _base_scale, 0.20).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC).set_delay(0.07)
	## 保底归位，防止 tween 被中断时残留变形
	_anim_tween.tween_callback(_force_reset_visual).set_delay(0.30)


## 受伤时红闪 + 轻微收缩反弹
func play_hurt_animation() -> void:
	var spr := _get_visual_node()
	if not is_instance_valid(spr):
		return
	if is_instance_valid(_anim_tween):
		_anim_tween.kill()
	## 先强制归位，避免 kill 后残留变形
	spr.scale = _base_scale
	_anim_tween = create_tween().set_parallel(true)
	spr.modulate = Color(1.6, 0.28, 0.28, 1.0)
	_anim_tween.tween_property(spr, "modulate", Color.WHITE, 0.22).set_ease(Tween.EASE_OUT)
	_anim_tween.tween_property(spr, "scale", _base_scale * Vector2(0.88, 1.12), 0.07).set_ease(Tween.EASE_OUT)
	_anim_tween.tween_property(spr, "scale", _base_scale, 0.16).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC).set_delay(0.07)
	## 保底归位
	_anim_tween.tween_callback(_force_reset_visual).set_delay(0.28)


func _force_reset_visual() -> void:
	var spr := _get_visual_node()
	if not is_instance_valid(spr):
		return
	spr.scale = _base_scale
	spr.modulate = Color.WHITE
	if spr is Sprite2D:
		(spr as Sprite2D).offset = _base_offset
	elif spr is AnimatedSprite2D:
		(spr as AnimatedSprite2D).offset = _base_offset


func _get_visual_node() -> CanvasItem:
	var anim := get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if is_instance_valid(anim):
		return anim
	var spr2d := get_node_or_null("CharacterSprite") as Sprite2D
	if is_instance_valid(spr2d):
		return spr2d
	return null


## 根据水平速度更新立绘朝向；速度接近 0 时保持上一次方向不变，防止站立时抖动。
## 只更改 _base_scale.x 的符号——攻击/受伤 tween 以 _base_scale 为基准形变，翻转后仍正确。
func _update_facing(vx: float) -> void:
	if abs(vx) < 8.0:
		return
	var want_right := vx > 0.0
	if want_right == _facing_right:
		return
	_facing_right = want_right
	var sign_x := 1.0 if _facing_right else -1.0
	_base_scale = _initial_scale * Vector2(sign_x, 1.0)
	## 没有攻击动画运行时立即应用；运行中等 tween 自然结束后 _force_reset_visual 会用新 _base_scale
	if not (is_instance_valid(_anim_tween) and _anim_tween.is_running()):
		var spr := _get_visual_node()
		if is_instance_valid(spr):
			spr.scale = _base_scale


func add_nearby_npc(npc: Node) -> void:
	if not nearby_npcs.has(npc):
		nearby_npcs.append(npc)


func remove_nearby_npc(npc: Node) -> void:
	if nearby_npcs.has(npc):
		nearby_npcs.erase(npc)


func start_dialog() -> void:
	is_in_dialog = true


func end_dialog() -> void:
	is_in_dialog = false
