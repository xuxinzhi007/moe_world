extends RefCounted

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


## ---------- 现代游戏风 UI（登录 / 注册 / 个人中心等共用）----------

static func modern_glass_card(corner: int = 28, bg_alpha: float = 0.93) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(1, 0.98, 0.995, bg_alpha)
	s.border_color = Color8(230, 185, 208)
	s.set_border_width_all(1)
	s.corner_radius_top_left = corner
	s.corner_radius_top_right = corner
	s.corner_radius_bottom_left = corner
	s.corner_radius_bottom_right = corner
	s.shadow_color = Color(0.32, 0.1, 0.2, 0.14)
	s.shadow_size = 26
	s.shadow_offset = Vector2(0, 12)
	return s


static func modern_line_edit_normal(corner: int = 14) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(1, 1, 1, 0.94)
	s.border_color = Color8(215, 175, 200)
	s.set_border_width_all(1)
	s.corner_radius_top_left = corner
	s.corner_radius_top_right = corner
	s.corner_radius_bottom_left = corner
	s.corner_radius_bottom_right = corner
	s.content_margin_left = 16
	s.content_margin_top = 12
	s.content_margin_right = 16
	s.content_margin_bottom = 12
	return s


static func modern_line_edit_focus(corner: int = 14) -> StyleBoxFlat:
	var s := modern_line_edit_normal(corner)
	s.border_color = Color8(255, 95, 150)
	s.set_border_width_all(2)
	return s


static func modern_primary_button_normal(corner: int = 22) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color8(255, 82, 145)
	s.corner_radius_top_left = corner
	s.corner_radius_top_right = corner
	s.corner_radius_bottom_left = corner
	s.corner_radius_bottom_right = corner
	s.content_margin_left = 22
	s.content_margin_top = 14
	s.content_margin_right = 22
	s.content_margin_bottom = 14
	s.shadow_color = Color(0.45, 0.08, 0.22, 0.2)
	s.shadow_size = 14
	s.shadow_offset = Vector2(0, 4)
	return s


static func modern_primary_button_hover(corner: int = 22) -> StyleBoxFlat:
	var s := modern_primary_button_normal(corner)
	s.bg_color = Color8(255, 120, 170)
	return s


static func modern_primary_button_pressed(corner: int = 22) -> StyleBoxFlat:
	var s := modern_primary_button_normal(corner)
	s.bg_color = Color8(225, 65, 125)
	s.shadow_size = 6
	return s


static func modern_dialog_sheet() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(1, 0.98, 0.99, 0.96)
	s.border_color = Color8(240, 175, 200)
	s.set_border_width_all(1)
	s.corner_radius_top_left = 28
	s.corner_radius_top_right = 28
	s.corner_radius_bottom_left = 0
	s.corner_radius_bottom_right = 0
	s.shadow_color = Color(0.25, 0.08, 0.15, 0.18)
	s.shadow_size = 28
	s.shadow_offset = Vector2(0, -6)
	return s


static func modern_hud_bar_bottom_round() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(1, 0.97, 0.99, 0.88)
	s.border_color = Color8(255, 195, 215)
	s.set_border_width_all(1)
	s.corner_radius_top_left = 0
	s.corner_radius_top_right = 0
	s.corner_radius_bottom_left = 20
	s.corner_radius_bottom_right = 20
	s.shadow_color = Color(0.35, 0.12, 0.2, 0.1)
	s.shadow_size = 16
	s.shadow_offset = Vector2(0, 6)
	return s


## HSlider / Slider — 柔和轨道 + 高亮拇指区（设置面板等）
static func modern_slider_track() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(1, 1, 1, 0.42)
	s.border_color = Color8(230, 190, 210)
	s.set_border_width_all(1)
	var r := 10
	s.corner_radius_top_left = r
	s.corner_radius_top_right = r
	s.corner_radius_bottom_left = r
	s.corner_radius_bottom_right = r
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	return s


static func modern_slider_grabber_area() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color8(255, 115, 165)
	s.border_color = Color8(255, 200, 220)
	s.set_border_width_all(1)
	var r := 10
	s.corner_radius_top_left = r
	s.corner_radius_top_right = r
	s.corner_radius_bottom_left = r
	s.corner_radius_bottom_right = r
	s.shadow_color = Color(0.4, 0.1, 0.2, 0.22)
	s.shadow_size = 10
	s.shadow_offset = Vector2(0, 2)
	return s


static func modern_slider_grabber_area_highlight() -> StyleBoxFlat:
	var s := modern_slider_grabber_area()
	s.bg_color = Color8(255, 135, 180)
	return s


## ---------- 响应式布局（大厅 / 个人中心 / 登录注册 等共用）----------

static func responsive_pad_x(screen_width: float) -> float:
	return clampf(screen_width * 0.022, 12.0, 64.0)


static func responsive_pad_y(screen_height: float) -> float:
	return clampf(screen_height * 0.02, 10.0, 52.0)


static func responsive_main_column_content_width(screen_width: float) -> float:
	var pad_x: float = responsive_pad_x(screen_width)
	var usable_w: float = maxf(120.0, screen_width - pad_x * 2.0)
	var max_content_w: float
	if screen_width >= 2200:
		max_content_w = 1880.0
	elif screen_width >= 1600:
		max_content_w = 1680.0
	elif screen_width >= 1280:
		max_content_w = 1480.0
	elif screen_width >= 960:
		max_content_w = 1240.0
	else:
		max_content_w = usable_w
	return minf(usable_w, max_content_w)


## 全屏页面主内容 VBox 的 offset_*（左右对称居中栏）
static func responsive_main_column_margins(screen: Vector2) -> Dictionary:
	var content_w: float = responsive_main_column_content_width(screen.x)
	var side: float = (screen.x - content_w) * 0.5
	var pad_y: float = responsive_pad_y(screen.y)
	return {"left": side, "right": -side, "top": pad_y, "bottom": -pad_y}


static func responsive_ui_font_scale(screen: Vector2) -> float:
	var font_scale: float = clampf(sqrt(screen.x * screen.y) / 920.0, 0.8, 1.45)
	if screen.x >= 1400:
		font_scale = maxf(font_scale, 1.02)
	return font_scale


## 登录/注册居中卡片半宽高（锚点居中时 offset_left=-hx, offset_right=hx）
static func responsive_auth_card_half_extents(screen: Vector2, tall_form: bool) -> Vector2:
	var pad_x: float = responsive_pad_x(screen.x)
	var pad_y: float = responsive_pad_y(screen.y)
	var usable_w: float = maxf(260.0, screen.x - pad_x * 2.0)
	var usable_h: float = maxf(240.0, screen.y - pad_y * 2.0)
	var max_full_w: float
	if screen.x >= 1600:
		max_full_w = 940.0
	elif screen.x >= 1200:
		max_full_w = 880.0
	elif screen.x >= 900:
		max_full_w = 820.0
	else:
		max_full_w = usable_w
	var full_w: float = minf(usable_w, max_full_w)
	var max_h_cap: float = 780.0 if tall_form else 680.0
	var full_h: float = minf(usable_h * 0.92, max_h_cap)
	return Vector2(full_w * 0.5, full_h * 0.5)
