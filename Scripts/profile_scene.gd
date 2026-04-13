extends Control

@onready var uid_label: Label = $MainCard/HBoxContainer/LeftAvatarArea/UidLabel
@onready var level_label: Label = $MainCard/HBoxContainer/LeftAvatarArea/LevelLabel
@onready var username_label: Label = $MainCard/HBoxContainer/RightInfoArea/InfoList/InfoItem_Username/Text_Username
@onready var email_label: Label = $MainCard/HBoxContainer/RightInfoArea/InfoList/InfoItem_Email/Text_Email
@onready var sign_label: Label = $MainCard/HBoxContainer/RightInfoArea/InfoList/InfoItem_Sign/Text_Sign
@onready var regtime_label: Label = $MainCard/HBoxContainer/RightInfoArea/InfoList/InfoItem_RegTime/Text_RegTime
@onready var edit_btn: Button = $MainCard/HBoxContainer/RightInfoArea/BtnContainer/Btn_EditProfile
@onready var security_btn: Button = $MainCard/HBoxContainer/RightInfoArea/BtnContainer/Btn_Security
@onready var back_btn: Button = $MainCard/HBoxContainer/RightInfoArea/BtnContainer/Btn_BackHall
@onready var avatar_frame: PanelContainer = $MainCard/HBoxContainer/LeftAvatarArea/AvatarFrame
@onready var title_label: Label = $MainCard/HBoxContainer/RightInfoArea/TitleLabel

var user_data: Dictionary = {}


func _ready() -> void:
	_load_user_data()
	_apply_theme()
	_bind_user_data()
	_bind_events()


func _load_user_data() -> void:
	if ProjectSettings.has_setting("moe_world/current_user"):
		var raw: Variant = ProjectSettings.get_setting("moe_world/current_user")
		if raw is Dictionary:
			user_data = raw as Dictionary
			print("📋 个人中心加载用户数据")
	else:
		user_data = {
			"username": "萌酱",
			"moe_no": "10001",
			"email": "",
			"signature": "这个人很懒，什么都没写~",
			"created_at": "2026-01-01",
			"is_vip": false
		}


func _apply_theme() -> void:
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
	btn_style.content_margin_top = 14
	btn_style.content_margin_right = 16
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

	var avatar_ring := StyleBoxFlat.new()
	avatar_ring.bg_color = Color(0, 0, 0, 0)
	avatar_ring.border_color = col_btn
	avatar_ring.set_border_width_all(4)
	avatar_ring.corner_radius_top_left = 100
	avatar_ring.corner_radius_top_right = 100
	avatar_ring.corner_radius_bottom_left = 100
	avatar_ring.corner_radius_bottom_right = 100
	avatar_frame.add_theme_stylebox_override("panel", avatar_ring)

	title_label.add_theme_font_size_override("font_size", 36)
	title_label.add_theme_color_override("font_color", col_title)
	uid_label.add_theme_font_size_override("font_size", 17)
	level_label.add_theme_font_size_override("font_size", 15)
	level_label.add_theme_color_override("font_color", col_muted)
	username_label.add_theme_font_size_override("font_size", 20)
	email_label.add_theme_font_size_override("font_size", 18)
	sign_label.add_theme_font_size_override("font_size", 17)
	sign_label.add_theme_color_override("font_color", col_muted)
	regtime_label.add_theme_font_size_override("font_size", 16)

	self.theme = theme_obj
	$BgColor.color = Color8(255, 243, 196)


func _bind_user_data() -> void:
	var username: String = str(user_data.get("username", "用户"))
	var moe_no: String = str(user_data.get("moe_no", "—"))
	var email: String = str(user_data.get("email", ""))
	var signature: String = str(user_data.get("signature", ""))
	var created_at: String = str(user_data.get("created_at", ""))
	var is_vip: bool = bool(user_data.get("is_vip", false))

	uid_label.text = "萌号: " + moe_no
	level_label.text = "VIP 会员" if is_vip else "普通用户"

	username_label.text = "用户名: " + username
	username_label.autowrap_mode = TextServer.AUTOWRAP_OFF

	email_label.text = "邮箱: " + (email if not email.is_empty() else "未绑定")

	sign_label.text = "个性签名: " + (signature if not signature.is_empty() else "这个人很懒，什么都没写~")
	sign_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	if created_at.length() >= 10:
		regtime_label.text = "注册时间: " + created_at.left(10)
	else:
		regtime_label.text = "注册时间: —"


func _bind_events() -> void:
	edit_btn.pressed.connect(_on_edit_clicked)
	security_btn.pressed.connect(_on_security_clicked)
	back_btn.pressed.connect(_on_back_clicked)


func _popup_info(title: String, body: String) -> void:
	var dlg := AcceptDialog.new()
	dlg.title = title
	dlg.dialog_text = body
	dlg.ok_button_text = "知道了"
	get_tree().root.add_child(dlg)
	dlg.popup_centered()
	dlg.confirmed.connect(func(): dlg.queue_free())
	dlg.canceled.connect(func(): dlg.queue_free())


func _on_edit_clicked() -> void:
	_popup_info("修改资料", "资料编辑将对接后端个人资料接口；当前为演示版，数据来自上次登录缓存。")


func _on_security_clicked() -> void:
	_popup_info("账号安全", "可在此绑定手机、修改密码等。当前为演示版，完整流程请在后端联调后接入。")


func _on_back_clicked() -> void:
	get_tree().change_scene_to_file("res://Scenes/HallScene.tscn")
