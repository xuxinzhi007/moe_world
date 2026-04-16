extends Control

@onready var welcome_label: Label = $MainContainer/Header/Logo/WelcomeLabel
@onready var username_label: Label = $MainContainer/Header/UserInfo/UsernameLabel
@onready var enter_world_btn: Button = $MainContainer/GameModes/OfflineMode/VBoxContainer/EnterBtn
@onready var cloud_world_btn: Button = $MainContainer/GameModes/CloudMode/VBoxContainer/CloudBtn
@onready var cloud_room_edit: LineEdit = $MainContainer/GameModes/CloudMode/VBoxContainer/RoomEdit
@onready var profile_btn: Button = $MainContainer/Features/ProfileBtn
@onready var settings_btn: Button = $MainContainer/Features/SettingsBtn
@onready var logout_btn: Button = $MainContainer/Features/LogoutBtn
@onready var copyright_label: Label = $MainContainer/Footer/CopyrightLabel
@onready var settings_overlay: Control = $MainContainer/SettingsOverlay
@onready var bg_gradient: ColorRect = $BgGradient

var _cloud_wait_timer: SceneTreeTimer
var _cloud_pending: bool = false

var gradient_offset: float = 0.0


func _ready() -> void:
	_apply_theme()
	_refresh_welcome()
	enter_world_btn.pressed.connect(_on_enter_offline_clicked)
	cloud_world_btn.pressed.connect(_on_cloud_world_clicked)
	profile_btn.pressed.connect(_on_profile_clicked)
	settings_btn.pressed.connect(_on_settings_clicked)
	logout_btn.pressed.connect(_on_logout_clicked)
	
	get_tree().root.size_changed.connect(_on_window_resized)
	_on_window_resized()
	
	_play_intro_animation()


func _process(delta: float) -> void:
	gradient_offset += delta * 0.1
	if gradient_offset > 1.0:
		gradient_offset = 0.0
	
	var t = gradient_offset
	var col1 = _lerp_color(Color8(255, 243, 196), Color8(255, 230, 240), t)
	var col2 = _lerp_color(Color8(255, 230, 240), Color8(255, 243, 196), t)
	_set_gradient(col1, col2)


func _lerp_color(col1: Color, col2: Color, t: float) -> Color:
	return Color(
		col1.r + (col2.r - col1.r) * t,
		col1.g + (col2.g - col1.g) * t,
		col1.b + (col2.b - col1.b) * t
	)


func _set_gradient(col_top: Color, col_bottom: Color) -> void:
	var shader_material = bg_gradient.material as ShaderMaterial
	if shader_material:
		shader_material.set_shader_parameter("color_top", col_top)
		shader_material.set_shader_parameter("color_bottom", col_bottom)


func _refresh_welcome() -> void:
	var name_str := "萌酱"
	if ProjectSettings.has_setting("moe_world/current_user"):
		var u: Variant = ProjectSettings.get_setting("moe_world/current_user")
		if u is Dictionary and not (u as Dictionary).is_empty():
			name_str = str((u as Dictionary).get("username", "萌酱"))
	welcome_label.text = "欢迎回来，%s" % name_str
	username_label.text = name_str


func _apply_theme() -> void:
	var col_bg := Color8(255, 243, 196)
	var col_card := Color8(255, 230, 230)
	var col_btn := Color8(255, 102, 153)
	var col_btn_hover := Color8(255, 130, 175)
	var col_btn_pressed := Color8(230, 85, 130)
	var col_title := Color8(255, 102, 153)
	var col_muted := Color8(120, 90, 105)
	var col_text := Color8(75, 50, 62)

	var theme_obj := Theme.new()
	
	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = col_btn
	btn_style.corner_radius_top_left = 24
	btn_style.corner_radius_top_right = 24
	btn_style.corner_radius_bottom_left = 24
	btn_style.corner_radius_bottom_right = 24
	btn_style.content_margin_left = 20
	btn_style.content_margin_top = 14
	btn_style.content_margin_right = 20
	btn_style.content_margin_bottom = 14
	theme_obj.set_stylebox("normal", "Button", btn_style)
	
	var btn_hover := btn_style.duplicate()
	btn_hover.bg_color = col_btn_hover
	theme_obj.set_stylebox("hover", "Button", btn_hover)
	
	var btn_pressed := btn_style.duplicate()
	btn_pressed.bg_color = col_btn_pressed
	theme_obj.set_stylebox("pressed", "Button", btn_pressed)

	var card_style := StyleBoxFlat.new()
	card_style.bg_color = col_card
	card_style.border_color = Color8(255, 200, 210)
	card_style.set_border_width_all(2)
	card_style.corner_radius_top_left = 32
	card_style.corner_radius_top_right = 32
	card_style.corner_radius_bottom_left = 32
	card_style.corner_radius_bottom_right = 32
	card_style.shadow_color = Color(0, 0, 0, 0.1)
	card_style.shadow_size = 10
	card_style.shadow_offset = Vector2(0, 5)
	theme_obj.set_stylebox("panel", "PanelContainer", card_style)

	var line_edit_style := StyleBoxFlat.new()
	line_edit_style.bg_color = Color8(255, 255, 255)
	line_edit_style.border_color = Color8(255, 200, 210)
	line_edit_style.set_border_width_all(2)
	line_edit_style.corner_radius_top_left = 20
	line_edit_style.corner_radius_top_right = 20
	line_edit_style.corner_radius_bottom_left = 20
	line_edit_style.corner_radius_bottom_right = 20
	line_edit_style.content_margin_left = 16
	line_edit_style.content_margin_top = 12
	line_edit_style.content_margin_right = 16
	line_edit_style.content_margin_bottom = 12
	theme_obj.set_stylebox("normal", "LineEdit", line_edit_style)
	theme_obj.set_stylebox("focus", "LineEdit", line_edit_style)

	theme_obj.set_color("font_color", "Button", Color8(255, 255, 255))
	theme_obj.set_color("font_color", "Label", col_text)
	theme_obj.set_color("font_color", "LineEdit", col_text)
	theme_obj.set_color("placeholder_font_color", "LineEdit", col_muted)

	var title_label: Label = $MainContainer/Header/Logo/TitleLabel
	title_label.add_theme_font_size_override("font_size", 48)
	title_label.add_theme_color_override("font_color", col_title)
	welcome_label.add_theme_font_size_override("font_size", 18)
	welcome_label.add_theme_color_override("font_color", col_muted)
	username_label.add_theme_font_size_override("font_size", 16)
	username_label.add_theme_color_override("font_color", col_text)

	var offline_mode_title: Label = $MainContainer/GameModes/OfflineMode/VBoxContainer/ModeTitle
	var offline_mode_desc: Label = $MainContainer/GameModes/OfflineMode/VBoxContainer/ModeDesc
	var cloud_mode_title: Label = $MainContainer/GameModes/CloudMode/VBoxContainer/ModeTitle
	var cloud_mode_desc: Label = $MainContainer/GameModes/CloudMode/VBoxContainer/ModeDesc
	
	offline_mode_title.add_theme_font_size_override("font_size", 20)
	offline_mode_title.add_theme_color_override("font_color", col_title)
	offline_mode_desc.add_theme_font_size_override("font_size", 14)
	offline_mode_desc.add_theme_color_override("font_color", col_muted)
	cloud_mode_title.add_theme_font_size_override("font_size", 20)
	cloud_mode_title.add_theme_color_override("font_color", col_title)
	cloud_mode_desc.add_theme_font_size_override("font_size", 14)
	cloud_mode_desc.add_theme_color_override("font_color", col_muted)

	enter_world_btn.add_theme_font_size_override("font_size", 18)
	cloud_world_btn.add_theme_font_size_override("font_size", 18)
	profile_btn.add_theme_font_size_override("font_size", 16)
	settings_btn.add_theme_font_size_override("font_size", 16)
	logout_btn.add_theme_font_size_override("font_size", 16)
	copyright_label.add_theme_font_size_override("font_size", 14)
	copyright_label.add_theme_color_override("font_color", col_muted)
	cloud_room_edit.add_theme_font_size_override("font_size", 16)

	self.theme = theme_obj

	var avatar_panel: Panel = $MainContainer/Header/UserInfo/Avatar
	var avatar_style := StyleBoxFlat.new()
	avatar_style.bg_color = col_btn
	avatar_style.corner_radius_top_left = 40
	avatar_style.corner_radius_top_right = 40
	avatar_style.corner_radius_bottom_left = 40
	avatar_style.corner_radius_bottom_right = 40
	avatar_panel.add_theme_stylebox_override("panel", avatar_style)


func _on_window_resized() -> void:
	var screen_size = get_viewport().size
	var is_mobile = screen_size.x < 768
	
	# 调整网格容器列数
	var game_modes: GridContainer = $MainContainer/GameModes
	if is_mobile:
		game_modes.columns = 1
	else:
		game_modes.columns = 2
	
	# 调整字体大小以适应屏幕
	var font_scale = min(screen_size.x, screen_size.y) / 1080.0
	var title_size = int(48 * font_scale)
	var subtitle_size = int(18 * font_scale)
	var btn_size = int(18 * font_scale)
	var small_btn_size = int(16 * font_scale)
	var small_text_size = int(14 * font_scale)
	
	var title_label: Label = $MainContainer/Header/Logo/TitleLabel
	title_label.add_theme_font_size_override("font_size", title_size)
	welcome_label.add_theme_font_size_override("font_size", subtitle_size)
	username_label.add_theme_font_size_override("font_size", small_text_size)
	
	var offline_mode_title: Label = $MainContainer/GameModes/OfflineMode/VBoxContainer/ModeTitle
	var offline_mode_desc: Label = $MainContainer/GameModes/OfflineMode/VBoxContainer/ModeDesc
	var cloud_mode_title: Label = $MainContainer/GameModes/CloudMode/VBoxContainer/ModeTitle
	var cloud_mode_desc: Label = $MainContainer/GameModes/CloudMode/VBoxContainer/ModeDesc
	
	offline_mode_title.add_theme_font_size_override("font_size", int(20 * font_scale))
	offline_mode_desc.add_theme_font_size_override("font_size", small_text_size)
	cloud_mode_title.add_theme_font_size_override("font_size", int(20 * font_scale))
	cloud_mode_desc.add_theme_font_size_override("font_size", small_text_size)

	enter_world_btn.add_theme_font_size_override("font_size", btn_size)
	cloud_world_btn.add_theme_font_size_override("font_size", btn_size)
	profile_btn.add_theme_font_size_override("font_size", small_btn_size)
	settings_btn.add_theme_font_size_override("font_size", small_btn_size)
	logout_btn.add_theme_font_size_override("font_size", small_btn_size)
	copyright_label.add_theme_font_size_override("font_size", small_text_size)
	cloud_room_edit.add_theme_font_size_override("font_size", int(16 * font_scale))

	# 调整元素大小
	var container: VBoxContainer = $MainContainer
	container.offset_left = max(10, screen_size.x * 0.05)
	container.offset_right = max(-10, -screen_size.x * 0.05)
	container.offset_top = max(20, screen_size.y * 0.05)
	container.offset_bottom = max(-20, -screen_size.y * 0.05)


func _play_intro_animation() -> void:
	var game_modes: GridContainer = $MainContainer/GameModes
	var features: HBoxContainer = $MainContainer/Features
	
	game_modes.modulate.a = 0.0
	features.modulate.a = 0.0
	
	# 标题动画
	var title_label: Label = $MainContainer/Header/Logo/TitleLabel
	title_label.modulate.a = 0.0
	title_label.scale = Vector2(0.8, 0.8)
	
	var welcome_label: Label = $MainContainer/Header/Logo/WelcomeLabel
	welcome_label.modulate.a = 0.0
	
	var user_info: VBoxContainer = $MainContainer/Header/UserInfo
	user_info.modulate.a = 0.0
	user_info.position.x += 50
	
	# 标题动画
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(title_label, "modulate:a", 1.0, 0.6)
	tween.tween_property(title_label, "scale", Vector2(1.0, 1.0), 0.6)
	
	await get_tree().create_timer(0.3).timeout
	
	# 欢迎语动画
	tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(welcome_label, "modulate:a", 1.0, 0.5)
	
	# 用户信息动画
	tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(user_info, "modulate:a", 1.0, 0.5)
	tween.tween_property(user_info, "position:x", user_info.position.x - 50, 0.5)
	
	await get_tree().create_timer(0.4).timeout
	
	# 游戏模式动画
	tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(game_modes, "modulate:a", 1.0, 0.6)
	
	await get_tree().create_timer(0.2).timeout
	
	# 功能按钮动画
	tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(features, "modulate:a", 1.0, 0.6)


func _on_enter_offline_clicked() -> void:
	WorldNetwork.leave_session()
	get_tree().change_scene_to_file("res://Scenes/WorldScene.tscn")


func _on_cloud_world_clicked() -> void:
	var room := cloud_room_edit.text.strip_edges()
	if room.is_empty():
		room = "default"
	if WorldNetwork.cloud_ready.is_connected(_on_cloud_ready):
		WorldNetwork.cloud_ready.disconnect(_on_cloud_ready)
	if WorldNetwork.cloud_connection_failed.is_connected(_on_cloud_failed):
		WorldNetwork.cloud_connection_failed.disconnect(_on_cloud_failed)
	WorldNetwork.cloud_ready.connect(_on_cloud_ready, CONNECT_ONE_SHOT)
	WorldNetwork.cloud_connection_failed.connect(_on_cloud_failed, CONNECT_ONE_SHOT)
	var err: int = WorldNetwork.start_cloud(room)
	if err != OK:
		if WorldNetwork.cloud_ready.is_connected(_on_cloud_ready):
			WorldNetwork.cloud_ready.disconnect(_on_cloud_ready)
		if WorldNetwork.cloud_connection_failed.is_connected(_on_cloud_failed):
			WorldNetwork.cloud_connection_failed.disconnect(_on_cloud_failed)
		if err == ERR_UNAUTHORIZED:
			MoeDialogBus.show_dialog("需要登录", "云端联机需要登录后的 token。请退出并用账号登录一次。")
		else:
			MoeDialogBus.show_dialog("无法连接", "请确认已登录且保存了 API 地址；房间名仅允许字母、数字、下划线与短横线。错误码 %d。" % err)
		return
	_cloud_pending = true
	_cloud_wait_timer = get_tree().create_timer(15.0)
	_cloud_wait_timer.timeout.connect(_on_cloud_timeout, CONNECT_ONE_SHOT)


func _on_cloud_ready() -> void:
	if not _cloud_pending:
		return
	_cloud_pending = false
	if WorldNetwork.cloud_connection_failed.is_connected(_on_cloud_failed):
		WorldNetwork.cloud_connection_failed.disconnect(_on_cloud_failed)
	get_tree().change_scene_to_file("res://Scenes/WorldScene.tscn")


func _on_cloud_failed(_reason: String) -> void:
	if not _cloud_pending:
		return
	_cloud_pending = false
	if WorldNetwork.cloud_ready.is_connected(_on_cloud_ready):
		WorldNetwork.cloud_ready.disconnect(_on_cloud_ready)
	WorldNetwork.leave_session()
	MoeDialogBus.show_dialog("云端连接失败", "无法连上服务器 WebSocket。请确认后端已部署 /ws/world，且 ngrok 等代理支持 WebSocket。")


func _on_cloud_timeout() -> void:
	if not _cloud_pending:
		return
	_cloud_pending = false
	if WorldNetwork.cloud_ready.is_connected(_on_cloud_ready):
		WorldNetwork.cloud_ready.disconnect(_on_cloud_ready)
	if WorldNetwork.cloud_connection_failed.is_connected(_on_cloud_failed):
		WorldNetwork.cloud_connection_failed.disconnect(_on_cloud_failed)
	WorldNetwork.leave_session()
	MoeDialogBus.show_dialog("云端超时", "长时间未收到服务器欢迎包，请检查网络与 token。")


func _on_profile_clicked() -> void:
	get_tree().change_scene_to_file("res://Scenes/ProfileScene.tscn")


func _on_settings_clicked() -> void:
	if settings_overlay.has_method("open_settings"):
		settings_overlay.open_settings()


func _on_logout_clicked() -> void:
	WorldNetwork.leave_session()
	if ProjectSettings.has_setting("moe_world/current_user"):
		ProjectSettings.set_setting("moe_world/current_user", {})
	UserStorage.clear_session_file()
	get_tree().change_scene_to_file("res://Scenes/LoginScreen.tscn")
