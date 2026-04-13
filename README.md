# moe_world（萌社区 · 大世界客户端）

基于 **Godot 4.4** 的 2D 大世界探索客户端：账号登录、大厅、个人中心、单机/云端多人同屏、移动端虚拟摇杆与对话 UI。可与自建后端 **moe_social**（REST + WebSocket）联调。

## 技术栈

| 项 | 说明 |
|----|------|
| 引擎 | Godot **4.4**（`project.godot` 中标记 Mobile 特性） |
| 语言 | **GDScript**（工程含 `[dotnet]` 段，可按需使用 C#） |
| 渲染 | OpenGL 3 / `gl_compatibility`（便于部分安卓设备） |
| 网络 | HTTP（登录与配置）+ **WebSocket**（`/ws/world` 房间同步） |
| 会话持久化 | `user://moe_world_session.cfg`（**UserStorage**），避免运行时写 `project.godot` |

## 功能概览

- **登录 / 注册**：对接后端 API；支持从远程拉取 `client-config`（如 GitHub 上的 `moe_api.json`）解析 `api_base_url`。
- **大厅**：单机进入世界、云端房间（约定房间名）、个人中心、设置、退出登录。
- **大世界（WorldScene）**：`CharacterBody2D` 移动、相机跟随、NPC 对话（底栏 **MoeDialog**）。
- **云端多人**：同一房间内的玩家位置与昵称同步；头顶显示用户名（`world_profile` / `world_peer_profile`）。
- **移动端**：左下摇杆 + 右下「对话」键；**对话仅建议用按钮或键盘 E**（`interact` 未绑定鼠标左键，避免触屏与摇杆冲突）。

## 运行要求

- 安装 **Godot 4.4.x**（与 `config/features` 一致）。
- 若使用完整账号与云端联机，需可访问的 **moe_social** 后端（HTTPS/WSS 或本地 HTTP/WS）。

## 快速开始

1. 用 Godot 打开本仓库根目录（含 `project.godot`）。
2. 主场景为 **LoginScreen**（`run/main_scene`）。
3. 运行（F5）：在编辑器内可先用默认或配置好的 `api_base_url` 登录。

### 导出 Android

- 工程内已有 `export_presets.cfg` 时，在编辑器中检查 **Internet** 等权限。
- 登录态写入 `user://`，无需可写安装目录。

## 后端配合说明

云端大世界依赖后端 WebSocket 路由（go-zero 示例路径）：

- **URL**：`{api_origin}/ws/world?token={JWT}&room={房间名}`  
  - `api_origin` 由 `api_base_url` 去掉末尾 `/api` 后，将 `http→ws`、`https→wss` 得到。
- **房间名**：`[a-zA-Z0-9_-]{1,48}`，默认可与好友约定同一串，例如 `default`。
- **消息类型**（JSON 文本帧）：`world_welcome`、`world_move`、`world_profile`、`world_peer_joined` / `world_peer_left` / `world_peer_profile`、`ping`/`pong` 等。

服务端对 **同一 WebSocket 连接** 的写入需串行化（例如每连接一把写锁），并对 `world_move` 做适度 **广播节流**，避免高并发下 fan-out 压力过大。

客户端侧 **WorldNetwork** 对上行位置有 **距离 + 频率** 节流（可在编辑器中调整 `WorldNetwork` 的 export 参数）。

## 自动加载（Autoload）

| 名称 | 脚本 | 作用 |
|------|------|------|
| **UserStorage** | `Scripts/user_storage.gd` | 启动时恢复会话到 `ProjectSettings` 内存；登录后持久化到 `user://` |
| **WorldNetwork** | `Scripts/world_network.gd` | 云端会话、WebSocket 轮询、移动/昵称发送与信号 |
| **MoeDialogBus** | `Scripts/moe_dialog_bus.gd` | 全局唯一对话层，防止叠多层对话框 |

## 目录结构（摘要）

```
Scenes/          # 各界面与 WorldScene、Player、NPC、MoeDialog 等
Scripts/         # GDScript：登录、大厅、世界、网络、对话总线、用户存储等
apk/             # 若存在，多为本地导出产物（勿误提交敏感签名）
export_presets.cfg
project.godot
```

## 配置与隐私

- **不要在仓库中提交** 真实 token、生产数据库连接或私人 `export_presets` 密钥；`project.godot` 里 `[moe_world]` 下若存有调试用户数据，提交前宜清理或使用本地覆盖。
- 远程 API 基址优先来自 **登录前拉取的配置** 或 **UserStorage**；编辑器内 `ProjectSettings` 中的 `moe_world/*` 多用于开发期默认值。

## 已知边界（产品级前需评估）

- 位置同步为 **客户端上报 + 服务端转发**，无服务端权威校验与反作弊。
- 无兴趣管理（AOI）；人数增多时需分服、分区或降频策略。
- 联机仅 **云端 WebSocket** 路径；局域网 ENet 主机/加入已移除。

## 许可证

若未单独指定，以仓库内 LICENSE 为准；无 LICENSE 文件时请自行补充。
