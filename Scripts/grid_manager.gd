extends Node2D

# ========== 可配置参数（编辑器调整） ==========
@export var grid_cell_size: Vector2 = Vector2(64, 64)  # 格子大小
@export var grid_color: Color = Color(0.5, 0.5, 0.5, 0.3)  # 网格线颜色
@export var turret_color: Color = Color(1, 0, 0, 0.8)  # 炮台默认颜色
@export var turret_size_ratio: float = 0.8  # 炮台占格子的比例
@export var map_boundary: Rect2 = Rect2(0, 0, 1500, 1200)
@export var draw_only_rooms: bool = true  # true=仅房间内显示网格，false=整张地图显示网格
@export var show_boundary_outline: bool = true
@export var boundary_color: Color = Color(1, 0.2, 0.2, 0.9)
@export var boundary_line_width: float = 3.0

# ========== 数据存储 ==========
var built_buildings: Dictionary = {}  # 已建造建筑 {Vector2i: 建筑节点}
var building_types = {  # 建筑类型配置（方便扩展）
	"turret": {
		"cost": 50,  # 建造成本
		"name": "炮台",
		"color": turret_color
	}
}

# ========== 节点引用 ==========
@onready var camera: Camera2D = get_node_or_null("/root/Main/Player/Camera2D")  # 摄像机路径（根据你的场景调整）
@onready var map_generator: Node2D = get_node_or_null("/root/Main/MapGenerator")

# ========== 核心绘制逻辑（按地图边界生成） ==========
func _draw() -> void:
	# 容错：避免视口未初始化导致的错误
	if not is_instance_valid(get_viewport()):
		return

	# 根据模式绘制网格：整图 or 仅房间
	if draw_only_rooms and map_generator and map_generator.has_method("get_rooms"):
		var rooms: Array = map_generator.get_rooms()
		for room_data in rooms:
			if room_data.has("rect"):
				_draw_grid_in_rect(room_data["rect"])
	else:
		_draw_grid_in_rect(map_boundary)

	if show_boundary_outline:
		draw_rect(map_boundary, boundary_color, false, boundary_line_width)

# ========== 坐标转换（适配大地图，不再限制屏幕范围） ==========
func screen_to_grid(world_pos: Vector2) -> Vector2i:
	# 容错：视口未初始化时返回无效坐标
	if not is_instance_valid(get_viewport()):
		return Vector2i(-1, -1)

	# 2. 转换为地图网格坐标（基于map_boundary的起始位置）
	var grid_x = int(floor((world_pos.x - map_boundary.position.x) / grid_cell_size.x))
	var grid_y = int(floor((world_pos.y - map_boundary.position.y) / grid_cell_size.y))
	
	# 3. 容错：限制坐标在地图合法范围
	var max_grid_x = int(floor(map_boundary.size.x / grid_cell_size.x))
	var max_grid_y = int(floor(map_boundary.size.y / grid_cell_size.y))
	grid_x = clamp(grid_x, 0, max_grid_x)
	grid_y = clamp(grid_y, 0, max_grid_y)
	
	return Vector2i(grid_x, grid_y)

# ========== 辅助：网格坐标转世界坐标（适配大地图） ==========
func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(
		map_boundary.position.x + grid_pos.x * grid_cell_size.x + grid_cell_size.x/2,
		map_boundary.position.y + grid_pos.y * grid_cell_size.y + grid_cell_size.y/2
	)

# ========== 建造检测 ==========
func is_grid_available(grid_pos: Vector2i) -> bool:
	# 容错：无效坐标直接返回不可建造
	if grid_pos.x < 0 or grid_pos.y < 0:
		return false
	# 检查是否超出地图网格范围
	var max_grid_x = int(floor(map_boundary.size.x / grid_cell_size.x))
	var max_grid_y = int(floor(map_boundary.size.y / grid_cell_size.y))
	if grid_pos.x > max_grid_x or grid_pos.y > max_grid_y:
		return false
	# 仅房间网格模式下，限制建筑必须在房间内
	if draw_only_rooms and not _is_grid_in_any_room(grid_pos):
		return false
	return not built_buildings.has(grid_pos)

# ========== 建造炮台（适配大地图坐标） ==========
func build_turret(grid_pos: Vector2i) -> bool:
	# 前置检测
	if not is_grid_available(grid_pos):
		print("❌ 格子(%d,%d)已被占用/超出地图范围！" % [grid_pos.x, grid_pos.y])
		return false
	
	# 1. 创建炮台节点（绑定攻击脚本）
	var turret = CharacterBody2D.new()
	turret.name = "Turret_%d_%d" % [grid_pos.x, grid_pos.y]
	turret.set_meta("grid_pos", grid_pos)  # 记录炮台所在格子
	turret.set_meta("building_type", "turret")  # 标记建筑类型

	# 2. 计算世界坐标（基于地图边界的格子中心）
	var world_pos = grid_to_world(grid_pos)
	turret.global_position = world_pos

	# 3. 添加可视化（ColorRect占位）
	var color_rect = ColorRect.new()
	color_rect.size = grid_cell_size * turret_size_ratio
	color_rect.anchor_center = Vector2(0.5, 0.5)
	color_rect.color = building_types["turret"]["color"]
	turret.add_child(color_rect)

	# 4. 绑定炮台攻击脚本（后续实现攻击逻辑时直接用）
	# turret_script = load("res://turret.gd")
	# turret.set_script(turret_script)

	# 5. 添加到场景+记录
	add_child(turret)
	built_buildings[grid_pos] = turret
	print("✅ 炮台已建造在格子(%d,%d) 世界坐标(%d,%d)" % [grid_pos.x, grid_pos.y, world_pos.x, world_pos.y])
	return true

# ========== 扩展功能：移除建筑（方便后续扩展） ==========
func remove_building(grid_pos: Vector2i) -> bool:
	if not built_buildings.has(grid_pos):
		print("❌ 格子(%d,%d)无建筑可移除！" % [grid_pos.x, grid_pos.y])
		return false
	
	# 移除节点+清理数据
	var building = built_buildings[grid_pos]
	if is_instance_valid(building):
		building.queue_free()
	built_buildings.erase(grid_pos)
	print("✅ 格子(%d,%d)建筑已移除" % [grid_pos.x, grid_pos.y])
	return true

# ========== 扩展功能：获取建筑信息（方便UI显示） ==========
func get_building_info(grid_pos: Vector2i) -> Dictionary:
	if not built_buildings.has(grid_pos):
		return {"valid": false}
	
	var building = built_buildings[grid_pos]
	return {
		"valid": true,
		"type": building.get_meta("building_type", "unknown"),
		"node": building,
		"world_pos": building.global_position
	}

# ========== 场景刷新 + 摄像机跟随 ==========
func _ready() -> void:
	_sync_boundary_from_map_generator()
	# 强制触发绘制
	queue_redraw()

func _viewport_resized() -> void:
	# 窗口大小变化时重新绘制网格
	queue_redraw()

func _process(_delta: float) -> void:
	# 若运行时调整了 MapGenerator 边界，网格自动同步
	_sync_boundary_from_map_generator()

func _sync_boundary_from_map_generator() -> void:
	if map_generator and map_generator.has_method("get_map_boundary"):
		var next_boundary: Rect2 = map_generator.get_map_boundary()
		if next_boundary != map_boundary:
			map_boundary = next_boundary
			queue_redraw()

func _draw_grid_in_rect(rect: Rect2) -> void:
	var start_x = rect.position.x
	var start_y = rect.position.y
	var end_x = rect.position.x + rect.size.x
	var end_y = rect.position.y + rect.size.y

	var step_x = int(grid_cell_size.x)
	var step_y = int(grid_cell_size.y)
	if step_x <= 0 or step_y <= 0:
		return

	for x in range(int(start_x), int(end_x) + step_x, step_x):
		draw_line(Vector2(x, start_y), Vector2(x, end_y), grid_color, 1)

	for y in range(int(start_y), int(end_y) + step_y, step_y):
		draw_line(Vector2(start_x, y), Vector2(end_x, y), grid_color, 1)

func _is_grid_in_any_room(grid_pos: Vector2i) -> bool:
	if not map_generator or not map_generator.has_method("get_rooms"):
		return true

	var center_pos = grid_to_world(grid_pos)
	var rooms: Array = map_generator.get_rooms()
	for room_data in rooms:
		if room_data.has("rect") and room_data["rect"].has_point(center_pos):
			return true
	return false
