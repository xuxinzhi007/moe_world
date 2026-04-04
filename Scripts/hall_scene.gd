extends Control

@onready var main_card: PanelContainer = $MainCard
@onready var title_label: Label = $MainCard/VBoxContainer/TitleLabel
@onready var enter_world_btn: Button = $MainCard/VBoxContainer/EnterWorldBtn
@onready var profile_btn: Button = $MainCard/VBoxContainer/ProfileBtn
@onready var settings_btn: Button = $MainCard/VBoxContainer/SettingsBtn
@onready var logout_btn: Button = $MainCard/VBoxContainer/LogoutBtn
@onready var copyright_label: Label = $MainCard/VBoxContainer/CopyrightLabel

func _ready() -> void:
	_apply_theme()
	
	enter_world_btn.pressed.connect(_on_enter_world_clicked)
	profile_btn.pressed.connect(_on_profile_clicked)
	settings_btn.pressed.connect(_on_settings_clicked)
	logout_btn.pressed.connect(_on_logout_clicked)

func _apply_theme() -> void:
	var theme_obj = Theme.new()
	
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(1, 0.4, 0.6)
	btn_style.corner_radius_top_left = 32
	btn_style.corner_radius_top_right = 32
	btn_style.corner_radius_bottom_left = 32
	btn_style.corner_radius_bottom_right = 32
	btn_style.content_margin_left = 16
	btn_style.content_margin_top = 16
	btn_style.content_margin_right = 16
	btn_style.content_margin_bottom = 16
	theme_obj.set_stylebox("normal", "Button", btn_style)
	
	var btn_hover = btn_style.duplicate()
	btn_hover.bg_color = Color(1, 0.5, 0.7)
	theme_obj.set_stylebox("hover", "Button", btn_hover)
	
	var btn_pressed = btn_style.duplicate()
	btn_pressed.bg_color = Color(0.9, 0.3, 0.5)
	theme_obj.set_stylebox("pressed", "Button", btn_pressed)
	
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = Color(1, 0.9, 0.9)
	card_style.corner_radius_top_left = 64
	card_style.corner_radius_top_right = 64
	card_style.corner_radius_bottom_left = 64
	card_style.corner_radius_bottom_right = 64
	theme_obj.set_stylebox("panel", "PanelContainer", card_style)
	
	theme_obj.set_color("font_color", "Button", Color(1, 1, 1))
	theme_obj.set_color("font_color", "Label", Color(0.2, 0.2, 0.2))
	
	title_label.add_theme_font_size_override("font_size", 64)
	title_label.add_theme_color_override("font_color", Color(1, 0.4, 0.6))
	
	copyright_label.add_theme_font_size_override("font_size", 20)
	copyright_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
	
	self.theme = theme_obj

func _on_enter_world_clicked() -> void:
	print("🌍 进入世界")
	get_tree().change_scene_to_file("res://Scenes/WorldScene.tscn")

func _on_profile_clicked() -> void:
	print("👤 个人中心")
	get_tree().change_scene_to_file("res://Scenes/ProfileScene.tscn")

func _on_settings_clicked() -> void:
	print("⚙️ 设置")

func _on_logout_clicked() -> void:
	print("🚪 退出登录")
	get_tree().change_scene_to_file("res://Scenes/LoginScreen.tscn")
