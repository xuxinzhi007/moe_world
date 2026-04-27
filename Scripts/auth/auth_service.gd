extends Node

signal login_success(token: String, user_data: Dictionary)
signal login_failed(error: String)
signal register_success(user_data: Dictionary)
signal register_failed(error: String)
signal config_fetched(api_base_url: String)
signal config_failed(error: String)
signal server_status_changed(is_online: bool)

const GITHUB_CONFIG_URL = "https://raw.githubusercontent.com/xuxinzhi007/moe_social/main/lib/config/moe_api.json"
## 线上容器 REST 根路径（须以 /api 结尾）；冷启动优先于此，而非 GitHub moe_api.json。
const DEFAULT_API_BASE_URL = "http://47.106.175.49:8888/api"
## 若为 true：GitHub 返回的 api_base_url 可覆盖当前地址。默认 false，避免远程仍指向 ngrok 时抢回旧隧道。
const GITHUB_URL_MAY_OVERRIDE_PRIMARY: bool = false
const HEALTH_CHECK_INTERVAL = 5.0
const CONFIG_CACHE_FILE = "user://moe_api_cache.cfg"
const CONFIG_CACHE_EXPIRY_DAYS = 7
const SERVER_RETRY_COUNT = 3
const SERVER_RETRY_DELAY = 2.0
const GITHUB_CHECK_INTERVAL = 7200.0

var api_base_url: String = DEFAULT_API_BASE_URL
var current_request: HTTPRequest
var is_auth_processing: bool = false
var is_server_online: bool = false
var health_check_timer: Timer
var health_check_request: HTTPRequest
var _cache_timer: Timer
var _github_fetch_in_progress: bool = false
var _server_retry_count: int = 0
var _last_github_fetch_time: float = 0.0

static var global_api_base_url: String = ""
static var global_is_api_ready: bool = false
static var global_is_server_online: bool = false
static var global_has_fetched_config: bool = false


func _ready() -> void:
	print("🔐 认证服务已初始化")
	health_check_timer = Timer.new()
	health_check_timer.wait_time = HEALTH_CHECK_INTERVAL
	health_check_timer.timeout.connect(_check_server_status)
	add_child(health_check_timer)
	
	_cache_timer = Timer.new()
	_cache_timer.wait_time = GITHUB_CHECK_INTERVAL
	_cache_timer.timeout.connect(_refresh_config_from_github)
	add_child(_cache_timer)
	
	if global_has_fetched_config:
		print("🔄 使用已缓存的配置")
		api_base_url = global_api_base_url
		is_server_online = global_is_server_online
		config_fetched.emit(api_base_url)
		server_status_changed.emit(is_server_online)
		_check_server_status()
		health_check_timer.start()
		_cache_timer.start()
		_refresh_config_from_github()
	else:
		_bootstrap_api_config_cold_start()


func _load_cached_config_url() -> String:
	if not FileAccess.file_exists(CONFIG_CACHE_FILE):
		return ""
	
	var file := FileAccess.open(CONFIG_CACHE_FILE, FileAccess.READ)
	if not file:
		return ""
	
	var cached_url: String = ""
	var cache_time: int = 0
	
	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		if line.begins_with("url="):
			cached_url = line.substr(4)
		elif line.begins_with("time="):
			cache_time = line.substr(5).to_int()
	
	file.close()
	
	if cached_url.is_empty():
		return ""
	
	var current_time := Time.get_unix_time_from_system()
	var expiry_seconds := CONFIG_CACHE_EXPIRY_DAYS * 86400.0
	
	if current_time - cache_time > expiry_seconds:
		print("⏰ 缓存已过期，删除旧缓存")
		DirAccess.remove_absolute(CONFIG_CACHE_FILE)
		return ""
	
	return cached_url


func _is_legacy_tunnel_url(url: String) -> bool:
	var u := url.to_lower()
	return u.contains("ngrok") or u.contains("localtunnel") or u.contains("serveo.net")


func _bootstrap_api_config_cold_start() -> void:
	var cached_url := _load_cached_config_url()
	if cached_url.is_empty() or _is_legacy_tunnel_url(cached_url):
		if not cached_url.is_empty():
			print("📦 忽略旧隧道类本地 API 缓存，改用内置线上: ", DEFAULT_API_BASE_URL)
		_start_with_url(DEFAULT_API_BASE_URL)
		_save_cached_config_url(api_base_url)
	else:
		print("📦 从本地缓存加载 API: ", cached_url)
		_start_with_url(cached_url)
	_refresh_config_from_github()


func _save_cached_config_url(url: String) -> void:
	var file := FileAccess.open(CONFIG_CACHE_FILE, FileAccess.WRITE)
	if not file:
		push_error("无法保存配置缓存到: ", CONFIG_CACHE_FILE)
		return
	
	var current_time := Time.get_unix_time_from_system()
	file.store_line("url=" + url)
	file.store_line("time=%d" % current_time)
	file.close()
	print("💾 配置已缓存到本地: ", url)


func _refresh_config_from_github() -> void:
	if _github_fetch_in_progress:
		return
	
	var current_time := Time.get_unix_time_from_system()
	if current_time - _last_github_fetch_time < GITHUB_CHECK_INTERVAL:
		return
	
	_github_fetch_in_progress = true
	_last_github_fetch_time = current_time
	
	var request := HTTPRequest.new()
	add_child(request)
	request.request_completed.connect(func(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray):
		_on_github_refresh_completed(result, code, body, request)
	)
	
	var error := request.request(GITHUB_CONFIG_URL, PackedStringArray(), HTTPClient.METHOD_GET, "")
	if error != OK:
		print("⚠️  GitHub 配置刷新失败")
		_github_fetch_in_progress = false
		request.queue_free()


func _on_github_refresh_completed(result: int, code: int, body: PackedByteArray, request: HTTPRequest) -> void:
	request.queue_free()
	_github_fetch_in_progress = false
	
	if result == HTTPRequest.RESULT_SUCCESS and code == 200:
		var json := JSON.new()
		if json.parse(body.get_string_from_utf8()) == OK:
			var data: Dictionary = json.data as Dictionary
			if data.has("api_base_url"):
				var new_url: String = data["api_base_url"] as String
				if not new_url.is_empty():
					while new_url.ends_with("/"):
						new_url = new_url.substr(0, new_url.length() - 1)
					if not new_url.ends_with("/api"):
						new_url = new_url + "/api"
					
					if new_url != api_base_url:
						if GITHUB_URL_MAY_OVERRIDE_PRIMARY:
							print("🔄 检测到新的 API 地址，更新配置: ", new_url)
							_save_cached_config_url(new_url)
							api_base_url = new_url
							global_api_base_url = new_url
							config_fetched.emit(new_url)
							_check_server_status()
						else:
							print("ℹ️  GitHub 提供其他 API（已禁覆盖，沿用当前）: ", new_url)
					else:
						print("✅ API 地址未变化，刷新缓存时间")
						_save_cached_config_url(api_base_url)
					return
	
	print("⚠️  GitHub 配置刷新失败，保持使用当前配置")


func _start_with_url(url: String) -> void:
	var final_url := url
	while final_url.ends_with("/"):
		final_url = final_url.substr(0, final_url.length() - 1)
	if not final_url.ends_with("/api"):
		final_url = final_url + "/api"
	
	api_base_url = final_url
	global_api_base_url = final_url
	global_has_fetched_config = true
	global_is_api_ready = true
	
	print("📍 使用 API 基址: ", api_base_url)
	config_fetched.emit(api_base_url)
	_check_server_status()
	health_check_timer.start()
	_cache_timer.start()


func _check_server_status() -> void:
	if health_check_request:
		return
	
	print("🔍 检查服务器状态...")
	health_check_request = HTTPRequest.new()
	add_child(health_check_request)
	health_check_request.request_completed.connect(func(result: int, code: int, _h: PackedStringArray, body: PackedByteArray):
		_on_server_status_check_completed(result, code, body, health_check_request)
	)
	var url := api_base_url + "/public/client-config"
	print("🌐 请求 URL: ", url)
	var error := health_check_request.request(url, PackedStringArray(), HTTPClient.METHOD_GET, "")
	if error != OK:
		_handle_server_check_failure()


func _handle_server_check_failure() -> void:
	_server_retry_count += 1
	
	if _server_retry_count < SERVER_RETRY_COUNT:
		print("⚠️  服务器检查失败，第 %d/%d 次重试..." % [_server_retry_count, SERVER_RETRY_COUNT])
		await get_tree().create_timer(SERVER_RETRY_DELAY).timeout
		_check_server_status()
	else:
		print("❌ 服务器连续 %d 次不可用，尝试从 GitHub 获取新地址..." % SERVER_RETRY_COUNT)
		_server_retry_count = 0
		_refresh_config_from_github()
		_set_server_offline()
		if health_check_request:
			health_check_request.queue_free()
			health_check_request = null


func _on_server_status_check_completed(result: int, code: int, _body: PackedByteArray, request: HTTPRequest) -> void:
	_server_retry_count = 0
	var online := (result == HTTPRequest.RESULT_SUCCESS and code == 200)
	is_server_online = online
	global_is_server_online = online
	print("✅ 服务器状态: %s" % ("在线" if online else "离线"))
	server_status_changed.emit(online)
	request.queue_free()
	health_check_request = null


func _set_server_offline() -> void:
	is_server_online = false
	global_is_server_online = false
	server_status_changed.emit(false)


func login(username: String, password: String, email: String = "") -> void:
	if is_auth_processing:
		return
	
	is_auth_processing = true
	var data := {"password": password}
	if not username.is_empty():
		data["username"] = username
	if not email.is_empty():
		data["email"] = email
	_make_request("/user/login", data, _on_login_response)


func register(username: String, password: String, email: String) -> void:
	if is_auth_processing:
		return
	
	is_auth_processing = true
	var data := {"username": username, "password": password, "email": email}
	_make_request("/user/register", data, _on_register_response)


func _make_request(endpoint: String, data: Dictionary, callback: Callable) -> void:
	current_request = HTTPRequest.new()
	add_child(current_request)
	current_request.request_completed.connect(func(r: int, code: int, _h: PackedStringArray, body: PackedByteArray):
		_on_request_completed(r, code, body, callback)
	)
	var hdrs := PackedStringArray(["Content-Type: application/json"])
	var url := api_base_url + endpoint
	print("📤 发送请求到: %s" % url)
	var error := current_request.request(url, hdrs, HTTPClient.METHOD_POST, JSON.stringify(data))
	if error != OK:
		is_auth_processing = false
		callback.call(false, "请求发送失败")


func _on_request_completed(result: int, code: int, body: PackedByteArray, callback: Callable) -> void:
	is_auth_processing = false
	
	if current_request:
		current_request.queue_free()
		current_request = null
	
	if result != HTTPRequest.RESULT_SUCCESS:
		callback.call(false, "网络请求失败")
		return
	
	var json := JSON.new()
	if json.parse(body.get_string_from_utf8()) != OK:
		callback.call(false, "数据解析失败")
		return
	
	var response_data: Dictionary = json.data as Dictionary
	callback.call(true, code, response_data)


func _on_login_response(success: bool, resp_or_err: Variant, data: Dictionary = {}) -> void:
	if not success:
		login_failed.emit(resp_or_err as String)
		return
	
	var base_resp: Dictionary = data as Dictionary
	if base_resp.get("success", false):
		var login_data: Dictionary = base_resp.get("data", {}) as Dictionary
		login_success.emit(login_data.get("token", ""), login_data.get("user", {}))
	else:
		login_failed.emit(base_resp.get("message", "登录失败"))


func _on_register_response(success: bool, resp_or_err: Variant, data: Dictionary = {}) -> void:
	if not success:
		register_failed.emit(resp_or_err as String)
		return
	
	var base_resp: Dictionary = data as Dictionary
	if base_resp.get("success", false):
		register_success.emit(base_resp.get("data", {}))
	else:
		register_failed.emit(base_resp.get("message", "注册失败"))
