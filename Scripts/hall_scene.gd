extends Control

@onready var main_card: PanelContainer = $MainCard
@onready var title_label: Label = $MainCard/VBoxContainer/TitleLabel
@onready var welcome_label: Label = $MainCard/VBoxContainer/WelcomeLabel
@onready var enter_world_btn: Button = $MainCard/VBoxContainer/EnterWorldBtn
@onready var profile_btn: Button = $MainCard/VBoxContainer/ProfileBtn
@onready var settings_btn: Button = $MainCard/VBoxContainer/SettingsBtn
@onready var logout_btn: Button = $MainCard/VBoxContainer/LogoutBtn
@onready var copyright_label: Label = $MainCard/VBoxContainer/CopyrightLabel
@onready var settings_overlay: Control = $SettingsOverlay


func _ready() -> void:
	_apply_theme()
	_refresh_welcome()
	enter_world_btn.pressed.connect(_on_enter_world_clicked)
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
	btn_style.content_margin_left = 18
	btn_style.content_margin_top = 14
	btn_style.content_margin_right = 18
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
	card_style.corner_radius_top_left = 48
	card_style.corner_radius_top_right = 48
	card_style.corner_radius_bottom_left = 48
	card_style.corner_radius_bottom_right = 48
	theme_obj.set_stylebox("panel", "PanelContainer", card_style)

	theme_obj.set_color("font_color", "Button", Color8(255, 255, 255))
	theme_obj.set_color("font_color", "Label", col_text)

	title_label.add_theme_font_size_override("font_size", 44)
	title_label.add_theme_color_override("font_color", col_title)
	welcome_label.add_theme_font_size_override("font_size", 18)
	welcome_label.add_theme_color_override("font_color", col_muted)
	enter_world_btn.add_theme_font_size_override("font_size", 20)
	profile_btn.add_theme_font_size_override("font_size", 20)
	settings_btn.add_theme_font_size_override("font_size", 20)
	logout_btn.add_theme_font_size_override("font_size", 20)
	copyright_label.add_theme_font_size_override("font_size", 16)
	copyright_label.add_theme_color_override("font_color", col_muted)

	self.theme = theme_obj
	$BgColor.color = col_bg


func _on_enter_world_clicked() -> void:
	get_tree().change_scene_to_file("res://Scenes/WorldScene.tscn")


func _on_profile_clicked() -> void:
	get_tree().change_scene_to_file("res://Scenes/ProfileScene.tscn")


func _on_settings_clicked() -> void:
	if settings_overlay.has_method("open_settings"):
		settings_overlay.open_settings()


func _on_logout_clicked() -> void:
	if ProjectSettings.has_setting("moe_world/current_user"):
		ProjectSettings.set_setting("moe_world/current_user", {})
	ProjectSettings.save()
	get_tree().change_scene_to_file("res://Scenes/LoginScreen.tscn")
