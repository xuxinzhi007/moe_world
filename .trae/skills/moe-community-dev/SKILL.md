---
name: "moe-community-dev"
description: "萌社区2D社交游戏开发助手，提供项目结构、代码规范、AI对接等开发支持。Invoke when working on the 萌社区 Godot 4.4 project."
---

# 萌社区开发助手

## 项目概述

萌社区是一个 Godot 4.4 2D 社交游戏，包含：
- 玩家移动控制
- NPC AI 系统
- 对话系统
- 本地大模型对接（Ollama）

## 项目结构

```
moe_world/
├── Scenes/
│   ├── LoginScreen.tscn       # 登录界面
│   ├── Main.tscn              # 主游戏场景
│   └── DialogSystem.tscn      # 对话系统场景
├── Scripts/
│   ├── login_screen.gd        # 登录界面逻辑
│   ├── auth_service.gd        # 认证服务（登录/注册）
│   ├── main.gd                # 主游戏逻辑
│   ├── player.gd              # 玩家脚本
│   ├── npc.gd                 # NPC脚本
│   ├── dialog_system.gd       # 对话系统
│   └── ai_service.gd          # AI服务
└── project.godot               # 项目配置
```

## 节点树结构

### 登录界面 (LoginScreen.tscn)
```
LoginScreen (Control)
├── Background (ColorRect)
├── LoginPanel (PanelContainer)
│   ├── VBoxContainer
│   │   ├── TitleLabel (Label)
│   │   ├── FormContainer (VBoxContainer)
│   │   │   ├── UsernameLabel (Label)
│   │   │   ├── UsernameInput (LineEdit)
│   │   │   ├── PasswordLabel (Label)
│   │   │   ├── PasswordInput (LineEdit)
│   │   │   ├── LoginButton (Button)
│   │   │   └── RegisterButton (Button)
│   │   ├── MessageLabel (Label)
│   │   └── SwitchModeButton (Button)
│   └── AuthService (Node)
```

### 主游戏场景 (Main.tscn)
```
Main (Node2D)
├── GameWorld (Node2D)
│   └── NPCs (Node2D)
├── Player (CharacterBody2D)
├── AIService (Node)
└── DialogSystem (CanvasLayer)
```

## 代码规范

### Godot 4.5 GDScript 标准

1. **脚本格式**
   - 使用 `extends` 指定继承类型
   - `@export` 用于导出编辑器变量
   - `@onready` 用于节点引用

2. **信号使用**
   - 定义信号：`signal signal_name(param: Type)`
   - 连接信号：`connect(_callback)`
   - 一次性连接：`CONNECT_ONE_SHOT`

3. **节点创建**
   - 使用 `Node.new()` 创建节点
   - 使用 `add_child()` 添加到场景树
   - 使用 `queue_free()` 安全删除节点

## 核心脚本说明

### player.gd
- **挂载节点**: Player (CharacterBody2D)
- **功能**: 玩家移动、交互检测、对话状态管理
- **输入**: W/A/S/D 或方向键移动，E/左键交互

### npc.gd
- **挂载节点**: 动态生成的 NPC (CharacterBody2D)
- **功能**: NPC 巡逻、交互区域、对话触发
- **特性**: 自动生成视觉元素

### dialog_system.gd
- **挂载节点**: DialogSystem (CanvasLayer)
- **功能**: 聊天 UI、消息展示、输入处理
- **UI 组件**: 消息容器、输入框、发送按钮

### ai_service.gd
- **挂载节点**: AIService (Node)
- **功能**: HTTP 请求、AI 响应处理、错误处理
- **API**: http://localhost:11434/api/generate

## AI 对接配置

### Ollama API 格式

```json
{
  "model": "llama2",
  "prompt": "系统提示\n\n玩家说: 你好\n\n你的回答:",
  "stream": false,
  "temperature": 0.7,
  "max_tokens": 200
}
```

### 响应格式

```json
{
  "response": "AI回复内容"
}
```

## 操作说明

| 按键 | 功能 |
|-----|------|
| W/A/S/D | 移动 |
| 方向键 | 移动 |
| E | 交互/对话 |
| 鼠标左键 | 交互/对话 |

## 扩展指南

### 添加新 NPC

在 `main.gd` 的 `_spawn_npcs()` 函数中添加：

```gdscript
{"name": "新NPC名", "position": Vector2(x, y), "color": Color(r, g, b, 1), "greeting": "欢迎语"}
```

### 修改 AI 模型

在 `ai_service.gd` 中修改：

```gdscript
"model": "your-model-name"
```

### 自定义对话 UI

编辑 `Scenes/DialogSystem.tscn` 场景文件。

## 注意事项

1. **Godot 版本**: 严格使用 4.5
2. **渲染模式**: 使用 gl_compatibility
3. **AI 服务**: 确保 Ollama 在 http://localhost:11434 运行
4. **节点命名**: 保持与现有结构一致
5. **脚本挂载**: 确保脚本挂载到正确的节点类型

## 常见问题

### 玩家无法移动
- 检查是否在对话状态 (`is_in_dialog`)
- 确认输入映射配置正确

### NPC 不显示
- 检查 `_setup_visuals()` 函数
- 确认 ColorRect 大小和位置

### AI 无响应
- 检查 Ollama 服务是否运行
- 查看控制台错误信息
- 确认 API 地址和格式正确

## 更新日志

### v1.4 (Bug 修复 - 2026-04-05)
- ✅ 修复 login_screen.gd 中的节点引用路径
- ✅ 修正所有 @onready 变量的节点路径

### v1.3 (Godot 4.4 适配 - 2026-04-05)
- ✅ 更新项目为 Godot 4.4 兼容
- ✅ 移除 theme_type_variation（4.5 特有属性）
- ✅ 调整 autowrap_mode 为 4.4 兼容值
- ✅ 更新 skill 文档中的版本说明
- ✅ 添加 4.4 与 4.5 兼容性说明

### v1.2 (最新更新 - 2026-04-05)
- ✅ 修复对话系统 UI 尺寸问题
- ✅ 添加聊天消息自动滚动功能
- ✅ 创建登录/注册界面
- ✅ 实现后端认证 API 对接（http://localhost:8080/api）
- ✅ 设置登录界面为启动场景
- ✅ 更新 skill 文档

### v1.1 (优化更新)
- 优化 NPC 脚本视觉元素创建
- 为 Label 添加 vertical_alignment 属性
- 为 CollisionShape2D 添加 name 属性
- 优化地面创建逻辑

### v1.0 (初始版本 - 2026-04-05)
- 初始项目重构完成
- 玩家移动系统实现
- NPC AI 巡逻系统
- 对话系统 UI
- Ollama AI 对接
- moe-community-dev skill 创建
