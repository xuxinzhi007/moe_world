extends Node

class FontSizes:
	const TITLE_LARGE: int = 28
	const TITLE_MEDIUM: int = 24
	const TITLE_SMALL: int = 20
	const BODY_LARGE: int = 18
	const BODY_MEDIUM: int = 16
	const BODY_SMALL: int = 14
	const CAPTION: int = 12

class Colors:
	const PRIMARY: Color = Color8(255, 102, 153)
	const PRIMARY_LIGHT: Color = Color8(255, 130, 175)
	const PRIMARY_DARK: Color = Color8(230, 85, 130)
	const SECONDARY: Color = Color8(255, 230, 230)
	const BACKGROUND: Color = Color8(255, 243, 196)
	const TEXT_MAIN: Color = Color8(75, 50, 62)
	const TEXT_MUTED: Color = Color8(120, 90, 105)
	const TEXT_LIGHT: Color = Color8(255, 255, 255)
	const SUCCESS: Color = Color8(46, 204, 113)
	const WARNING: Color = Color8(241, 196, 15)
	const ERROR: Color = Color8(231, 76, 60)
	const INFO: Color = Color8(52, 152, 219)

class AnimationDurations:
	const INSTANT: float = 0.0
	const VERY_FAST: float = 0.15
	const FAST: float = 0.25
	const NORMAL: float = 0.35
	const SLOW: float = 0.5
	const VERY_SLOW: float = 0.75

static func create_button_style(base_color: Color, radius: int = 24) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = base_color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.content_margin_left = 20
	style.content_margin_top = 14
	style.content_margin_right = 20
	style.content_margin_bottom = 14
	return style

static func create_card_style(base_color: Color, radius: int = 32) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = base_color
	style.border_color = Color8(255, 200, 210)
	style.set_border_width_all(2)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.shadow_color = Color(0, 0, 0, 0.1)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 5)
	return style

static func create_input_style(radius: int = 20) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color8(255, 255, 255)
	style.border_color = Color8(255, 200, 210)
	style.set_border_width_all(2)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.content_margin_left = 16
	style.content_margin_top = 12
	style.content_margin_right = 16
	style.content_margin_bottom = 12
	return style

static func fade_in(node: Node, duration: float = AnimationDurations.NORMAL) -> void:
	if not node:
		return
	var tween := node.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	node.modulate.a = 0.0
	tween.tween_property(node, "modulate:a", 1.0, duration)

static func fade_out(node: Node, duration: float = AnimationDurations.NORMAL) -> void:
	if not node:
		return
	var tween := node.create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(node, "modulate:a", 0.0, duration)

static func slide_in(node: Node, direction: Vector2 = Vector2(0, 50), duration: float = AnimationDurations.NORMAL) -> void:
	if not node:
		return
	var tween := node.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	node.position += direction
	tween.tween_property(node, "position", node.position - direction, duration)

static func scale_in(node: Node, target_scale: Vector2 = Vector2(1, 1), duration: float = AnimationDurations.NORMAL) -> void:
	if not node:
		return
	var tween := node.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	node.scale = Vector2(0.8, 0.8)
	tween.tween_property(node, "scale", target_scale, duration)

static func pulse(node: Node, scale_factor: float = 1.05, duration: float = AnimationDurations.FAST) -> void:
	if not node:
		return
	var tween := node.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(node, "scale", Vector2(scale_factor, scale_factor), duration)
	tween.tween_property(node, "scale", Vector2(1.0, 1.0), duration)
