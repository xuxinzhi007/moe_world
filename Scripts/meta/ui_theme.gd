extends RefCounted

## ============================================================
## 萌社区 UI 主题系统 — 现代暗色 RPG 风格
## 主色：深紫 + 玫红 + 青色高光
## ============================================================

class FontSizes:
	const TITLE_LARGE: int = 28
	const TITLE_MEDIUM: int = 24
	const TITLE_SMALL: int = 20
	const BODY_LARGE: int = 18
	const BODY_MEDIUM: int = 16
	const BODY_SMALL: int = 14
	const CAPTION: int = 12

class Colors:
	## 背景 / 面板
	const BG_DEEP: Color        = Color(0.059, 0.039, 0.118, 1.0)   ## #0F0A1E
	const PANEL_DARK: Color     = Color(0.10,  0.08,  0.22,  0.82)  ## 深色面板 稍透明
	const PANEL_MID: Color      = Color(0.14,  0.10,  0.28,  0.72)  ## 中等面板 更透明
	## 主色 & 强调 — 降低饱和度 / 提亮
	const PRIMARY: Color        = Color(0.52,  0.35,  0.78,  1.0)   ## 中紫（降饱和）
	const PRIMARY_LIGHT: Color  = Color(0.68,  0.52,  0.90,  1.0)   ## 亮紫
	const PRIMARY_DARK: Color   = Color(0.38,  0.22,  0.60,  1.0)   ## 深紫
	const ACCENT_PINK: Color    = Color(1.0,   0.50,  0.68,  1.0)   ## 玫红（柔和）
	const ACCENT_CYAN: Color    = Color(0.30,  0.82,  1.0,   1.0)   ## 青（柔和）
	const GOLD: Color           = Color(1.0,   0.82,  0.40,  1.0)   ## 金
	## 游戏状态色
	const HP_RED: Color         = Color(1.0,   0.32,  0.38,  1.0)
	const MP_BLUE: Color        = Color(0.36,  0.56,  1.0,   1.0)
	const XP_GREEN: Color       = Color(0.20,  0.80,  0.44,  1.0)
	## 文字
	const TEXT_MAIN: Color      = Color(0.95,  0.93,  1.0,   1.0)   ## 近白微紫
	const TEXT_MUTED: Color     = Color(0.62,  0.58,  0.74,  1.0)   ## 灰紫
	const TEXT_LIGHT: Color     = Color(1.0,   1.0,   1.0,   1.0)
	## 功能色
	const SUCCESS: Color        = Color(0.20,  0.80,  0.44,  1.0)
	const WARNING: Color        = Color(1.0,   0.82,  0.40,  1.0)
	const ERROR: Color          = Color(1.0,   0.32,  0.38,  1.0)
	const INFO: Color           = Color(0.36,  0.56,  1.0,   1.0)
	## 渐变背景色
	const BG_GRAD_A: Color      = Color(0.059, 0.039, 0.118, 1.0)
	const BG_GRAD_B: Color      = Color(0.051, 0.122, 0.239, 1.0)

class AnimationDurations:
	const INSTANT: float = 0.0
	const VERY_FAST: float = 0.15
	const FAST: float = 0.25
	const NORMAL: float = 0.35
	const SLOW: float = 0.5
	const VERY_SLOW: float = 0.75

## ---------- StyleBox 工厂函数 ----------

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

static func create_card_style(base_color: Color, radius: int = 20) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = base_color
	style.border_color = Colors.PRIMARY
	style.set_border_width_all(1)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.shadow_color = Color(Colors.PRIMARY.r, Colors.PRIMARY.g, Colors.PRIMARY.b, 0.18)
	style.shadow_size = 14
	style.shadow_offset = Vector2(0, 6)
	return style

static func create_input_style(radius: int = 14) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.098, 0.067, 0.196, 0.96)
	style.border_color = Color(0.420, 0.247, 0.627, 0.8)
	style.set_border_width_all(1)
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

## 面板从屏幕外滑入（配合 open_panel 使用）
static func panel_slide_open(panel: Control, from_x_offset: float = 80.0, duration: float = 0.28) -> void:
	if not is_instance_valid(panel):
		return
	panel.modulate.a = 0.0
	panel.position.x += from_x_offset
	var tw := panel.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.set_parallel(true)
	tw.tween_property(panel, "modulate:a", 1.0, duration)
	tw.tween_property(panel, "position:x", panel.position.x - from_x_offset, duration)

## 弹出放大（打开覆层）
static func pop_open(panel: Control, duration: float = 0.22) -> void:
	if not is_instance_valid(panel):
		return
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.88, 0.88)
	var tw := panel.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.set_parallel(true)
	tw.tween_property(panel, "scale", Vector2(1.0, 1.0), duration)
	tw.tween_property(panel, "modulate:a", 1.0, duration * 0.8).set_ease(Tween.EASE_OUT)

## 摄像机震动（命中 / 技能特效）
static func camera_shake(camera: Camera2D, strength: float = 4.0, duration: float = 0.12) -> void:
	if not is_instance_valid(camera):
		return
	var origin: Vector2 = camera.offset
	var tw := camera.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	var steps: int = maxi(4, int(duration / 0.025))
	for i in steps:
		var decay: float = 1.0 - float(i) / float(steps)
		var off := Vector2(
			randf_range(-strength, strength) * decay,
			randf_range(-strength * 0.5, strength * 0.5) * decay
		)
		tw.tween_property(camera, "offset", origin + off, duration / steps)
	tw.tween_property(camera, "offset", origin, duration / steps)

## 节点白闪（命中反馈）
static func flash_white(node: CanvasItem, duration: float = 0.09) -> void:
	if not is_instance_valid(node):
		return
	var orig: Color = node.modulate
	var tw := node.create_tween().set_ease(Tween.EASE_OUT)
	tw.tween_property(node, "modulate", Color(2.5, 2.5, 2.5, 1.0), duration * 0.3)
	tw.tween_property(node, "modulate", orig, duration * 0.7)

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


## ---------- 现代游戏风 UI（深色系 暗紫 + 玫红 + 青色）----------

## 通用暗色半透明卡片面板
static func modern_glass_card(corner: int = 20, bg_alpha: float = 0.92) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.14, 0.10, 0.28, bg_alpha * 0.80)
	s.border_color = Color(0.52, 0.35, 0.78, 0.45)
	s.set_border_width_all(1)
	s.corner_radius_top_left = corner
	s.corner_radius_top_right = corner
	s.corner_radius_bottom_left = corner
	s.corner_radius_bottom_right = corner
	s.shadow_color = Color(0.0, 0.0, 0.0, 0.18)
	s.shadow_size = 14
	s.shadow_offset = Vector2(0, 6)
	return s


static func modern_line_edit_normal(corner: int = 14) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.098, 0.067, 0.196, 0.96)
	s.border_color = Color(0.420, 0.247, 0.627, 0.7)
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
	s.border_color = Color(1.0, 0.420, 0.616, 1.0)
	s.set_border_width_all(2)
	s.shadow_color = Color(1.0, 0.420, 0.616, 0.25)
	s.shadow_size = 8
	return s


## 主操作按钮 — 轻盈紫色主题
static func modern_primary_button_normal(corner: int = 22) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.38, 0.22, 0.60, 0.88)
	s.corner_radius_top_left = corner
	s.corner_radius_top_right = corner
	s.corner_radius_bottom_left = corner
	s.corner_radius_bottom_right = corner
	s.content_margin_left = 22
	s.content_margin_top = 14
	s.content_margin_right = 22
	s.content_margin_bottom = 14
	s.shadow_color = Color(0.0, 0.0, 0.0, 0.20)
	s.shadow_size = 8
	s.shadow_offset = Vector2(0, 3)
	return s


static func modern_primary_button_hover(corner: int = 22) -> StyleBoxFlat:
	var s := modern_primary_button_normal(corner)
	s.bg_color = Color(0.52, 0.34, 0.78, 0.94)
	s.shadow_size = 14
	return s


static func modern_primary_button_pressed(corner: int = 22) -> StyleBoxFlat:
	var s := modern_primary_button_normal(corner)
	s.bg_color = Color(0.26, 0.14, 0.44, 1.0)
	s.shadow_size = 4
	return s


## 对话底栏（从屏幕底部上拉）
static func modern_dialog_sheet() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.118, 0.082, 0.251, 0.96)
	s.border_color = Color(0.616, 0.306, 0.867, 0.5)
	s.set_border_width_all(1)
	s.corner_radius_top_left = 28
	s.corner_radius_top_right = 28
	s.corner_radius_bottom_left = 0
	s.corner_radius_bottom_right = 0
	s.shadow_color = Color(0.616, 0.306, 0.867, 0.28)
	s.shadow_size = 32
	s.shadow_offset = Vector2(0, -8)
	return s


## 世界 HUD 顶栏（底部圆角）
static func modern_hud_bar_bottom_round() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.06, 0.04, 0.14, 0.82)
	s.border_color = Color(0.52, 0.35, 0.78, 0.25)
	s.border_width_bottom = 1
	s.corner_radius_top_left = 0
	s.corner_radius_top_right = 0
	s.corner_radius_bottom_left = 14
	s.corner_radius_bottom_right = 14
	s.shadow_color = Color(0.0, 0.0, 0.0, 0.22)
	s.shadow_size = 10
	s.shadow_offset = Vector2(0, 5)
	return s


## HSlider 轨道
static func modern_slider_track() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.2, 0.14, 0.38, 0.7)
	s.border_color = Color(0.42, 0.25, 0.63, 0.5)
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
	s.bg_color = Color(0.616, 0.306, 0.867, 1.0)
	s.border_color = Color(0.729, 0.451, 0.941, 0.6)
	s.set_border_width_all(1)
	var r := 10
	s.corner_radius_top_left = r
	s.corner_radius_top_right = r
	s.corner_radius_bottom_left = r
	s.corner_radius_bottom_right = r
	s.shadow_color = Color(0.616, 0.306, 0.867, 0.35)
	s.shadow_size = 10
	s.shadow_offset = Vector2(0, 2)
	return s


static func modern_slider_grabber_area_highlight() -> StyleBoxFlat:
	var s := modern_slider_grabber_area()
	s.bg_color = Color(0.729, 0.451, 0.941, 1.0)
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
