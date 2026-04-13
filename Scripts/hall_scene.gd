extends Control

@onready var welcome_label: Label = $MainCard/VBoxContainer/WelcomeLabel
@onready var enter_world_btn: Button = $MainCard/VBoxContainer/EnterWorldBtn
@onready var host_world_btn: Button = $MainCard/VBoxContainer/HostWorldBtn
@onready var join_world_btn: Button = $MainCard/VBoxContainer/JoinWorldBtn
@onready var profile_btn: Button = $MainCard/VBoxContainer/ProfileBtn
@onready var settings_btn: Button = $MainCard/VBoxContainer/SettingsBtn
@onready var logout_btn: Button = $MainCard/VBoxContainer/LogoutBtn
@onready var copyright_label: Label = $MainCard/VBoxContainer/CopyrightLabel
@onready var settings_overlay: Control = $SettingsOverlay
@onready var join_panel: Control = $JoinPanel
@onready var join_ip_edit: LineEdit = $JoinPanel/JoinCard/JoinMargin/JoinVBox/JoinIpEdit
@onready var join_confirm_btn: Button = $JoinPanel/JoinCard/JoinMargin/JoinVBox/JoinBtnRow/JoinConfirmBtn
@onready var join_cancel_btn: Button = $JoinPanel/JoinCard/JoinMargin/JoinVBox/JoinBtnRow/JoinCancelBtn

var _join_wait_timer: SceneTreeTimer
var _join_pending: bool = false


func _ready() -> void:
	_apply_theme()
	_refresh_welcome()
	enter_world_btn.pressed.connect(_on_enter_offline_clicked)
	host_world_btn.pressed.connect(_on_host_world_clicked)
	join_world_btn.pressed.connect(_on_open_join_panel)
	join_confirm_btn.pressed.connect(_on_join_confirm_clicked)
	join_cancel_btn.pressed.connect(_on_join_cancel_clicked)
	profile_btn.pressed.connect(_on_profile_clicked)
	settings_btn.pressed.connect(_on_settings_clicked)
	logout_btn.pressed.connect(_on_logout_clicked)


func _refresh_welcome() -> void:
	var name_str := "萌酱"
	if ProjectSettings.has_setting("moe_world/current_user"):
		var u: Variant = ProjectSettings.get_setting("moe_world/current_user")
		if u is Dictionary and not (u as Dictionary).is_empty():
			name_str = str((u as Dictionary).get("username", "萌酱"))
	welcome_label.text = "欢迎回来，%s" % name_str


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
	btn_style.corner_radius_top_left = 28
	btn_style.corner_radius_top_right = 28
	btn_style.corner_radius_bottom_left = 28
	btn_style.corner_radius_bottom_right = 28
	btn_style.content_margin_left = 16
	btn_style.content_margin_top = 12
	btn_style.content_margin_right = 16
	btn_style.content_margin_bottom = 12
	theme_obj.set_stylebox("normal", "Button", btn_style)
	var btn_hover := btn_style.duplicate()
	btn_hover.bg_color = col_btn_hover
	theme_obj.set_stylebox("hover", "Button", btn_hover)
	var btn_pressed := btn_style.duplicate()
	btn_pressed.bg_color = col_btn_pressed
	theme_obj.set_stylebox("pressed", "Button", btn_pressed)

	var card_style := StyleBoxFlat.new()
	card_style.bg_color = col_card
	card_style.corner_radius_top_left = 48
	card_style.corner_radius_top_right = 48
	card_style.corner_radius_bottom_left = 48
	card_style.corner_radius_bottom_right = 48
	theme_obj.set_stylebox("panel", "PanelContainer", card_style)

	theme_obj.set_color("font_color", "Button", Color8(255, 255, 255))
	theme_obj.set_color("font_color", "Label", col_text)

	var title_label: Label = $MainCard/VBoxContainer/TitleLabel
	title_label.add_theme_font_size_override("font_size", 42)
	title_label.add_theme_color_override("font_color", col_title)
	welcome_label.add_theme_font_size_override("font_size", 17)
	welcome_label.add_theme_color_override("font_color", col_muted)
	enter_world_btn.add_theme_font_size_override("font_size", 18)
	host_world_btn.add_theme_font_size_override("font_size", 18)
	join_world_btn.add_theme_font_size_override("font_size", 18)
	profile_btn.add_theme_font_size_override("font_size", 18)
	settings_btn.add_theme_font_size_override("font_size", 18)
	logout_btn.add_theme_font_size_override("font_size", 18)
	copyright_label.add_theme_font_size_override("font_size", 15)
	copyright_label.add_theme_color_override("font_color", col_muted)

	self.theme = theme_obj
	$BgColor.color = col_bg


func _on_enter_offline_clicked() -> void:
	WorldNetwork.leave_session()
	get_tree().change_scene_to_file("res://Scenes/WorldScene.tscn")


func _on_host_world_clicked() -> void:
	var err: int = WorldNetwork.start_host()
	if err != OK:
		MoeDialogBus.show_dialog("联机失败", "无法在本机开启主机（错误码 %d）。请检查端口 %d 是否被占用。" % [err, WorldNetwork.port])
		return
	get_tree().change_scene_to_file("res://Scenes/WorldScene.tscn")


func _on_open_join_panel() -> void:
	join_panel.visible = true


func _on_join_cancel_clicked() -> void:
	join_panel.visible = false


func _on_join_confirm_clicked() -> void:
	var ip := join_ip_edit.text.strip_edges()
	if ip.is_empty():
		ip = "127.0.0.1"
	var err: int = WorldNetwork.start_client(ip)
	if err != OK:
		MoeDialogBus.show_dialog("联机失败", "无法发起连接（错误码 %d）。" % err)
		return
	_join_pending = true
	if multiplayer.connected_to_server.is_connected(_on_join_connected):
		multiplayer.connected_to_server.disconnect(_on_join_connected)
	multiplayer.connected_to_server.connect(_on_join_connected)
	if multiplayer.connection_failed.is_connected(_on_join_failed):
		multiplayer.connection_failed.disconnect(_on_join_failed)
	multiplayer.connection_failed.connect(_on_join_failed)
	_join_wait_timer = get_tree().create_timer(8.0)
	_join_wait_timer.timeout.connect(_on_join_timeout, CONNECT_ONE_SHOT)


func _on_join_connected() -> void:
	_join_pending = false
	if multiplayer.connection_failed.is_connected(_on_join_failed):
		multiplayer.connection_failed.disconnect(_on_join_failed)
	if multiplayer.connected_to_server.is_connected(_on_join_connected):
		multiplayer.connected_to_server.disconnect(_on_join_connected)
	join_panel.visible = false
	get_tree().change_scene_to_file("res://Scenes/WorldScene.tscn")


func _on_join_failed() -> void:
	_join_pending = false
	if multiplayer.connected_to_server.is_connected(_on_join_connected):
		multiplayer.connected_to_server.disconnect(_on_join_connected)
	WorldNetwork.leave_session()
	MoeDialogBus.show_dialog("连接失败", "连不上主机。请确认对方已点「我当主机」、IP 正确、防火墙放行 UDP %d。" % WorldNetwork.port)


func _on_join_timeout() -> void:
	if not _join_pending:
		return
	_join_pending = false
	if multiplayer.connected_to_server.is_connected(_on_join_connected):
		multiplayer.connected_to_server.disconnect(_on_join_connected)
	if multiplayer.connection_failed.is_connected(_on_join_failed):
		multiplayer.connection_failed.disconnect(_on_join_failed)
	WorldNetwork.leave_session()
	MoeDialogBus.show_dialog("连接超时", "仍未连上主机，请检查网络与 IP 后重试。")


func _on_profile_clicked() -> void:
	get_tree().change_scene_to_file("res://Scenes/ProfileScene.tscn")


func _on_settings_clicked() -> void:
	if settings_overlay.has_method("open_settings"):
		settings_overlay.open_settings()


func _on_logout_clicked() -> void:
	WorldNetwork.leave_session()
	if ProjectSettings.has_setting("moe_world/current_user"):
		ProjectSettings.set_setting("moe_world/current_user", {})
	ProjectSettings.save()
	get_tree().change_scene_to_file("res://Scenes/LoginScreen.tscn")
