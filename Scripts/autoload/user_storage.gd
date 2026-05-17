extends Node

## 登录态写入 user://，避免运行时调用 ProjectSettings.save()（导出包无法写 project.godot）。
const CFG_PATH := "user://moe_world_session.cfg"
const SESSION_SECTION := "session"
const KEY_API_BASE_URL := "api_base_url"
const KEY_USER_JSON := "user_json"
const KEY_LOGIN_UNIX := "login_unix"


func _ready() -> void:
	restore_into_project_settings()


func restore_into_project_settings() -> void:
	var cf := ConfigFile.new()
	if cf.load(CFG_PATH) != OK:
		return
	var api := str(cf.get_value(SESSION_SECTION, KEY_API_BASE_URL, ""))
	var ujson := str(cf.get_value(SESSION_SECTION, KEY_USER_JSON, ""))
	var login_unix := int(cf.get_value(SESSION_SECTION, KEY_LOGIN_UNIX, 0))
	if not api.is_empty():
		ProjectSettings.set_setting("moe_world/api_base_url", api)
	if not ujson.is_empty():
		var p := JSON.new()
		if p.parse(ujson) == OK and p.data is Dictionary:
			ProjectSettings.set_setting("moe_world/current_user", p.data)
	if login_unix > 0:
		ProjectSettings.set_setting("moe_world/session_login_unix", login_unix)


func persist_current_session() -> void:
	var user := get_current_user()
	if user.is_empty():
		clear_session_file()
		return
	_save_cfg(user, get_api_base_url(), get_session_login_unix())


func get_current_user() -> Dictionary:
	var u: Variant = ProjectSettings.get_setting("moe_world/current_user", {})
	if u is Dictionary:
		return (u as Dictionary).duplicate(true)
	return {}


func set_current_user(user: Dictionary) -> void:
	ProjectSettings.set_setting("moe_world/current_user", user.duplicate(true))


func is_logged_in() -> bool:
	var user := get_current_user()
	if user.is_empty():
		return false
	return not str(user.get("token", "")).strip_edges().is_empty()


func get_api_base_url() -> String:
	return str(ProjectSettings.get_setting("moe_world/api_base_url", "")).strip_edges()


func set_api_base_url(api_base_url: String) -> void:
	ProjectSettings.set_setting("moe_world/api_base_url", api_base_url.strip_edges())


func get_session_login_unix() -> int:
	return int(ProjectSettings.get_setting("moe_world/session_login_unix", 0))


func set_session_login_unix(login_unix: int) -> void:
	ProjectSettings.set_setting("moe_world/session_login_unix", maxi(0, login_unix))


func clear_runtime_session() -> void:
	set_current_user({})
	set_session_login_unix(0)


func clear_session_file() -> void:
	if not FileAccess.file_exists(CFG_PATH):
		return
	var da := DirAccess.open("user://")
	if da:
		da.remove("moe_world_session.cfg")


func _save_cfg(user: Dictionary, api_base_url: String, login_unix: int) -> void:
	var cf := ConfigFile.new()
	cf.set_value(SESSION_SECTION, KEY_API_BASE_URL, api_base_url)
	cf.set_value(SESSION_SECTION, KEY_USER_JSON, JSON.stringify(user))
	cf.set_value(SESSION_SECTION, KEY_LOGIN_UNIX, maxi(0, login_unix))
	var err := cf.save(CFG_PATH)
	if err != OK:
		push_warning("UserStorage: save failed (%d)" % err)
