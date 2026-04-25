extends Control

const SETTINGS_PATH := "user://moe_world_ui_settings.cfg"
const UiTheme := preload("res://Scripts/ui_theme.gd")

@onready var dim_rect: ColorRect = $DimRect
@onready var center_panel: Panel = $DimRect/CenterPanel
@onready var master_slider: HSlider = $DimRect/CenterPanel/Margin/VBox/MasterRow/HSlider
@onready var master_lbl: Label = $DimRect/CenterPanel/Margin/VBox/MasterRow/MasterLbl
@onready var close_btn: Button = $DimRect/CenterPanel/Margin/VBox/CloseBtn
@onready var title_label: Label = $DimRect/CenterPanel/Margin/VBox/TitleLabel


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim_rect.color = Color(0.1, 0.03, 0.07, 0.58)
	_apply_panel_theme()
	master_slider.min_value = 0.0
	master_slider.max_value = 100.0
	master_slider.step = 1.0
	_load_settings()
	master_slider.value_changed.connect(_on_master_changed)
	close_btn.pressed.connect(close_settings)


func _apply_panel_theme() -> void:
	var col_text := Color8(72, 48, 62)
	var col_primary := Color8(255, 95, 150)
	center_panel.add_theme_stylebox_override("panel", UiTheme.modern_glass_card(26, 0.94))
	title_label.add_theme_font_size_override("font_size", 28)
	title_label.add_theme_color_override("font_color", col_primary)
	master_lbl.add_theme_font_size_override("font_size", 17)
	master_lbl.add_theme_color_override("font_color", col_text)
	close_btn.add_theme_stylebox_override("normal", UiTheme.modern_primary_button_normal(22))
	close_btn.add_theme_stylebox_override("hover", UiTheme.modern_primary_button_hover(22))
	close_btn.add_theme_stylebox_override("pressed", UiTheme.modern_primary_button_pressed(22))
	close_btn.add_theme_color_override("font_color", Color8(255, 255, 255))
	close_btn.add_theme_font_size_override("font_size", 18)
	var hint: Label = $DimRect/CenterPanel/Margin/VBox/HintLabel
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color8(110, 82, 98))
	var st := Theme.new()
	st.set_stylebox("slider", "HSlider", UiTheme.modern_slider_track())
	st.set_stylebox("grabber_area", "HSlider", UiTheme.modern_slider_grabber_area())
	st.set_stylebox("grabber_area_highlight", "HSlider", UiTheme.modern_slider_grabber_area_highlight())
	master_slider.theme = st


func open_settings() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = true


func close_settings() -> void:
	_save_settings()
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _on_master_changed(value: float) -> void:
	var linear: float = clampf(value / 100.0, 0.0001, 1.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(linear))


func _load_settings() -> void:
	var v := 80.0
	if FileAccess.file_exists(SETTINGS_PATH):
		var cf := ConfigFile.new()
		if cf.load(SETTINGS_PATH) == OK:
			v = float(cf.get_value("audio", "master_percent", 80.0))
	master_slider.set_value_no_signal(v)
	_on_master_changed(v)


func _save_settings() -> void:
	var cf := ConfigFile.new()
	cf.set_value("audio", "master_percent", master_slider.value)
	cf.save(SETTINGS_PATH)
