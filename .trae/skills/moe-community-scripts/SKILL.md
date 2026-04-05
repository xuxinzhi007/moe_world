---
name: "moe-community-scripts"
description: "萌社区脚本规范和说明。包含所有脚本的作用、挂载位置、代码规范。在编写或修改任何脚本前先调用此技能。"
---

# 萌社区 - 脚本规范和说明

## 脚本清单

| 脚本 | 路径 | 挂载节点 | 作用 |
|-----|------|---------|------|
| **login_screen.gd** | `res://Scripts/login_screen.gd` | LoginScreen | 登录/注册界面逻辑 |
| **auth_service.gd** | `res://Scripts/auth_service.gd` | LoginScreen/AuthService | 后端认证服务对接 |
| **hall_scene.gd** | `res://Scripts/hall_scene.gd` | HallScene | 大厅主菜单，导航按钮 |
| **profile_scene.gd** | `res://Scripts/profile_scene.gd` | ProfileScene | 个人中心，用户信息 |
| **world_scene.gd** | `res://Scripts/world_scene.gd` | WorldScene | 世界场景，玩家移动，相机跟随 |
| **main.gd** | `res://Scripts/main.gd` | Main | 旧主游戏逻辑（保留） |
| **player.gd** | `res://Scripts/player.gd` | Player | 旧玩家脚本（保留） |
| **npc.gd** | `res://Scripts/npc.gd` | 动态生成的 NPC | NPC 角色，AI 巡逻，对话触发 |
| **dialog_system.gd** | `res://Scripts/dialog_system.gd` | DialogSystem | 对话系统 UI，聊天界面 |
| **ai_service.gd** | `res://Scripts/ai_service.gd` | Main/AIService | 本地 AI 对接，Ollama |

---

## world_scene.gd - 世界场景 (萌系风格 v2 - 2026-04-05)

### 挂载节点
```
WorldScene (Node2D)
```

### 主要功能
- 萌系风格主题
- 玩家 8 方向移动 (WASD)
- 相机平滑跟随玩家
- 顶部 UI：返回大厅按钮、玩家昵称、头像
- 预留 NPC 区域接口

### 核心函数
```gdscript
func _apply_theme() -> void  # 应用萌系主题样式
func _physics_process(delta: float) -> void  # 玩家移动
func _process(delta: float) -> void  # 相机跟随
func _on_back_clicked() -> void  # 返回大厅
```

### 主题颜色
- 地面: #e6f2d9 (浅色草地)
- 按钮: #FF6699 (粉色)
- 头像: #FF6699 (粉色圆形)

---

## profile_scene.gd - 个人中心 (萌系风格 v2 - 2026-04-05)

### 挂载节点
```
ProfileScene (Control)
```

### 主要功能
- 萌系风格主题（与登录页、大厅一致）
- 圆形头像框占位
- 用户名、用户ID、个性签名显示
- 四个功能按钮：修改昵称、修改签名、账号安全、返回大厅
- 预留后端对接接口

### 核心函数
```gdscript
func _apply_theme() -> void  # 应用萌系主题样式
func _load_user_data() -> void  # 加载用户数据（预留对接）
func _update_ui() -> void  # 更新 UI 显示
func _on_edit_nickname_clicked() -> void
func _on_edit_bio_clicked() -> void
func _on_account_security_clicked() -> void
func _on_back_clicked() -> void  # 返回大厅
```

### 主题颜色
- 背景色: #FFF3C4 (暖黄色)
- 主卡片: #FFE6E6 (浅粉色)
- 按钮: #FF6699 (粉色)
- 头像: #FF6699 (粉色圆形占位)

---

## hall_scene.gd - 大厅主菜单 (萌系风格 v2 - 2026-04-05)

### 挂载节点
```
HallScene (Control)
```

### 主要功能
- 萌系风格主题（与登录界面一致）
- 四个主要按钮：进入世界、个人中心、设置、退出登录
- 按钮粉色 (#FF6699)，圆角 32px
- 主卡片浅粉色 (#FFE6E6)，圆角 64px
- 底部版权小字：© 2026 moe_world

### 核心函数
```gdscript
func _apply_theme() -> void  # 应用萌系主题样式
func _on_enter_world_clicked() -> void  # 跳转到主游戏
func _on_profile_clicked() -> void
func _on_settings_clicked() -> void
func _on_logout_clicked() -> void  # 退出登录，返回登录页
```

### 主题颜色
- 背景色: #FFF3C4 (暖黄色)
- 主卡片: #FFE6E6 (浅粉色)
- 按钮: #FF6699 (粉色)
- 标题文字: #FF6699 (粉色)

---
## 代码规范（用户优化版 v3）

### Godot 4.4 GDScript 规范
1. 使用 4.4 语法，不使用 4.5 特有功能
2. 节点引用用 `@onready var 名称: 类型 = $路径`
3. 信号连接用 `connect()`
4. 不要凭空生成节点，修改前先确认节点结构

### 命名规范
- **节点**: PascalCase (如 `Player`, `LoginPanel`)
- **脚本变量**: snake_case (如 `is_in_dialog`, `move_speed`)
- **函数**: snake_case (如 `_on_button_pressed`, `_setup_visuals`)
- **信号**: snake_case (如 `dialog_closed`, `login_success`)

---

## 用户优化的代码规范（重要！必须遵守！）

### 1. 使用 Color8 代替 Color
```gdscript
// ✅ 推荐写法
var col_bg := Color8(255, 243, 196)  // 暖黄色
var col_btn := Color8(255, 102, 153)    // 粉色

// ❌ 不推荐
var col_bg := Color(1, 0.95, 0.77, 1)
```

### 2. 规范的颜色变量命名
```gdscript
// ✅ 推荐写法
var col_bg := Color8(255, 243, 196)
var col_card := Color8(255, 235, 240)
var col_btn := Color8(255, 102, 153)
var col_btn_hover := Color8(255, 130, 175)
var col_btn_press := Color8(230, 80, 130)
var col_link := Color8(230, 70, 130)
var col_text := Color8(60, 40, 50)
var col_text_light := Color8(180, 150, 165)
```

### 3. 正确的鼠标过滤器设置
```gdscript
// 装饰性节点：MOUSE_FILTER_IGNORE (值为 2)
// 这样装饰不会阻挡下面的输入
bg_decor.mouse_filter = 2

// 输入节点：MOUSE_FILTER_STOP (值为 1)
// 这样输入框能接收输入
input_box.mouse_filter = 1
```

### 4. 使用 StyleBoxEmpty 给 flat 按钮
```gdscript
// ✅ 推荐写法
var flat_clear := StyleBoxEmpty.new()
forget_pwd_btn.add_theme_stylebox_override("normal", flat_clear)
register_btn.add_theme_stylebox_override("normal", flat_clear)
```

### 5. 正确的主题覆盖方法
```gdscript
// ✅ 推荐写法
add_theme_stylebox_override()
add_theme_color_override()
remove_theme_color_override()

// 使用 override 而不是直接修改主题
login_btn.add_theme_stylebox_override("normal", btn_style)
```

### 6. 更清晰的状态颜色
```gdscript
// ✅ 推荐写法
status_dot.color = Color8(90, 200, 110)  // 服务器在线 - 绿色
status_dot.color = Color8(230, 90, 100)   // 服务器离线 - 红色
status_label.modulate = Color8(90, 200, 110)
status_label.modulate = Color8(230, 90, 100)
```

---

## login_screen.gd - 登录界面 (萌系风格 v3 - 2026-04-05，用户优化版)

---

## login_screen.gd - 登录界面 (萌系风格 v2 - 2026-04-05)

### 挂载节点
```
LoginScreen (Control)
```

### 主要功能
- 萌系风格主题（暖黄色背景、浅粉色卡片）
- 输入框圆角 32px，按钮圆角 32px
- 主卡片圆角 64px
- 登录功能（支持用户名或邮箱）
- 回车登录，用户名回车跳转到密码框
- 对接 auth_service
- 登录成功后跳转到 Main 场景

### 核心函数
```gdscript
func _apply_theme() -> void  # 应用萌系主题样式
func _on_login_clicked() -> void
func _on_register_clicked() -> void
func _focus_to_password() -> void
func _on_login_success(token: String, user_data: Dictionary) -> void
func _on_login_failed(error: String) -> void
```

### 主题颜色
- 背景色: #FFF3C4 (暖黄色)
- 主卡片: #FFE6E6 (浅粉色)
- 登录按钮: #FF6699 (粉色)
- 标题文字: #FF6699 (粉色)
- 输入框: 白色背景 + 浅灰边框

---

## auth_service.gd - 认证服务

### 挂载节点
```
LoginScreen (Control)
└── AuthService (Node)
```

### 主要功能
- 对接后端 API (http://localhost:8888/api)
- 登录接口: `/api/user/login`
- 注册接口: `/api/user/register`
- 获取配置接口: `/api/public/client-config`

### 核心信号
```gdscript
signal login_success(token: String, user_data: Dictionary)
signal login_failed(error: String)
signal register_success(user_data: Dictionary)
signal register_failed(error: String)
signal config_fetched(api_base_url: String)
signal config_failed(error: String)
```

---

## main.gd - 主游戏逻辑

### 挂载节点
```
Main (Node2D)
```

### 主要功能
- 生成游戏地面
- 生成 3 个 NPC (小萌、阿杰、小雪)
- 连接 dialog_closed 信号

### NPC 数据
```gdscript
[
    {"name": "小萌", "position": Vector2(100, 100), "color": Color(1, 0.5, 0.8, 1), "greeting": "你好呀~ 欢迎来到萌社区！"},
    {"name": "阿杰", "position": Vector2(-100, -100), "color": Color(0.5, 0.8, 1, 1), "greeting": "嗨！今天天气真好~"},
    {"name": "小雪", "position": Vector2(150, -80), "color": Color(0.8, 1, 0.5, 1), "greeting": "见到你真开心！"}
]
```

---

## player.gd - 玩家角色

### 挂载节点
```
Main (Node2D)
└── Player (CharacterBody2D)
```

### 主要功能
- 玩家移动控制 (键盘)
- 与 NPC 交互检测
- 相机跟随 (自动创建 Camera2D)

### 核心变量
```gdscript
@export var move_speed: float = 200.0
@export var player_color: Color = Color(0.3, 0.6, 1, 1)
var is_in_dialog: bool = false
var nearby_npcs: Array = []
```

### 核心函数
```gdscript
func _physics_process(delta: float) -> void  # 移动
func _process(delta: float) -> void  # 交互
func add_nearby_npc(npc: Node) -> void
func remove_nearby_npc(npc: Node) -> void
func start_dialog() -> void
func end_dialog() -> void
```

---

## npc.gd - NPC 角色

### 挂载节点
```
Main (Node2D)
└── GameWorld (Node2D)
    └── NPCs (Node2D)
        └── [动态生成的 NPC] (CharacterBody2D)
```

### 主要功能
- AI 巡逻 (自动移动)
- 玩家接近检测 (Area2D)
- 对话触发

### 核心变量
```gdscript
@export var npc_name: String = "NPC"
@export var npc_color: Color = Color(1, 0.5, 0.5, 1)
@export var greeting: String = "你好呀~"
var patrol_speed: float = 50.0
```

### 核心信号
```gdscript
signal npc_interacted(npc: Node2D)
```

---

## dialog_system.gd - 对话系统

### 挂载节点
```
Main (Node2D)
└── DialogSystem (CanvasLayer)
```

### 主要功能
- 显示对话界面
- 发送和接收消息
- 与 ai_service 对接
- 消息滚动

### 核心函数
```gdscript
func show_dialog(npc: Node2D, npc_name: String, greeting: String = "") -> void
func hide_dialog() -> void
func _add_message(sender: String, text: String) -> void
func _send_message() -> void
func set_ai_service(service: Node) -> void
```

### 核心信号
```gdscript
signal dialog_closed()
```

---

## ai_service.gd - AI 服务

### 挂载节点
```
Main (Node2D)
└── AIService (Node)
```

### 主要功能
- 对接本地 Ollama API
- 地址: `http://localhost:11434/api/generate`
- 默认模型: llama2

### 核心信号
```gdscript
signal ai_response_received(response: String)
signal ai_error_occurred(error: String)
```

---

## 重要提示
1. **修改前先看节点结构** - 调用 moe-community-nodes
2. **不要凭空生成节点** - 用 @onready 和 $路径
3. **只写完整可运行代码** - 不写伪代码，不省略逻辑
