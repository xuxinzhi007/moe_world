---
name: "moe-community-core"
description: "萌社区核心项目信息。包含项目概述、技术栈、版本、基本规则等。在开始任何开发工作前先调用此技能了解项目基础信息。"
---

# 萌社区 - 核心项目信息

## 项目概述
- **项目名称**: 萌社区 (Moe World)
- **项目类型**: 2D 社区社交游戏
- **游戏引擎**: Godot 4.4
- **脚本语言**: GDScript
- **项目路径**: `d:\godot_data\moe_world`

## 技术栈
- **Godot 版本**: 4.4.1 stable mono
- **后端**: Go-Zero 框架
- **后端端口**: 8888 (REST API), 8080 (gRPC)
- **后端路径**: `C:\Users\ZhuanZ1\Desktop\moe_social\backend`

## Godot 可执行文件路径
```
D:\godot4.4.1\Godot_v4.4.1-stable_mono_win64\Godot_v4.4.1-stable_mono_win64.exe
```

## 核心开发规则
1. 必须使用 Godot 4.4 版本，GDScript 语法
2. 所有节点名称、结构、代码必须完全符合 Godot 4.4 标准
3. 修改前先确认当前节点结构
4. 只写可直接复制运行的完整代码，不写伪代码
5. 代码中所有节点引用，必须用 @onready 和 $路径
6. 如果需要新增功能，先告诉用户需要新增什么节点、怎么挂，再写对应代码

## Godot 4.4 与 4.5 兼容性说明
- 不使用 4.5 特有功能（如 theme_type_variation）
- autowrap_mode 使用 2 (WORD_WRAP) 而不是 3 (WORD_WRAP_SMART)

## 当前项目状态
- ✅ 登录系统完整
- ✅ 用户认证对接后端
- ✅ 玩家角色移动
- ✅ NPC 系统
- ✅ 对话系统
- ✅ AI 对接 (Ollama)
- ⏳ 移动端控制 (暂时移除，后续添加)

---

## 开发流程

### 新增功能流程
1. 调用 `moe-community` (主入口) - 了解项目
2. 调用 `moe-community-nodes` - 确认节点结构
3. 调用 `moe-community-scripts` - 查看脚本规范
4. 编写代码 - 按照规范开发
5. 调用 `moe-community-check` - 检查代码
6. 更新对应子 skill - 记录新功能或问题

---

## 更新历史

### v1.17 (2026-04-05)
- ✅ 新增世界场景 WorldScene.tscn
- ✅ 暖黄色背景，浅色草地 (#e6f2d9
- ✅ 玩家角色 CharacterBody2D
- ✅ 玩家移动 (WASD 8 方向)
- ✅ 相机平滑跟随玩家
- ✅ 顶部 UI：返回大厅按钮、玩家昵称、头像
- ✅ 大厅"进入世界"按钮跳转到 WorldScene
- ✅ WorldScene"返回大厅"按钮跳回大厅

### v1.16 (2026-04-05)
- ✅ 新增个人中心界面 ProfileScene.tscn
- ✅ 暖黄色背景，浅粉色主卡片，与登录页、大厅风格一致
- ✅ 圆形头像框占位
- ✅ 用户名、用户ID、个性签名显示
- ✅ 四个功能按钮：修改昵称、修改签名、账号安全、返回大厅
- ✅ 预留后端对接接口
- ✅ 大厅个人中心按钮跳转到个人中心
- ✅ 个人中心返回按钮跳回大厅

### v1.15 (2026-04-05)
- ✅ 新增大厅界面 HallScene.tscn
- ✅ 暖黄色背景，浅粉色主卡片，与登录页风格一致
- ✅ 四个主要按钮：进入世界、个人中心、设置、退出登录
- ✅ 底部版权小字：© 2026 moe_world
- ✅ 登录成功后跳转到大厅，大厅进入世界跳转到主游戏
- ✅ 退出登录返回登录页

### v1.14 (2026-04-05)
- ✅ 登录界面重构为萌系风格 v2
- ✅ 暖黄色背景 (#FFF3C4)，浅粉色主卡片 (#FFE6E6)，圆角 64px
- ✅ 左侧 Q 版少女立绘占位，右侧登录表单
- ✅ 标题 "moe world" 粉色 64 号字
- ✅ 输入框圆角 32px，按钮粉色圆角 32px
- ✅ Theme 样式配置完整
- ✅ 保留完整的后端对接功能

### v1.13 (2026-04-05)
- ✅ 修复 dialog_closed 信号重复连接问题 (main.gd)
- ✅ 修复 Camera2D make_current() 顺序问题 (player.gd)

### v1.12 (2026-04-05)
- ✅ 暂时移除移动端控制 (MobileControls.tscn, main.gd, player.gd)
- ⏳ 后续用更简单方案重新添加

### v1.11 (2026-04-05)
- ✅ 修复 JoystickHandle layout_mode 问题 (MobileControls.tscn)

### v1.10 (2026-04-05)
- ✅ 重构移动端控制节点结构 (MobileControls.tscn)
- ✅ 添加 HandleColor 子节点解决 ColorRect 没有 rect_position 的问题

### v1.9 (2026-04-05)
- ✅ 优化 JoystickArea 事件处理 (mobile_controls.gd)

### v1.8 (2026-04-05)
- ✅ 添加移动端虚拟摇杆和交互按钮 (MobileControls.tscn, mobile_controls.gd)

### v1.7 (2026-04-05)
- ✅ 优化登录检测邮箱逻辑 (login_screen.gd)

### v1.6 (2026-04-05)
- ✅ 修改 API 端口从 8080 到 8888 (auth_service.gd)

### v1.5 (2026-04-05)
- ✅ 完善登录界面后端对接 (login_screen.gd, auth_service.gd)

### v1.4 (2026-04-05)
- ✅ 添加登录注册界面 (LoginScreen.tscn, login_screen.gd)
- ✅ 添加后端认证服务 (auth_service.gd)

### v1.3 (2026-04-05)
- ✅ 适配 Godot 4.4 版本 (移除 theme_type_variation, 更新 autowrap_mode)

### v1.2 (2026-04-05)
- ✅ 添加登录/注册界面和后端对接

### v1.1 (2026-04-05)
- ✅ 重构为萌社区项目
