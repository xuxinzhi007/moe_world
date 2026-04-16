extends Node

signal login_success(token: String, user_data: Dictionary)
signal login_failed(error: String)
signal register_success(user_data: Dictionary)
signal register_failed(error: String)
signal config_fetched(api_base_url: String)
signal config_failed(error: String)
signal server_status_changed(is_online: bool)

const GITHUB_CONFIG_URL = "https://raw.githubusercontent.com/xuxinzhi007/moe_social/main/lib/config/moe_api.json"
const DEFAULT_API_BASE_URL = "http://localhost:8888/api"
const HEALTH_CHECK_INTERVAL = 5.0

var api_base_url: String = DEFAULT_API_BASE_URL
var current_request: HTTPRequest
var is_auth_processing: bool = false
var is_server_online: bool = false
var health_check_timer: Timer
var health_check_request: HTTPRequest

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
	
	if global_has_fetched_config:
		print("🔄 使用已缓存的配置")
		api_base_url = global_api_base_url
		is_server_online = global_is_server_online
		config_fetched.emit(api_base_url)
		server_status_changed.emit(is_server_online)
		_check_server_status()
		health_check_timer.start()
	else:
		call_deferred("_fetch_config_and_start")


func _fetch_config_and_start() -> void:
	print("🌐 从 GitHub 获取配置...")
	var request := HTTPRequest.new()
	add_child(request)
	request.request_completed.connect(func(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray):
		_on_config_fetched(result, code, body, request)
	)
	var error := request.request(GITHUB_CONFIG_URL, PackedStringArray(), HTTPClient.METHOD_GET, "")
	if error != OK:
		print("⚠️  获取 GitHub 配置失败，使用默认地址")
		_start_with_url(DEFAULT_API_BASE_URL)
		request.queue_free()


func _on_config_fetched(result: int, code: int, body: PackedByteArray, request: HTTPRequest) -> void:
	request.queue_free()
	
	if result == HTTPRequest.RESULT_SUCCESS and code == 200:
		var json = JSON.new()
		if json.parse(body.get_string_from_utf8()) == OK:
			var data = json.data as Dictionary
			if data.has("api_base_url"):
				var url := data["api_base_url"] as String
				if not url.is_empty():
					while url.ends_with("/"):
						url = url.substr(0, url.length() - 1)
					if not url.ends_with("/api"):
						url = url + "/api"
					print("✅ 从 GitHub 获取到 API 地址: ", url)
					_start_with_url(url)
					return
	
	print("⚠️  GitHub 配置获取失败，使用默认地址")
	_start_with_url(DEFAULT_API_BASE_URL)


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
		_set_server_offline()
		health_check_request.queue_free()
		health_check_request = null


func _on_server_status_check_completed(result: int, code: int, _body: PackedByteArray, request: HTTPRequest) -> void:
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
	var data = {"password": password}
	if not username.is_empty():
		data["username"] = username
	if not email.is_empty():
		data["email"] = email
	_make_request("/user/login", data, _on_login_response)


func register(username: String, password: String, email: String) -> void:
	if is_auth_processing:
		return
	
	is_auth_processing = true
	var data = {"username": username, "password": password, "email": email}
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
	
	var json = JSON.new()
	if json.parse(body.get_string_from_utf8()) != OK:
		callback.call(false, "数据解析失败")
		return
	
	var response_data = json.data as Dictionary
	callback.call(true, code, response_data)


func _on_login_response(success: bool, resp_or_err: Variant, data: Dictionary = {}) -> void:
	if not success:
		login_failed.emit(resp_or_err as String)
		return
	
	var base_resp = data as Dictionary
	if base_resp.get("success", false):
		var login_data = base_resp.get("data", {}) as Dictionary
		login_success.emit(login_data.get("token", ""), login_data.get("user", {}))
	else:
		login_failed.emit(base_resp.get("message", "登录失败"))


func _on_register_response(success: bool, resp_or_err: Variant, data: Dictionary = {}) -> void:
	if not success:
		register_failed.emit(resp_or_err as String)
		return
	
	var base_resp = data as Dictionary
	if base_resp.get("success", false):
		register_success.emit(base_resp.get("data", {}))
	else:
		register_failed.emit(base_resp.get("message", "注册失败"))
