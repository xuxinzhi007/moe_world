extends CharacterBody2D

const _FALLBACK_CHARACTER_PATH := "res://Assets/characters/拿刀武夫.png"
## 名牌底边与立绘顶边的间距（玩家本地坐标，y 向下为正）。
const _NAMEPLATE_GAP_ABOVE_VISUAL := 8.0
## 等级条底边与名牌顶边的间距。
const _LEVEL_CAPTION_GAP_ABOVE_NAME := 5.0

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


func _ready() -> void:
	add_to_group("player")
	collision_layer = 1
	collision_mask = 1
	z_as_relative = false
	_setup_visuals()
	_ensure_nameplate()
	_ensure_combat_caption()
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
	_level_exp_label.position = Vector2(-120, -102)
	_level_exp_label.custom_minimum_size = Vector2(240, 26)
	_level_exp_label.add_theme_font_size_override("font_size", 12)
	_level_exp_label.add_theme_color_override("font_color", Color8(255, 252, 240))
	_level_exp_label.add_theme_color_override("font_outline_color", Color8(35, 22, 38))
	_level_exp_label.add_theme_constant_override("outline_size", 5)
	_level_exp_label.z_index = 7
	_level_exp_label.z_as_relative = true
	_level_exp_label.text = "Lv.1  0/0 EXP"
	_level_exp_label.visible = not WorldNetwork.is_cloud()
	add_child(_level_exp_label)


func set_level_exp_caption(text: String) -> void:
	_ensure_combat_caption()
	_level_exp_label.text = text


func set_level_exp_visible(vis: bool) -> void:
	_ensure_combat_caption()
	_level_exp_label.visible = vis and not WorldNetwork.is_cloud()


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


## 立绘/序列帧在「玩家根节点」坐标系下的包围盒；用于把名牌、等级条摆在头顶上方。
func _visual_bounds_in_player_space() -> Rect2:
	var anim := get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if anim != null:
		return _xf_rect_to_player(anim, _animated_sprite_local_bounds(anim))
	var spr := get_node_or_null("CharacterSprite") as Sprite2D
	if spr != null and spr.texture != null:
		return _xf_rect_to_player(spr, spr.get_rect())
	return Rect2(-28.0, -88.0, 56.0, 88.0)


## AnimatedSprite2D 在 4.1 等版本无 get_rect()，用当前帧贴图尺寸 + offset 估算本地 AABB。
func _animated_sprite_local_bounds(anim: AnimatedSprite2D) -> Rect2:
	var sf := anim.sprite_frames
	if sf == null:
		return Rect2(-40.0, -120.0, 80.0, 120.0)
	var anim_key: StringName = anim.animation
	if anim_key.is_empty():
		var names := sf.get_animation_names()
		if names.is_empty():
			return Rect2(-40.0, -120.0, 80.0, 120.0)
		anim_key = names[0]
	if not sf.has_animation(anim_key):
		return Rect2(-40.0, -120.0, 80.0, 120.0)
	var tex: Texture2D = sf.get_frame_texture(anim_key, anim.frame)
	if tex == null:
		return Rect2(-40.0, -120.0, 80.0, 120.0)
	var sz: Vector2 = tex.get_size()
	var half: Vector2 = sz * 0.5
	# 与引擎绘制一致：以节点原点为中心，再平移 offset。
	return Rect2(-half + anim.offset, sz)


func _xf_rect_to_player(node: Node2D, r: Rect2) -> Rect2:
	var xf := node.get_transform()
	var corners: Array[Vector2] = [
		r.position,
		r.position + Vector2(r.size.x, 0.0),
		r.end,
		r.position + Vector2(0.0, r.size.y)
	]
	var mn := Vector2(1e9, 1e9)
	var mx := Vector2(-1e9, -1e9)
	for c in corners:
		var p: Vector2 = xf * c
		mn = mn.min(p)
		mx = mx.max(p)
	return Rect2(mn, mx - mn)


func _refresh_overhead_layout() -> void:
	if not is_instance_valid(_name_label):
		return
	var vr := _visual_bounds_in_player_space()
	if vr.size.y < 0.5 or vr.size.x < 0.5:
		return
	var head_top: float = vr.position.y
	var nm_h: float = maxf(18.0, _name_label.custom_minimum_size.y)
	var name_bottom: float = head_top - _NAMEPLATE_GAP_ABOVE_VISUAL
	var name_top: float = name_bottom - nm_h
	_name_label.position = Vector2(-80.0, name_top)
	if is_instance_valid(_level_exp_label):
		var lv_h: float = maxf(18.0, _level_exp_label.custom_minimum_size.y)
		var level_bottom: float = name_top - _LEVEL_CAPTION_GAP_ABOVE_NAME
		var level_top: float = level_bottom - lv_h
		_level_exp_label.position = Vector2(-120.0, level_top)


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
	## y 越大越靠前，保证与树/植物等装饰前后关系正确
	z_index = int(floor(global_position.y))

	if WorldNetwork.is_cloud() and str(name) == WorldNetwork.cloud_my_user_id:
		WorldNetwork.send_cloud_move(global_position)


func is_local_controllable() -> bool:
	return not _is_remote_player()


func _is_remote_player() -> bool:
	if WorldNetwork.is_cloud():
		return str(name) != WorldNetwork.cloud_my_user_id
	return false


func _process(_delta: float) -> void:
	if _is_remote_player():
		return
	if not get_tree().get_nodes_in_group("world_map_open").is_empty():
		return
	if Input.is_action_just_pressed("interact"):
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
