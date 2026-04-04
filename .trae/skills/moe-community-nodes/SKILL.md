---
name: "moe-community-nodes"
description: "萌社区节点结构和场景信息。包含所有场景的节点树结构、节点引用路径。在修改任何场景或节点前先调用此技能确认当前结构。"
---

# 萌社区 - 节点结构和场景

## 场景清单

| 场景 | 路径 | 说明 |
|-----|------|------|
| **LoginScreen** | `res://Scenes/LoginScreen.tscn` | 启动场景，登录/注册界面 |
| **HallScene** | `res://Scenes/HallScene.tscn` | 大厅场景，主菜单 |
| **ProfileScene** | `res://Scenes/ProfileScene.tscn` | 个人中心场景 |
| **WorldScene** | `res://Scenes/WorldScene.tscn` | 世界场景，2D 开放世界 |
| **Main** | `res://Scenes/Main.tscn` | 旧主游戏场景（保留） |
| **DialogSystem** | `res://Scenes/DialogSystem.tscn` | 对话系统界面 |

---

## WorldScene.tscn 节点树 (萌系风格 v2 - 2026-04-05)

```
WorldScene (Node2D)
├── Ground (ColorRect) - 浅色草地背景
├── Player (CharacterBody2D) - 玩家角色
│   ├── Sprite2D
│   │   └── ColorRect - 蓝色方块 (#4d99ff)
│   └── CollisionShape2D (RectangleShape2D, 32x32)
├── MainCamera (Camera2D) - 平滑跟随玩家
└── UI (CanvasLayer, layer = 10)
    └── TopBar (Control)
        ├── BackBtn (Button) - 左上角"返回大厅"按钮
        └── PlayerInfoArea (Control) - 右上角
            ├── AvatarFrame (PanelContainer) - 圆形头像框
            │   └── AvatarColor (ColorRect) - 粉色圆形
            └── NicknameLabel (Label) - "萌酱", 28号字
```

### WorldScene 节点引用
```gdscript
@onready var player: CharacterBody2D = $Player
@onready var main_camera: Camera2D = $MainCamera
@onready var back_btn: Button = $UI/TopBar/BackBtn
@onready var nickname_label: Label = $UI/TopBar/PlayerInfoArea/NicknameLabel
```

---

## ProfileScene.tscn 节点树 (萌系风格 v2 - 2026-04-05)

```
ProfileScene (Control)
├── BgColor (ColorRect) - 暖黄色背景 (#FFF3C4)
└── MainCard (PanelContainer) - 浅粉色主卡片 (#FFE6E6), 圆角 64px
    └── VBoxContainer
        ├── AvatarArea (Control)
        │   └── AvatarFrame (PanelContainer) - 圆形头像框
        │       └── AvatarColor (ColorRect) - 粉色圆形占位 (#FF6699)
        ├── Spacer1 (Control) - 间距 20px
        ├── UsernameLabel (Label) - "用户名", 32号字
        ├── UserIdLabel (Label) - "ID: 12345", 20号灰色字
        ├── BioLabel (Label) - "个性签名", 24号灰色字
        ├── Spacer2 (Control) - 间距 30px
        ├── EditNicknameBtn (Button) - "修改昵称", 粉色, 圆角 32px, 高度 56px
        ├── Spacer3 (Control) - 间距 16px
        ├── EditBioBtn (Button) - "修改签名", 粉色, 圆角 32px, 高度 56px
        ├── Spacer4 (Control) - 间距 16px
        ├── AccountSecurityBtn (Button) - "账号安全", 粉色, 圆角 32px, 高度 56px
        ├── Spacer5 (Control) - 间距 30px
        └── BackBtn (Button) - "返回大厅", 粉色, 圆角 32px, 高度 56px
```

### ProfileScene 节点引用
```gdscript
@onready var main_card: PanelContainer = $MainCard
@onready var avatar_frame: PanelContainer = $MainCard/VBoxContainer/AvatarArea/AvatarFrame
@onready var avatar_color: ColorRect = $MainCard/VBoxContainer/AvatarArea/AvatarFrame/AvatarColor
@onready var username_label: Label = $MainCard/VBoxContainer/UsernameLabel
@onready var user_id_label: Label = $MainCard/VBoxContainer/UserIdLabel
@onready var bio_label: Label = $MainCard/VBoxContainer/BioLabel
@onready var edit_nickname_btn: Button = $MainCard/VBoxContainer/EditNicknameBtn
@onready var edit_bio_btn: Button = $MainCard/VBoxContainer/EditBioBtn
@onready var account_security_btn: Button = $MainCard/VBoxContainer/AccountSecurityBtn
@onready var back_btn: Button = $MainCard/VBoxContainer/BackBtn
```

---

## HallScene.tscn 节点树 (萌系风格 v2 - 2026-04-05)

```
HallScene (Control)
├── BgColor (ColorRect) - 暖黄色背景 (#FFF3C4)
└── MainCard (PanelContainer) - 浅粉色主卡片 (#FFE6E6), 圆角 64px
    └── VBoxContainer
        ├── TitleLabel (Label) - "moe world", 粉色 (#FF6699), 64号字体
        ├── Spacer1 (Control) - 间距 40px
        ├── EnterWorldBtn (Button) - "进入世界", 粉色, 圆角 32px, 高度 64px
        ├── Spacer2 (Control) - 间距 20px
        ├── ProfileBtn (Button) - "个人中心", 粉色, 圆角 32px, 高度 64px
        ├── Spacer3 (Control) - 间距 20px
        ├── SettingsBtn (Button) - "设置", 粉色, 圆角 32px, 高度 64px
        ├── Spacer4 (Control) - 间距 20px
        ├── LogoutBtn (Button) - "退出登录", 粉色, 圆角 32px, 高度 64px
        ├── Spacer5 (Control) - 间距 40px
        └── CopyrightLabel (Label) - "© 2026 moe_world", 灰色小字
```

### HallScene 节点引用
```gdscript
@onready var main_card: PanelContainer = $MainCard
@onready var title_label: Label = $MainCard/VBoxContainer/TitleLabel
@onready var enter_world_btn: Button = $MainCard/VBoxContainer/EnterWorldBtn
@onready var profile_btn: Button = $MainCard/VBoxContainer/ProfileBtn
@onready var settings_btn: Button = $MainCard/VBoxContainer/SettingsBtn
@onready var logout_btn: Button = $MainCard/VBoxContainer/LogoutBtn
@onready var copyright_label: Label = $MainCard/VBoxContainer/CopyrightLabel
```

---

## LoginScreen.tscn 节点树 (萌系风格 v2 - 2026-04-05)

```
LoginScreen (Control)
├── BgColor (ColorRect) - 暖黄色背景 (#FFF3C4)
├── MainCard (PanelContainer) - 浅粉色主卡片 (#FFE6E6), 圆角 64px
│   └── HBoxContainer
│       ├── CharacterPlaceholder (PanelContainer)
│       │   ├── CharacterImg (ColorRect) - Q版少女立绘占位
│       │   └── CharacterLabel (Label) - "Q版少女立绘"
│       └── RightContainer (VBoxContainer)
│           ├── TitleLabel (Label) - "moe world", 粉色 (#FF6699), 64号字体
│           ├── Spacer1 (Control) - 间距 20px
│           ├── UsernameInput (LineEdit) - 圆角 32px, 高度 64px
│           ├── Spacer2 (Control) - 间距 16px
│           ├── PasswordInput (LineEdit) - 密码模式, 圆角 32px, 高度 64px
│           ├── Spacer3 (Control) - 间距 24px
│           ├── LoginBtn (Button) - 粉色 (#FF6699), 圆角 32px, 高度 64px
│           ├── Spacer4 (Control) - 间距 20px
│           └── BottomLinks (HBoxContainer)
│               ├── ForgetPwdLabel (Label) - "忘记密码?"
│               └── RegisterBtn (LinkButton) - "注册账号", 蓝色 (#3399FF)
├── MessageLabel (Label) - 消息提示
└── AuthService (Node)
```

### LoginScreen 节点引用
```gdscript
@onready var main_card: PanelContainer = $MainCard
@onready var title_label: Label = $MainCard/HBoxContainer/RightContainer/TitleLabel
@onready var username_input: LineEdit = $MainCard/HBoxContainer/RightContainer/UsernameInput
@onready var password_input: LineEdit = $MainCard/HBoxContainer/RightContainer/PasswordInput
@onready var login_btn: Button = $MainCard/HBoxContainer/RightContainer/LoginBtn
@onready var register_btn: LinkButton = $MainCard/HBoxContainer/RightContainer/BottomLinks/RegisterBtn
@onready var forget_pwd_label: Label = $MainCard/HBoxContainer/RightContainer/BottomLinks/ForgetPwdLabel
@onready var message_label: Label = $MessageLabel
```

---

## Main.tscn 节点树

```
Main (Node2D)
├── GameWorld (Node2D)
│   └── NPCs (Node2D) - NPC 容器
├── Player (CharacterBody2D)
├── AIService (Node)
└── DialogSystem (CanvasLayer) - 实例化自 DialogSystem.tscn
```

### Main 节点引用
```gdscript
@onready var player: CharacterBody2D = $Player
@onready var ai_service: Node = $AIService
@onready var dialog_system: CanvasLayer = $DialogSystem
@onready var game_world: Node2D = $GameWorld
@onready var npcs: Node2D = $GameWorld/NPCs
```

### Player 节点（运行时创建）
```
Player (CharacterBody2D)
├── Sprite2D
│   └── ColorRect
├── CollisionShape2D
│   └── RectangleShape2D (32x32)
└── Camera2D (make_current=true)
```

---

## DialogSystem.tscn 节点树

```
DialogSystem (CanvasLayer)
└── DialogPanel (PanelContainer)
    ├── CloseButton (Button)
    ├── NameLabel (Label)
    └── VBoxContainer
        ├── MessageContainer (ScrollContainer)
        │   └── MessageText (RichTextLabel)
        ├── TypingLabel (Label)
        └── InputContainer (HBoxContainer)
            ├── InputLine (LineEdit)
            └── SendButton (Button)
```

### DialogSystem 节点引用
```gdscript
@onready var dialog_panel: PanelContainer = $DialogPanel
@onready var npc_name_label: Label = $DialogPanel/NameLabel
@onready var message_text: RichTextLabel = $DialogPanel/VBoxContainer/MessageContainer/MessageText
@onready var input_container: HBoxContainer = $DialogPanel/VBoxContainer/InputContainer
@onready var input_line: LineEdit = $DialogPanel/VBoxContainer/InputContainer/InputLine
@onready var send_button: Button = $DialogPanel/VBoxContainer/InputContainer/SendButton
@onready var close_button: Button = $DialogPanel/CloseButton
@onready var typing_label: Label = $DialogPanel/VBoxContainer/TypingLabel
```

---

## 动态生成的 NPC 节点

每个 NPC 在运行时由 main.gd 生成：
```
NPC (CharacterBody2D)
├── Sprite2D
│   └── ColorRect
├── CollisionShape2D
│   └── RectangleShape2D (32x32)
├── Area2D (交互检测)
│   └── CollisionShape2D
└── Label (NPC 名字)
```

---

## 重要提示
1. **不要凭空创建节点** - 修改场景前先确认当前结构
2. **路径必须完全一致** - 节点引用用 @onready 和 $路径
3. **LoginScreen 是启动场景** - 在 project.godot 中配置
