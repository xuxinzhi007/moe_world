extends Node

signal login_success(token: String, user_data: Dictionary)
signal login_failed(error: String)
signal register_success(user_data: Dictionary)
signal register_failed(error: String)
signal config_fetched(api_base_url: String)
signal config_failed(error: String)

const DEFAULT_API_BASE_URL = "http://localhost:8888/api"
var api_base_url: String = DEFAULT_API_BASE_URL

var current_request: HTTPRequest
var is_auth_processing: bool = false

func _ready() -> void:
	print("🔐 认证服务已初始化")
	print("📡 正在尝试获取 API 配置...")
	_fetch_api_config()

func _fetch_api_config() -> void:
	var request = HTTPRequest.new()
	add_child(request)
	
	request.request_completed.connect(func(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
		_on_config_fetched(result, response_code, headers, body)
		request.queue_free()
	)
	
	var url = DEFAULT_API_BASE_URL + "/public/client-config"
	print("🔍 尝试获取配置: %s" % url)
	
	var error = request.request(url, [], HTTPClient.METHOD_GET, "")
	if error != OK:
		print("⚠️  无法发送配置请求，使用默认地址")
		_on_use_default_config()

func _on_config_fetched(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	print("📦 配置请求完成，结果: %d, 状态码: %d" % [result, response_code])
	
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		print("⚠️  配置获取失败，使用默认地址")
		_on_use_default_config()
		return
	
	var json = JSON.new()
	var parse_result = json.parse(body.get_string_from_utf8())
	
	if parse_result != OK:
		print("⚠️  配置解析失败，使用默认地址")
		_on_use_default_config()
		return
	
	var response_data = json.data as Dictionary
	var fetched_url = response_data.get("api_base_url", "")
	
	print("🔍 获取到的配置地址: %s" % fetched_url)
	
	if fetched_url.is_empty():
		print("⚠️  配置地址为空，使用默认地址")
		_on_use_default_config()
		return
	
	if fetched_url == "xuxinzhi19@gmail.com":
		print("⚠️  配置地址为邮箱，不是有效 API 地址，使用默认地址")
		_on_use_default_config()
		return
	
	api_base_url = fetched_url
	print("✅ 已获取 API 配置: %s" % api_base_url)
	config_fetched.emit(api_base_url)

func _on_use_default_config() -> void:
	api_base_url = DEFAULT_API_BASE_URL
	print("📍 使用默认 API 地址: %s" % api_base_url)
	config_fetched.emit(api_base_url)

func login(username: String, password: String, email: String = "") -> void:
	if is_auth_processing:
		print("⚠️  上一个请求还在处理中")
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
		print("⚠️  上一个请求还在处理中")
		return
	
	is_auth_processing = true
	var data = {"username": username, "password": password, "email": email}
	_make_request("/user/register", data, _on_register_response)

func _make_request(endpoint: String, data: Dictionary, callback: Callable) -> void:
	current_request = HTTPRequest.new()
	add_child(current_request)
	
	current_request.request_completed.connect(func(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
		_on_request_completed(result, response_code, headers, body, callback)
	)
	
	var headers = ["Content-Type: application/json"]
	var json_string = JSON.stringify(data)
	var url = api_base_url + endpoint
	print("📤 发送请求到: %s" % url)
	var error = current_request.request(url, headers, HTTPClient.METHOD_POST, json_string)
	
	if error != OK:
		print("❌ 请求失败: %d" % error)
		is_auth_processing = false
		callback.call(false, "请求发送失败")

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray, callback: Callable) -> void:
	is_auth_processing = false
	
	if current_request:
		current_request.queue_free()
		current_request = null
	
	print("📡 请求完成，结果: %d, 状态码: %d" % [result, response_code])
	
	if result != HTTPRequest.RESULT_SUCCESS:
		print("❌ 网络请求失败，结果: %d" % result)
		callback.call(false, "网络请求失败")
		return
	
	var json = JSON.new()
	var parse_result = json.parse(body.get_string_from_utf8())
	
	if parse_result != OK:
		print("❌ JSON解析失败")
		print("响应内容: ", body.get_string_from_utf8())
		callback.call(false, "数据解析失败")
		return
	
	var response_data = json.data as Dictionary
	print("📦 响应数据: ", response_data)
	callback.call(true, response_code, response_data)

func _on_login_response(success: bool, response_code_or_error: Variant, response_data: Dictionary = {}) -> void:
	if not success:
		var error = response_code_or_error as String
		login_failed.emit(error)
		return
	
	var response_code = response_code_or_error as int
	var base_resp = response_data as Dictionary
	
	if base_resp.get("success", false):
		var login_data = base_resp.get("data", {}) as Dictionary
		var token = login_data.get("token", "")
		var user_data = login_data.get("user", {}) as Dictionary
		print("✅ 登录成功！Token: %s" % token.left(20) + "...")
		login_success.emit(token, user_data)
	else:
		var error_msg = base_resp.get("message", "登录失败")
		print("❌ 登录失败: %s" % error_msg)
		login_failed.emit(error_msg)

func _on_register_response(success: bool, response_code_or_error: Variant, response_data: Dictionary = {}) -> void:
	if not success:
		var error = response_code_or_error as String
		register_failed.emit(error)
		return
	
	var _response_code = response_code_or_error as int
	var base_resp = response_data as Dictionary
	
	if base_resp.get("success", false):
		var user_data = base_resp.get("data", {}) as Dictionary
		print("✅ 注册成功！用户: %s" % user_data.get("username", ""))
		register_success.emit(user_data)
	else:
		var error_msg = base_resp.get("message", "注册失败")
		print("❌ 注册失败: %s" % error_msg)
		register_failed.emit(error_msg)
