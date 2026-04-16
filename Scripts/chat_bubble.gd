extends PanelContainer

signal bubble_finished

const FADE_DURATION = 0.8
const DISPLAY_DURATION = 4.0

@onready var player_name_label: Label = $Content/PlayerName
@onready var message_label: RichTextLabel = $Content/Message

var _offset_y: float = -120.0
var _is_fading_out: bool = false


func _ready() -> void:
	_apply_theme()


func _apply_theme() -> void:
	var bubble_style := StyleBoxFlat.new()
	bubble_style.bg_color = Color(1, 0.95, 0.98, 0.95)
	bubble_style.border_color = Color8(255, 150, 180)
	bubble_style.set_content_margin_all(12)
	bubble_style.content_margin_top = 10
	bubble_style.set_border_width_all(2)
	bubble_style.corner_radius_top_left = 20
	bubble_style.corner_radius_top_right = 20
	bubble_style.corner_radius_bottom_left = 20
	bubble_style.corner_radius_bottom_right = 8
	bubble_style.shadow_color = Color(0, 0, 0, 0.15)
	bubble_style.shadow_size = 8
	bubble_style.shadow_offset = Vector2(0, 4)
	
	add_theme_stylebox_override("panel", bubble_style)
	
	player_name_label.add_theme_color_override("font_color", Color8(255, 100, 150))
	player_name_label.add_theme_font_size_override("font_size", 14)
	
	message_label.add_theme_color_override("default_color", Color8(75, 50, 62))
	message_label.add_theme_font_size_override("normal_font_size", 16)


func setup(player_name: String, message: String, offset: Vector2) -> void:
	player_name_label.text = player_name
	message_label.text = message
	
	var estimated_display_time: float = min(DISPLAY_DURATION + float(message.length()) * 0.05, 8.0)
	
	modulate.a = 0.0
	position.y = offset.y + _offset_y
	# 首帧后才有正确 minimum size，再水平居中，避免根节点曾用「顶栏拉满」时 size.x 失真
	await get_tree().process_frame
	position.x = offset.x - size.x * 0.5
	
	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "modulate:a", 1.0, FADE_DURATION)
	tween.tween_interval(estimated_display_time)
	tween.tween_callback(_start_fade_out)
	tween.tween_callback(func(): bubble_finished.emit())


func _start_fade_out() -> void:
	if _is_fading_out:
		return
	_is_fading_out = true
	
	var tween := create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "modulate:a", 0.0, FADE_DURATION)
	tween.tween_callback(queue_free)
