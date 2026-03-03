# 适配 Godot 4.4 稳定版
extends CharacterBody2D

# ========== 变量定义（必须放在所有函数之前） ==========
# 移动速度（可在编辑器里拖动修改）
@export var move_speed: float = 350.0

# 房间系统相关变量（核心新增）
@onready var map_generator: Node2D = get_node_or_null("/root/Main/MapGenerator")
var current_room: Dictionary = {}  # 当前所在房间数据
var is_near_door: bool = false  # 是否靠近门
var door_detection_range: float = 64.0  # 门检测距离（像素）
var last_door_tip_time: float = 0.0  # 门提示防刷屏时间（修复static报错）
@export var confine_player_to_map: bool = true
var has_forced_spawn_to_room: bool = false


# 躺床发育相关变量
@export var gold_per_second: int = 1  # 躺床每秒获得1金币
var is_in_bed: bool = false            # 是否躺床
var is_near_bed: bool = false          # 是否靠近床
var current_gold: int = 0              # 当前金币（整数）
var gold_accumulator: float = 0.0      # 金币累加器（用于精确计时）

# 节点引用（集中放在这里，更规范）
@onready var bed_trigger: Area2D = get_node_or_null("/root/Main/Bed/BedTrigger")
@onready var bed_node: StaticBody2D = get_node_or_null("/root/Main/Bed")
@onready var gold_label: Label = get_node_or_null("/root/Main/UI/GoldLabel")
@onready var build_menu: PanelContainer = get_node_or_null("/root/Main/UI/BuildMenu")
@onready var grid_manager: Node2D = get_node_or_null("/root/Main/GridManager") # 新增网格管理器引用

# ========== 物理帧更新（核心逻辑） ==========
func _physics_process(delta: float) -> void:
	# ========== 新增：每帧更新当前房间 + 门检测 ==========
	_update_current_room()
	_ensure_player_spawn_in_room()
	_update_current_room()
	_update_door_detection()

	# ========== 1. 统一处理左键点击（适配房间限制） ==========
	if Input.is_action_just_pressed("left_click"):
		# 躺床状态不处理菜单
		if is_in_bed:
			return
		
		var mouse_global = get_global_mouse_position()
		# 检查是否在自己房间内（核心限制）
		var is_in_player_room = _is_point_in_player_room(mouse_global)
		
		# 菜单已显示的情况
		if build_menu and build_menu.visible:
			var is_mouse_in_menu = build_menu.get_global_rect().has_point(mouse_global)
			# 鼠标在菜单内 → 不处理（让按钮接收点击）
			if is_mouse_in_menu:
				pass
			# 鼠标在菜单外 → 关闭菜单
			else:
				build_menu.hide_menu()
		# 菜单未显示的情况 → 先检查房间，再弹出菜单
		else:
			if not is_in_player_room:
				print("❌ 只能在自己房间内建造！")
				return
			
			if grid_manager and build_menu:
				var mouse_local = get_viewport().get_mouse_position()
				var grid_pos = grid_manager.screen_to_grid(mouse_global)
				build_menu.show_menu(mouse_local, grid_pos)

	# ========== 新增：E键交互（开关门） ==========
	if Input.is_action_just_pressed("lie_bed") and not is_in_bed:
		if is_near_door and current_room:
			map_generator.toggle_door(current_room)

	# ========== 2. 躺床/起床逻辑（原有） ==========
	if Input.is_action_just_pressed("lie_bed") and is_near_bed:
		is_in_bed = not is_in_bed
		if is_in_bed:
			velocity = Vector2.ZERO
			print("✅ 躺床成功！每秒获得%d金币" % gold_per_second)
		else:
			print("❌ 起床！当前金币：%d" % current_gold)

	# ========== 3. 躺床产金币（原有） ==========
	if is_in_bed:
		gold_accumulator += delta
		if gold_accumulator >= 1.0:
			current_gold += gold_per_second
			gold_accumulator -= 1.0
			if gold_label:
				gold_label.text = "金币: %d" % current_gold
				print("当前金币：%d" % current_gold)
		return

	# ========== 4. 角色移动（原有） ==========
	var input_left: float = Input.get_action_strength("move_left")
	var input_right: float = Input.get_action_strength("move_right")
	var input_up: float = Input.get_action_strength("move_up")
	var input_down: float = Input.get_action_strength("move_down")

	var move_dir: Vector2 = Vector2(input_right - input_left, input_down - input_up)
	if move_dir != Vector2.ZERO:
		move_dir = move_dir.normalized()

	velocity = move_dir * move_speed
	move_and_slide()
	_clamp_to_map_boundary()

	# ========== 5. 检测R键升级床（原有） ==========
	if Input.is_action_just_pressed("upgrade_bed") and is_near_bed:
		if bed_node and bed_node.has_method("upgrade"):
			var success = bed_node.upgrade(current_gold)
			if success:
				# 修复：int转换避免小数金币
				var cost = int(bed_node.upgrade_cost / 1.5)
				current_gold -= cost
				gold_per_second = bed_node.get_current_gold_per_second()
				if gold_label:
					gold_label.text = "金币: %d" % current_gold

	# ========== 6. 角色翻转（原有） ==========
	if move_dir.x != 0:
		$Sprite2D.flip_h = move_dir.x < 0

# ========== 新增：房间检测辅助函数 ==========
# 更新当前所在房间
func _update_current_room() -> void:
	if map_generator and map_generator.has_method("get_player_room_data"):
		current_room = map_generator.get_player_room_data(get_global_position())
	else:
		current_room = {}

# 检测是否靠近门
func _update_door_detection() -> void:
	is_near_door = false
	if current_room and current_room.has("door_node") and is_instance_valid(current_room["door_node"]):
		var door_pos = current_room["door_node"].global_position
		var distance = (get_global_position() - door_pos).length()
		if distance < door_detection_range:
			is_near_door = true
			# 只打印一次提示，避免刷屏（修复static报错）
			var now_seconds: float = Time.get_ticks_msec() / 1000.0
			if now_seconds - last_door_tip_time > 1.0:
				print("🔑 靠近门了，按E开关门！")
				last_door_tip_time = now_seconds

# 检查坐标是否在玩家房间内
func _is_point_in_player_room(target_pos: Vector2) -> bool:
	if not map_generator or not map_generator.has_method("is_point_in_player_room"):
		return true  # 无地图生成器则不限制（兼容旧逻辑）
	return map_generator.is_point_in_player_room(get_global_position(), target_pos)

func _clamp_to_map_boundary() -> void:
	if not confine_player_to_map:
		return
	if not map_generator or not map_generator.has_method("get_map_boundary"):
		return

	var boundary: Rect2 = map_generator.get_map_boundary()
	var clamped_x = clamp(global_position.x, boundary.position.x, boundary.position.x + boundary.size.x)
	var clamped_y = clamp(global_position.y, boundary.position.y, boundary.position.y + boundary.size.y)
	global_position = Vector2(clamped_x, clamped_y)

func _ensure_player_spawn_in_room() -> void:
	if has_forced_spawn_to_room:
		return
	if current_room:
		has_forced_spawn_to_room = true
		return
	if not map_generator or not map_generator.has_method("get_rooms"):
		return

	var rooms: Array = map_generator.get_rooms()
	if rooms.is_empty():
		return

	var first_room: Dictionary = rooms[0]
	if not first_room.has("rect"):
		return

	var room_rect: Rect2 = first_room["rect"]
	global_position = room_rect.position + room_rect.size / 2.0
	has_forced_spawn_to_room = true
	print("✅ 玩家已放置到初始房间中心，门交互和建造判定已激活")

# ========== 初始化与事件绑定 ==========
func _ready() -> void:
	# 移除重复的绑定/初始化代码
	if bed_trigger:
		bed_trigger.body_entered.connect(_on_bed_enter)
		bed_trigger.body_exited.connect(_on_bed_exit)
	
	# 初始化金币UI
	if gold_label:
		gold_label.text = "金币: 0"
		print("✅ UI金币标签绑定成功！")
	else:
		print("❌ 未找到UI金币标签，请检查节点路径！")
	
	# 补全：初始化建造菜单
	if build_menu and grid_manager:
		build_menu.init(self, grid_manager)
		print("✅ 建造菜单初始化成功！")
	else:
		print("❌ 建造菜单初始化失败！")
		if not grid_manager:
			print("   → 未找到GridManager节点！")
		if not build_menu:
			print("   → 未找到BuildMenu节点！")

# ========== 床触发事件 ==========
func _on_bed_enter(body: Node2D) -> void:
	if body == self:
		is_near_bed = true
		print("靠近床了，按E躺床发育！按R升级床！")

func _on_bed_exit(body: Node2D) -> void:
	if body == self:
		is_near_bed = false
		is_in_bed = false
		gold_accumulator = 0.0
		print("离开床，停止发育！当前金币：%d" % current_gold)
