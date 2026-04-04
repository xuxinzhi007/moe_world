---
name: "moe-community-check"
description: "萌社区代码检查和验证。包含常见错误、调试方法、Godot 验证命令。在写完代码或遇到错误时先调用此技能。"
---

# 萌社区 - 代码检查和验证

## 常见错误和修复

### 1. 信号重复连接错误
**错误**: `Signal 'xxx' is already connected to given callable`
**原因**: 信号被多次连接
**修复**:
- 在 `_ready()` 中连接一次即可
- 不要在每次触发时都连接
- 用 `CONNECT_ONE_SHOT` 只连接一次（但避免重复）

**示例**:
```gdscript
# 正确 - 在 _ready() 中连接一次
func _ready() -> void:
    dialog_system.dialog_closed.connect(_on_dialog_closed)

# 错误 - 每次都连接
func _on_something() -> void:
    dialog_system.dialog_closed.connect(_on_dialog_closed, CONNECT_ONE_SHOT)
```

---

### 2. 节点属性访问错误
**错误**: `Invalid access to property or key 'xxx' on a base object of type 'null instance'`
**原因**: 节点引用路径错误，或节点还没 ready
**修复**:
- 确认节点路径正确，调用 moe-community-nodes
- 用 `@onready var 名称: 类型 = $路径`
- 确保在 `_ready()` 之后访问节点

---

### 3. Control 节点 layout_mode 和 rect_position
**错误**: `Invalid assignment of property or key 'rect_position' with value of type 'Vector2' on a base object of type 'Control'`
**原因**: Control 节点在 `layout_mode = 1` (锚点布局) 时不能设置 `rect_position`
**修复**:
- 需要设置 `rect_position` 时，用 `layout_mode = 0` (固定布局)
- 或者用 `offset_*` 属性替代

---

### 4. ColorRect 没有 rect_position 属性
**错误**: `Invalid assignment of property or key 'rect_position' with value of type 'Vector2' on a base object of type 'ColorRect'`
**原因**: ColorRect 是 CanvasItem，不是 Control，没有 rect_position 属性
**修复**:
- 用 Control 包装 ColorRect，设置 Control 的 rect_position
- ColorRect 可以用 `position` 属性

---

### 5. 节点不存在错误
**错误**: `Invalid get index 'xxx' (on base: 'null instance')`
**原因**: 节点路径错误，或节点被删除了
**修复**:
- 调用 moe-community-nodes 确认当前节点结构
- 检查 `@onready` 引用路径是否正确

---

## 验证和调试方法

### 1. Godot 项目验证命令
```powershell
& "D:\godot4.4.1\Godot_v4.4.1-stable_mono_win64\Godot_v4.4.1-stable_mono_win64.exe" --headless --check-only .
```

### 2. 查看控制台输出
- 所有 `print()` 语句都会输出到 Godot 控制台
- 运行游戏时，先查看控制台是否有错误

### 3. 添加调试日志
在关键位置添加打印语句：
```gdscript
func _ready() -> void:
    print("🎮 玩家节点初始化中...")
    # ... 初始化代码
    print("✅ 玩家视觉元素创建完成！")
```

---

## 代码检查清单

写完代码后，检查以下内容：

### 1. 节点引用
- [ ] 用 `@onready var 名称: 类型 = $路径`
- [ ] 路径与 moe-community-nodes 一致
- [ ] 没有凭空生成节点

### 2. 信号连接
- [ ] 在 `_ready()` 中只连接一次
- [ ] 没有重复连接
- [ ] 信号名称正确

### 3. Godot 4.4 兼容
- [ ] 没有使用 4.5 特有功能
- [ ] 没有 `theme_type_variation`
- [ ] `autowrap_mode` 用 2 而不是 3

### 4. 命名规范
- [ ] 节点: PascalCase
- [ ] 变量: snake_case
- [ ] 函数: snake_case
- [ ] 信号: snake_case

---

## 常见问题

### Q: 为什么运行后没有玩家角色？
A: 玩家角色在运行时由 `player.gd` 的 `_setup_visuals()` 自动创建，查看控制台是否有 `✅ 玩家视觉元素创建完成！`

### Q: 为什么 NPC 没有显示？
A: NPC 由 `main.gd` 的 `_spawn_npcs()` 动态生成，确认 `_ready()` 调用了这个函数

### Q: 后端连接失败？
A: 确认：
1. 后端服务在运行（端口 8888）
2. API 地址正确（http://localhost:8888/api）
3. 查看控制台输出的请求信息

### Q: 如何用 Godot 运行项目？
A: 在项目目录运行：
```powershell
& "D:\godot4.4.1\Godot_v4.4.1-stable_mono_win64\Godot_v4.4.1-stable_mono_win64.exe" .
```

---

## 重要提示
1. **先调用 moe-community-nodes** - 确认当前节点结构
2. **再调用 moe-community-scripts** - 查看脚本规范
3. **写完后用 moe-community-check** - 检查代码
4. **用 --check-only 验证** - 确保项目能编译

---

## 问题历史记录

### 2026-04-05 - Camera2D make_current() 顺序错误
- **问题**: `ERROR: Condition "!enabled || !is_inside_tree()" is true.`
- **原因**: 在 `player.gd` 的 `_setup_visuals()` 中，先调用了 `camera.make_current()`，然后才调用 `add_child(camera)`
- **解决方案**: 先 `add_child(camera)`，再 `camera.make_current()`
- **影响文件**: `Scripts/player.gd`

### 2026-04-05 - dialog_closed 信号重复连接错误
- **问题**: `Signal 'dialog_closed' is already connected to given callable`
- **原因**: 在 `_on_npc_interacted` 中每次都连接信号
- **解决方案**: 在 `main.gd` 的 `_ready()` 中只连接一次
- **影响文件**: `Scripts/main.gd`

### 2026-04-05 - 移动端控制暂时移除
- **问题**: 移动端控制太复杂，导致多个节点属性错误
- **原因**: ColorRect 没有 rect_position，Control layout_mode 问题
- **解决方案**: 暂时从 Main.tscn 移除移动端控制，后续用更简单方案重新添加
- **影响**: 移动端控制功能暂时不可用，PC 键盘控制正常
