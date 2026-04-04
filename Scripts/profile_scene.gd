extends Control

@onready var uid_label: Label = $MainCard/HBoxContainer/LeftAvatarArea/UidLabel
@onready var level_label: Label = $MainCard/HBoxContainer/LeftAvatarArea/LevelLabel
@onready var username_label: Label = $MainCard/HBoxContainer/RightInfoArea/InfoList/InfoItem_Username/Text_Username
@onready var sign_label: Label = $MainCard/HBoxContainer/RightInfoArea/InfoList/InfoItem_Sign/Text_Sign
@onready var regtime_label: Label = $MainCard/HBoxContainer/RightInfoArea/InfoList/InfoItem_RegTime/Text_RegTime
@onready var edit_btn: Button = $MainCard/HBoxContainer/RightInfoArea/BtnContainer/Btn_EditProfile
@onready var security_btn: Button = $MainCard/HBoxContainer/RightInfoArea/BtnContainer/Btn_Security
@onready var back_btn: Button = $MainCard/HBoxContainer/RightInfoArea/BtnContainer/Btn_BackHall
@onready var avatar_frame: PanelContainer = $MainCard/HBoxContainer/LeftAvatarArea/AvatarFrame
@onready var title_label: Label = $MainCard/HBoxContainer/RightInfoArea/TitleLabel

var user_data = {}

func _ready() -> void:
	_load_user_data()
	_apply_theme()
	_bind_user_data()
	_bind_events()

func _load_user_data() -> void:
	if ProjectSettings.has_setting("moe_world/current_user"):
		user_data = ProjectSettings.get_setting("moe_world/current_user")
		print("📋 加载用户数据: ", user_data)
	else:
		user_data = {
			"username": "萌酱",
			"moe_no": "10001",
			"signature": "这个人很懒，什么都没写~",
			"created_at": "2026-01-01",
			"is_vip": false
		}

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
	
	var avatar_frame_style = StyleBoxFlat.new()
	avatar_frame_style.bg_color = Color(1, 0.4, 0.6)
	avatar_frame_style.corner_radius_top_left = 100
	avatar_frame_style.corner_radius_top_right = 100
	avatar_frame_style.corner_radius_bottom_left = 100
	avatar_frame_style.corner_radius_bottom_right = 100
	theme_obj.set_stylebox("panel", "Avatar", avatar_frame_style)
	
	theme_obj.set_color("font_color", "Button", Color(1, 1, 1))
	theme_obj.set_color("font_color", "Label", Color(0.2, 0.2, 0.2))
	
	title_label.add_theme_font_size_override("font_size", 48)
	title_label.add_theme_color_override("font_color", Color(1, 0.4, 0.6))
	
	uid_label.add_theme_font_size_override("font_size", 18)
	level_label.add_theme_font_size_override("font_size", 16)
	level_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
	username_label.add_theme_font_size_override("font_size", 24)
	sign_label.add_theme_font_size_override("font_size", 20)
	sign_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4, 1))
	regtime_label.add_theme_font_size_override("font_size", 18)
	
	self.theme = theme_obj

func _bind_user_data() -> void:
	var username = user_data.get("username", "用户")
	var moe_no = user_data.get("moe_no", "10001")
	var signature = user_data.get("signature", "")
	var created_at = user_data.get("created_at", "")
	var is_vip = user_data.get("is_vip", false)
	
	uid_label.text = "UID: " + str(moe_no)
	level_label.text = "VIP" if is_vip else "普通用户"
	
	username_label.text = "用户名: " + username
	username_label.custom_minimum_size = Vector2(500, 35)
	username_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	username_label.horizontal_alignment = 0
	
	sign_label.text = "个性签名: " + (signature if not signature.is_empty() else "这个人很懒，什么都没写~")
	sign_label.custom_minimum_size = Vector2(500, 35)
	sign_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	sign_label.horizontal_alignment = 0
	
	if created_at and len(created_at) >= 10:
		regtime_label.text = "注册时间: " + created_at.left(10)
	else:
		regtime_label.text = "注册时间: 2026-01-01"
	regtime_label.custom_minimum_size = Vector2(500, 35)
	regtime_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	regtime_label.horizontal_alignment = 0

func _bind_events() -> void:
	edit_btn.pressed.connect(_on_edit_clicked)
	security_btn.pressed.connect(_on_security_clicked)
	back_btn.pressed.connect(_on_back_clicked)

func _on_edit_clicked() -> void:
	print("打开修改资料界面")

func _on_security_clicked() -> void:
	print("打开账号安全界面")

func _on_back_clicked() -> void:
	print("🏠 返回大厅")
	get_tree().change_scene_to_file("res://Scenes/HallScene.tscn")
