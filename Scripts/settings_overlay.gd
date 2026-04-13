extends Control

const SETTINGS_PATH := "user://moe_world_ui_settings.cfg"

@onready var center_panel: Panel = $DimRect/CenterPanel
@onready var master_slider: HSlider = $DimRect/CenterPanel/Margin/VBox/MasterRow/HSlider
@onready var close_btn: Button = $DimRect/CenterPanel/Margin/VBox/CloseBtn
@onready var title_label: Label = $DimRect/CenterPanel/Margin/VBox/TitleLabel


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_panel_theme()
	master_slider.min_value = 0.0
	master_slider.max_value = 100.0
	master_slider.step = 1.0
	_load_settings()
	master_slider.value_changed.connect(_on_master_changed)
	close_btn.pressed.connect(close_settings)


func _apply_panel_theme() -> void:
	var col_card := Color8(255, 230, 230)
	var col_btn := Color8(255, 102, 153)
	var col_btn_h := Color8(255, 130, 175)
	var col_btn_p := Color8(230, 85, 130)
	var col_text := Color8(75, 50, 62)
	var panel_st := StyleBoxFlat.new()
	panel_st.bg_color = col_card
	panel_st.border_color = Color8(255, 200, 210)
	panel_st.set_border_width_all(2)
	panel_st.corner_radius_top_left = 24
	panel_st.corner_radius_top_right = 24
	panel_st.corner_radius_bottom_left = 24
	panel_st.corner_radius_bottom_right = 24
	center_panel.add_theme_stylebox_override("panel", panel_st)
	title_label.add_theme_font_size_override("font_size", 26)
	title_label.add_theme_color_override("font_color", col_btn)
	var btn_st := StyleBoxFlat.new()
	btn_st.bg_color = col_btn
	btn_st.corner_radius_top_left = 22
	btn_st.corner_radius_top_right = 22
	btn_st.corner_radius_bottom_left = 22
	btn_st.corner_radius_bottom_right = 22
	btn_st.content_margin_top = 12
	btn_st.content_margin_bottom = 12
	close_btn.add_theme_stylebox_override("normal", btn_st)
	var h := btn_st.duplicate()
	h.bg_color = col_btn_h
	close_btn.add_theme_stylebox_override("hover", h)
	var p := btn_st.duplicate()
	p.bg_color = col_btn_p
	close_btn.add_theme_stylebox_override("pressed", p)
	close_btn.add_theme_color_override("font_color", Color8(255, 255, 255))
	close_btn.add_theme_font_size_override("font_size", 18)
	var hint: Label = $DimRect/CenterPanel/Margin/VBox/HintLabel
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", col_text)


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
