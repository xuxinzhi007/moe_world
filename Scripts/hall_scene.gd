extends Control

const UITheme = preload("res://Scripts/ui_theme.gd")
const LOGIN_SCENE := preload("res://Scenes/LoginScreen.tscn")

@onready var player_name_label: Label = $MainContainer/PlayerInfoBar/PlayerInfoContent/PlayerDetails/PlayerName
@onready var online_time_label: Label = $MainContainer/PlayerInfoBar/PlayerInfoContent/PlayerDetails/OnlineTime
@onready var avatar_initial: Label = $MainContainer/PlayerInfoBar/PlayerInfoContent/AvatarBtn/AvatarCircle/AvatarInitial
@onready var vip_badge: Label = $MainContainer/PlayerInfoBar/PlayerInfoContent/AvatarBtn/VIPBadge
@onready var recent_btn: Button = $MainContainer/PlayerInfoBar/PlayerInfoContent/QuickAccess/RecentBtn
@onready var friends_btn: Button = $MainContainer/PlayerInfoBar/PlayerInfoContent/QuickAccess/FriendsBtn
@onready var notice_btn: Button = $MainContainer/PlayerInfoBar/PlayerInfoContent/QuickAccess/NoticeBtn
@onready var enter_world_btn: Button = $MainContainer/GameModesSection/GameModesGrid/OfflineModeCard/OfflineCardContent/EnterBtn
@onready var cloud_world_btn: Button = $MainContainer/GameModesSection/GameModesGrid/CloudModeCard/CloudCardContent/CloudBtn
@onready var cloud_room_edit: LineEdit = $MainContainer/GameModesSection/GameModesGrid/CloudModeCard/CloudCardContent/RoomEdit
@onready var profile_btn: Button = $MainContainer/FeaturesSection/ProfileBtn
@onready var settings_btn: Button = $MainContainer/FeaturesSection/SettingsBtn
@onready var login_btn: Button = $MainContainer/FeaturesSection/LoginBtn
@onready var logout_btn: Button = $MainContainer/FeaturesSection/LogoutBtn
@onready var copyright_label: Label = $MainContainer/FooterSection/CopyrightLabel
@onready var settings_overlay: Control = $MainContainer/SettingsOverlay
@onready var bg_gradient: ColorRect = $BgGradient

var _cloud_wait_timer: SceneTreeTimer
var _cloud_pending: bool = false
var _online_time_seconds: int = 0
var gradient_offset: float = 0.0
var _is_mobile: bool = false
var _login_overlay_layer: CanvasLayer
var _pending_cloud_room: String = ""


func _ready() -> void:
	_apply_theme()
	_refresh_player_info()
	_setup_button_connections()
	_start_online_timer()
	
	get_tree().root.size_changed.connect(_on_window_resized)
	_on_window_resized()
	
	_play_intro_animation()


func _process(delta: float) -> void:
	gradient_offset += delta * 0.05
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


func _setup_button_connections() -> void:
	enter_world_btn.pressed.connect(_on_enter_offline_clicked)
	cloud_world_btn.pressed.connect(_on_cloud_world_clicked)
	profile_btn.pressed.connect(_on_profile_clicked)
	settings_btn.pressed.connect(_on_settings_clicked)
	login_btn.pressed.connect(_on_login_btn_clicked)
	logout_btn.pressed.connect(_on_logout_clicked)
	recent_btn.pressed.connect(_on_recent_clicked)
	friends_btn.pressed.connect(_on_friends_clicked)
	notice_btn.pressed.connect(_on_notice_clicked)
	
	_setup_button_hover_effect(enter_world_btn)
	_setup_button_hover_effect(cloud_world_btn)
	_setup_button_hover_effect(profile_btn)
	_setup_button_hover_effect(settings_btn)
	_setup_button_hover_effect(login_btn)
	_setup_button_hover_effect(logout_btn)


func _setup_button_hover_effect(btn: Button) -> void:
	if btn:
		btn.mouse_entered.connect(func(): _on_button_hover_enter(btn))
		btn.mouse_exited.connect(func(): _on_button_hover_exit(btn))


func _on_button_hover_enter(btn: Button) -> void:
	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(btn, "scale", Vector2(1.05, 1.05), 0.2)


func _on_button_hover_exit(btn: Button) -> void:
	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.2)


func _refresh_player_info() -> void:
	var name_str := "萌酱"
	var vip_level := 0
	
	if ProjectSettings.has_setting("moe_world/current_user"):
		var u: Variant = ProjectSettings.get_setting("moe_world/current_user")
		if u is Dictionary and not (u as Dictionary).is_empty():
			name_str = str((u as Dictionary).get("username", "萌酱"))
			vip_level = int((u as Dictionary).get("vip_level", 0))
	
	player_name_label.text = name_str
	avatar_initial.text = name_str.substr(0, 1) if name_str.length() > 0 else "萌"
	
	if vip_level > 0:
		vip_badge.visible = true
		vip_badge.text = "VIP %d" % vip_level
	else:
		vip_badge.visible = false
	
	_update_auth_buttons()


func _is_logged_in() -> bool:
	if not ProjectSettings.has_setting("moe_world/current_user"):
		return false
	var u: Variant = ProjectSettings.get_setting("moe_world/current_user")
	if not u is Dictionary:
		return false
	var d: Dictionary = u as Dictionary
	if d.is_empty():
		return false
	return not str(d.get("token", "")).strip_edges().is_empty()


func _update_auth_buttons() -> void:
	var logged := _is_logged_in()
	login_btn.visible = not logged
	logout_btn.visible = logged


func _start_online_timer() -> void:
	_online_time_seconds = 0
	var timer := Timer.new()
	timer.wait_time = 1.0
	timer.timeout.connect(func():
		_online_time_seconds += 1
		var minutes := _online_time_seconds / 60
		online_time_label.text = "在线: %d分钟" % minutes
	)
	add_child(timer)
	timer.start()


func _apply_theme() -> void:
	var theme_obj := Theme.new()
	
	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = Color8(255, 102, 153)
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
	btn_hover.bg_color = Color8(255, 130, 175)
	theme_obj.set_stylebox("hover", "Button", btn_hover)
	
	var btn_pressed := btn_style.duplicate()
	btn_pressed.bg_color = Color8(230, 85, 130)
	theme_obj.set_stylebox("pressed", "Button", btn_pressed)

	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color8(255, 230, 230)
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

	var input_style := StyleBoxFlat.new()
	input_style.bg_color = Color8(255, 255, 255)
	input_style.border_color = Color8(255, 200, 210)
	input_style.set_border_width_all(2)
	input_style.corner_radius_top_left = 20
	input_style.corner_radius_top_right = 20
	input_style.corner_radius_bottom_left = 20
	input_style.corner_radius_bottom_right = 20
	input_style.content_margin_left = 16
	input_style.content_margin_top = 12
	input_style.content_margin_right = 16
	input_style.content_margin_bottom = 12
	theme_obj.set_stylebox("normal", "LineEdit", input_style)
	theme_obj.set_stylebox("focus", "LineEdit", input_style)

	theme_obj.set_color("font_color", "Button", Color8(255, 255, 255))
	theme_obj.set_color("font_color", "Label", Color8(75, 50, 62))
	theme_obj.set_color("font_color", "LineEdit", Color8(75, 50, 62))
	theme_obj.set_color("placeholder_font_color", "LineEdit", Color8(120, 90, 105))

	self.theme = theme_obj

	var avatar_circle: Panel = $MainContainer/PlayerInfoBar/PlayerInfoContent/AvatarBtn/AvatarCircle
	var avatar_style := StyleBoxFlat.new()
	avatar_style.bg_color = Color8(255, 102, 153)
	avatar_style.corner_radius_top_left = 24
	avatar_style.corner_radius_top_right = 24
	avatar_style.corner_radius_bottom_left = 24
	avatar_style.corner_radius_bottom_right = 24
	avatar_circle.add_theme_stylebox_override("panel", avatar_style)

	var quick_btn_style := StyleBoxFlat.new()
	quick_btn_style.bg_color = Color8(255, 240, 245)
	quick_btn_style.border_color = Color8(255, 200, 210)
	quick_btn_style.set_border_width_all(1)
	quick_btn_style.corner_radius_top_left = 12
	quick_btn_style.corner_radius_top_right = 12
	quick_btn_style.corner_radius_bottom_left = 12
	quick_btn_style.corner_radius_bottom_right = 12
	recent_btn.add_theme_stylebox_override("normal", quick_btn_style)
	friends_btn.add_theme_stylebox_override("normal", quick_btn_style.duplicate())
	notice_btn.add_theme_stylebox_override("normal", quick_btn_style.duplicate())


func _on_window_resized() -> void:
	var screen_size = get_viewport().size
	_is_mobile = screen_size.x < 768
	
	var game_modes_grid: GridContainer = $MainContainer/GameModesSection/GameModesGrid
	if _is_mobile:
		game_modes_grid.columns = 1
	else:
		game_modes_grid.columns = 2
	
	var font_scale = min(screen_size.x, screen_size.y) / 1080.0
	var title_size = int(24 * font_scale)
	var body_size = int(16 * font_scale)
	var caption_size = int(14 * font_scale)
	
	player_name_label.add_theme_font_size_override("font_size", title_size)
	online_time_label.add_theme_font_size_override("font_size", caption_size)
	
	var section_title: Label = $MainContainer/GameModesSection/SectionTitle
	section_title.add_theme_font_size_override("font_size", int(20 * font_scale))
	
	var container: VBoxContainer = $MainContainer
	container.offset_left = max(16, screen_size.x * 0.02)
	container.offset_right = max(-16, -screen_size.x * 0.02)
	container.offset_top = max(16, screen_size.y * 0.02)
	container.offset_bottom = max(-16, -screen_size.y * 0.02)


func _play_intro_animation() -> void:
	var player_info: PanelContainer = $MainContainer/PlayerInfoBar
	var game_modes: VBoxContainer = $MainContainer/GameModesSection
	var features: HBoxContainer = $MainContainer/FeaturesSection
	
	player_info.modulate.a = 0.0
	player_info.position.y -= 30
	game_modes.modulate.a = 0.0
	features.modulate.a = 0.0
	
	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(player_info, "modulate:a", 1.0, 0.5)
	tween.tween_property(player_info, "position:y", player_info.position.y + 30, 0.5)
	
	await get_tree().create_timer(0.2).timeout
	
	tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(game_modes, "modulate:a", 1.0, 0.5)
	
	await get_tree().create_timer(0.15).timeout
	
	tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(features, "modulate:a", 1.0, 0.5)


func _on_enter_offline_clicked() -> void:
	UITheme.pulse(enter_world_btn)
	WorldNetwork.leave_session()
	get_tree().change_scene_to_file("res://Scenes/WorldScene.tscn")


func _on_cloud_world_clicked() -> void:
	UITheme.pulse(cloud_world_btn)
	var room := cloud_room_edit.text.strip_edges()
	_begin_cloud_connection(room)


func _begin_cloud_connection(room: String) -> void:
	var rid := room.strip_edges()
	if rid.is_empty():
		rid = "default"
	if WorldNetwork.cloud_ready.is_connected(_on_cloud_ready):
		WorldNetwork.cloud_ready.disconnect(_on_cloud_ready)
	if WorldNetwork.cloud_connection_failed.is_connected(_on_cloud_failed):
		WorldNetwork.cloud_connection_failed.disconnect(_on_cloud_failed)
	WorldNetwork.cloud_ready.connect(_on_cloud_ready, CONNECT_ONE_SHOT)
	WorldNetwork.cloud_connection_failed.connect(_on_cloud_failed, CONNECT_ONE_SHOT)
	var err: int = WorldNetwork.start_cloud(rid)
	if err != OK:
		if WorldNetwork.cloud_ready.is_connected(_on_cloud_ready):
			WorldNetwork.cloud_ready.disconnect(_on_cloud_ready)
		if WorldNetwork.cloud_connection_failed.is_connected(_on_cloud_failed):
			WorldNetwork.cloud_connection_failed.disconnect(_on_cloud_failed)
		if err == ERR_UNAUTHORIZED:
			_open_login_overlay(rid)
		else:
			MoeDialogBus.show_dialog("无法连接", "请确认已登录且保存了 API 地址；房间名仅允许字母、数字、下划线与短横线。错误码 %d。" % err)
		return
	_cloud_pending = true
	_cloud_wait_timer = get_tree().create_timer(15.0)
	_cloud_wait_timer.timeout.connect(_on_cloud_timeout, CONNECT_ONE_SHOT)


func _on_login_btn_clicked() -> void:
	UITheme.pulse(login_btn)
	_open_login_overlay("")


func _open_login_overlay(pending_cloud_room: String) -> void:
	if _login_overlay_layer != null and is_instance_valid(_login_overlay_layer):
		return
	_pending_cloud_room = pending_cloud_room.strip_edges()
	var layer := CanvasLayer.new()
	layer.layer = 120
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.5)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(dim)
	var login_inst: Control = LOGIN_SCENE.instantiate()
	login_inst.overlay_mode = true
	login_inst.set_anchors_preset(Control.PRESET_FULL_RECT)
	login_inst.login_success.connect(_on_overlay_login_success, CONNECT_ONE_SHOT)
	login_inst.overlay_closed.connect(_on_login_overlay_closed, CONNECT_ONE_SHOT)
	layer.add_child(login_inst)
	add_child(layer)
	_login_overlay_layer = layer


func _login_overlay_dispose() -> void:
	if _login_overlay_layer != null and is_instance_valid(_login_overlay_layer):
		_login_overlay_layer.queue_free()
	_login_overlay_layer = null


func _on_login_overlay_closed() -> void:
	_pending_cloud_room = ""
	_login_overlay_dispose()


func _on_overlay_login_success() -> void:
	var retry_room := _pending_cloud_room
	_pending_cloud_room = ""
	_login_overlay_dispose()
	_refresh_player_info()
	if not retry_room.is_empty():
		_begin_cloud_connection(retry_room)


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


func _on_recent_clicked() -> void:
	UITheme.pulse(recent_btn)
	MoeDialogBus.show_dialog("最近访问", "暂无最近访问记录")


func _on_friends_clicked() -> void:
	UITheme.pulse(friends_btn)
	MoeDialogBus.show_dialog("好友列表", "暂无在线好友")


func _on_notice_clicked() -> void:
	UITheme.pulse(notice_btn)
	MoeDialogBus.show_dialog("公告", "暂无新公告")


func _on_profile_clicked() -> void:
	UITheme.pulse(profile_btn)
	get_tree().change_scene_to_file("res://Scenes/ProfileScene.tscn")


func _on_settings_clicked() -> void:
	UITheme.pulse(settings_btn)
	if settings_overlay.has_method("open_settings"):
		settings_overlay.open_settings()


func _on_logout_clicked() -> void:
	UITheme.pulse(logout_btn)
	WorldNetwork.leave_session()
	if ProjectSettings.has_setting("moe_world/current_user"):
		ProjectSettings.set_setting("moe_world/current_user", {})
	UserStorage.clear_session_file()
	_refresh_player_info()
