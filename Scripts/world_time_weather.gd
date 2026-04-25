extends Node

## 世界内游戏时间 + 昼夜色调（作用于 Playfield）与简单天气（雨/雪/雾粒子与雾层）。

enum WeatherKind { CLEAR, RAIN, SNOW, FOG }

@export var minutes_advance_per_real_second: float = 3.5
@export var start_minute_of_day: float = 420.0
@export var weather_roll_min_sec: float = 72.0
@export var weather_roll_max_sec: float = 200.0

var _minute_of_day: float = 420.0
var _weather: WeatherKind = WeatherKind.CLEAR
var _next_weather_in: float = 110.0
var _day_index: int = 1

var _playfield: Node2D
var _camera: Camera2D
var _rain: CPUParticles2D
var _snow: CPUParticles2D
var _fog_canvas: CanvasLayer
var _fog_rect: ColorRect
var _hud_clock: Label


func _ready() -> void:
	_minute_of_day = start_minute_of_day
	_playfield = get_node_or_null("../Playfield") as Node2D
	_camera = get_node_or_null("../Playfield/MainCamera") as Camera2D
	if _camera == null:
		push_warning("TimeWeather: 未找到 Playfield/MainCamera，天气粒子将不会创建。")
	else:
		_rain = _make_rain_particles()
		_snow = _make_snow_particles()
		_camera.add_child(_rain)
		_camera.add_child(_snow)
		_rain.position = Vector2(0.0, -260.0)
		_snow.position = Vector2(0.0, -280.0)

	_fog_canvas = CanvasLayer.new()
	_fog_canvas.name = "WeatherFogLayer"
	_fog_canvas.layer = 2
	_fog_rect = ColorRect.new()
	_fog_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fog_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fog_rect.color = Color(0.72, 0.76, 0.82, 0.0)
	_fog_canvas.add_child(_fog_rect)
	var pr: Node = get_parent()
	if pr:
		pr.add_child(_fog_canvas)

	_next_weather_in = randf_range(weather_roll_min_sec, weather_roll_max_sec)
	_roll_random_weather()
	_apply_weather_state(true)


func bind_hud_clock(label: Label) -> void:
	_hud_clock = label


func _roll_random_weather() -> void:
	var kinds: Array[WeatherKind] = [
		WeatherKind.CLEAR, WeatherKind.RAIN, WeatherKind.SNOW, WeatherKind.FOG
	]
	_weather = kinds[randi() % kinds.size()]


func _process(delta: float) -> void:
	if _playfield == null:
		_playfield = get_node_or_null("../Playfield") as Node2D
	if _playfield == null:
		return

	_minute_of_day += minutes_advance_per_real_second * delta
	while _minute_of_day >= 1440.0:
		_minute_of_day -= 1440.0
		_day_index += 1

	_next_weather_in -= delta
	if _next_weather_in <= 0.0:
		_next_weather_in = randf_range(weather_roll_min_sec, weather_roll_max_sec)
		_roll_random_weather()
		_apply_weather_state(false)

	_apply_day_modulate()
	_refresh_hud_clock()


func _apply_day_modulate() -> void:
	var h: float = _minute_of_day / 60.0
	var c: Color = _color_for_hour(h)
	_playfield.modulate = c


func _color_for_hour(hour: float) -> Color:
	## 近似昼夜：正午偏亮白，黄昏暖色，深夜蓝紫。
	if hour < 5.0:
		return Color(0.42, 0.48, 0.72).lerp(Color(0.52, 0.56, 0.78), hour / 5.0)
	if hour < 7.0:
		return Color(0.52, 0.56, 0.78).lerp(Color(0.92, 0.9, 0.95), (hour - 5.0) / 2.0)
	if hour < 11.0:
		return Color(0.92, 0.9, 0.95).lerp(Color(1.0, 1.0, 1.0), (hour - 7.0) / 4.0)
	if hour < 16.0:
		return Color(1.0, 0.99, 0.98)
	if hour < 18.5:
		return Color(1.0, 0.99, 0.98).lerp(Color(1.0, 0.82, 0.68), (hour - 16.0) / 2.5)
	if hour < 20.5:
		return Color(1.0, 0.82, 0.68).lerp(Color(0.62, 0.58, 0.82), (hour - 18.5) / 2.0)
	if hour < 23.0:
		return Color(0.62, 0.58, 0.82).lerp(Color(0.48, 0.52, 0.75), (hour - 20.5) / 2.5)
	return Color(0.48, 0.52, 0.75).lerp(Color(0.42, 0.48, 0.72), (hour - 23.0))


func _weather_name(w: WeatherKind) -> String:
	match w:
		WeatherKind.CLEAR:
			return "晴"
		WeatherKind.RAIN:
			return "雨"
		WeatherKind.SNOW:
			return "雪"
		WeatherKind.FOG:
			return "雾"
	return "—"


func _refresh_hud_clock() -> void:
	if not is_instance_valid(_hud_clock):
		return
	var hh: int = int(_minute_of_day / 60.0)
	var mm: int = int(_minute_of_day) % 60
	var season := "春"
	var di: int = (_day_index - 1) % 4
	match di:
		0:
			season = "春"
		1:
			season = "夏"
		2:
			season = "秋"
		3:
			season = "冬"
	_hud_clock.text = "%s·第%d天  %02d:%02d  %s" % [season, _day_index, hh, mm, _weather_name(_weather)]


func _apply_weather_state(_initial: bool) -> void:
	if _rain:
		_rain.emitting = _weather == WeatherKind.RAIN
	if _snow:
		_snow.emitting = _weather == WeatherKind.SNOW
	if _fog_rect:
		var a: float = 0.0
		if _weather == WeatherKind.FOG:
			a = 0.22
		elif _weather == WeatherKind.RAIN:
			a = 0.06
		elif _weather == WeatherKind.SNOW:
			a = 0.08
		var target: Color = Color(0.75, 0.78, 0.85, a)
		if _initial:
			_fog_rect.color = target
		else:
			var tw := create_tween()
			tw.tween_property(_fog_rect, "color", target, 0.55)


func _make_rain_particles() -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.name = "RainParticles"
	p.z_index = 50
	p.amount = 260
	p.lifetime = 1.15
	p.preprocess = 0.5
	p.local_coords = true
	p.emitting = false
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(960, 40)
	p.direction = Vector2(0.15, 1.0)
	p.spread = 12.0
	p.initial_velocity_min = 520.0
	p.initial_velocity_max = 780.0
	p.scale_amount_min = 0.28
	p.scale_amount_max = 0.55
	p.color = Color(0.78, 0.86, 1.0, 0.45)
	return p


func _make_snow_particles() -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.name = "SnowParticles"
	p.z_index = 50
	p.amount = 160
	p.lifetime = 2.4
	p.preprocess = 0.5
	p.local_coords = true
	p.emitting = false
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(920, 36)
	p.direction = Vector2(0.04, 1.0)
	p.spread = 28.0
	p.initial_velocity_min = 40.0
	p.initial_velocity_max = 120.0
	p.angular_velocity_min = -40.0
	p.angular_velocity_max = 40.0
	p.scale_amount_min = 0.2
	p.scale_amount_max = 0.45
	p.color = Color(1.0, 1.0, 1.0, 0.55)
	return p
