extends Control

@onready var main_card: PanelContainer = $MainCard
@onready var avatar_frame: PanelContainer = $MainCard/VBoxContainer/AvatarArea/AvatarFrame
@onready var avatar_color: ColorRect = $MainCard/VBoxContainer/AvatarArea/AvatarFrame/AvatarColor
@onready var username_label: Label = $MainCard/VBoxContainer/UsernameLabel
@onready var user_id_label: Label = $MainCard/VBoxContainer/UserIdLabel
@onready var bio_label: Label = $MainCard/VBoxContainer/BioLabel
@onready var edit_nickname_btn: Button = $MainCard/VBoxContainer/EditNicknameBtn
@onready var edit_bio_btn: Button = $MainCard/VBoxContainer/EditBioBtn
@onready var account_security_btn: Button = $MainCard/VBoxContainer/AccountSecurityBtn
@onready var back_btn: Button = $MainCard/VBoxContainer/BackBtn

var user_data: Dictionary = {}

func _ready() -> void:
	_apply_theme()
	
	edit_nickname_btn.pressed.connect(_on_edit_nickname_clicked)
	edit_bio_btn.pressed.connect(_on_edit_bio_clicked)
	account_security_btn.pressed.connect(_on_account_security_clicked)
	back_btn.pressed.connect(_on_back_clicked)
	
	_load_user_data()

func _apply_theme() -> void:
	var theme = Theme.new()
	
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
	theme.set_stylebox("normal", "Button", btn_style)
	
	var btn_hover = btn_style.duplicate()
	btn_hover.bg_color = Color(1, 0.5, 0.7)
	theme.set_stylebox("hover", "Button", btn_hover)
	
	var btn_pressed = btn_style.duplicate()
	btn_pressed.bg_color = Color(0.9, 0.3, 0.5)
	theme.set_stylebox("pressed", "Button", btn_pressed)
	
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = Color(1, 0.9, 0.9)
	card_style.corner_radius_top_left = 64
	card_style.corner_radius_top_right = 64
	card_style.corner_radius_bottom_left = 64
	card_style.corner_radius_bottom_right = 64
	theme.set_stylebox("panel", "PanelContainer", card_style)
	
	var avatar_style = StyleBoxFlat.new()
	avatar_style.bg_color = Color(1, 0.4, 0.6)
	avatar_style.corner_radius_top_left = 100
	avatar_style.corner_radius_top_right = 100
	avatar_style.corner_radius_bottom_left = 100
	avatar_style.corner_radius_bottom_right = 100
	theme.set_stylebox("panel", "Avatar", avatar_style)
	
	theme.set_color("font_color", "Button", Color(1, 1, 1))
	theme.set_color("font_color", "Label", Color(0.2, 0.2, 0.2))
	
	username_label.add_theme_font_size_override("font_size", 32)
	user_id_label.add_theme_font_size_override("font_size", 20)
	user_id_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
	bio_label.add_theme_font_size_override("font_size", 24)
	bio_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4, 1))
	
	self.theme = theme

func _load_user_data() -> void:
	user_data = {
		"username": "萌酱",
		"user_id": "12345",
		"bio": "这个人很懒，什么都没写~"
	}
	
	_update_ui()

func _update_ui() -> void:
	username_label.text = user_data.get("username", "用户")
	user_id_label.text = "ID: %s" % user_data.get("user_id", "0")
	bio_label.text = user_data.get("bio", "")

func _on_edit_nickname_clicked() -> void:
	print("✏️ 修改昵称")

func _on_edit_bio_clicked() -> void:
	print("📝 修改签名")

func _on_account_security_clicked() -> void:
	print("🔐 账号安全")

func _on_back_clicked() -> void:
	print("🏠 返回大厅")
	get_tree().change_scene_to_file("res://Scenes/HallScene.tscn")
