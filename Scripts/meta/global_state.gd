extends Node
signal global_api_ready(api_base_url: String)
signal global_server_status_changed(is_online: bool)

var api_base_url: String = ""
var is_api_ready: bool = false
var is_server_online: bool = false
var has_fetched_config: bool = false

func _ready() -> void:
	print("🌍 全局状态管理器初始化")

func reset() -> void:
	api_base_url = ""
	is_api_ready = false
	is_server_online = false
	has_fetched_config = false

func set_api_ready(url: String) -> void:
	api_base_url = url
	is_api_ready = true
	global_api_ready.emit(url)

func set_server_online(online: bool) -> void:
	is_server_online = online
	global_server_status_changed.emit(online)
