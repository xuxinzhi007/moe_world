# TECH DESIGN

## 文档元信息

- 需求包目录：`docs/requirements/2026-05-18_world-main-city_map-ui-redesign/`
- 日期：2026-05-18
- 技术负责人：AI 协作开发

## 1. 技术目标

- 统一地图主语义：`world_main = 主城 = 出生地图 = 世界入口`
- 统一交互语义：地图边缘切换与 `NPC` / `survivor_portal` 使用同类“进入范围 -> 显示提示 -> 玩家确认”的流程
- 统一地图 UI 语义：
  - 右上角小地图：当前地图真实空间表达
  - 全屏地图：主城与周边区域关系图

## 2. 影响范围

- 场景：
  - `Scenes/WorldScene.tscn`
  - `Scenes/maps/zones/ZoneEastMarket.tscn`
  - `Scenes/maps/zones/ZoneSouthTrail.tscn`
  - `Scenes/maps/zones/ZoneComingSoon.tscn`
- 脚本：
  - `Scripts/world/world_scene.gd`
  - `Scripts/world/world_scene_config.gd`
  - `Scripts/world/world_radar_minimap.gd`
  - `Scripts/player/player.gd`
- UI：
  - `Scenes/ui/WorldGameplayHud.tscn`
  - `Scenes/ui/WorldMapOverlay.tscn`

## 3. 方案设计

### 3.1 地图结构

- `WorldScene` 中基础地面与出生逻辑对应 `world_main`
- 周边区域通过 `REGION_FALLBACK_EXITS` 与 `MapMeta.neighbors` 回链主城
- `plaza` 仅保留为遗留资源，不再参与“当前主城中心”推导

### 3.2 边缘交互模型

- 主城边缘触发器不再直接打开确认弹窗
- 玩家进入边缘触发区后：
  - `hint_label` 显示目的地提示
  - 玩家交互提示点亮
  - 飘字提示“按 E 前往 / 点击对话前往”
- 玩家按交互键时才真正切图或弹出“未开放区域”提示
- 周边区域 `GateExits` 同样走主动交互，而不是强制 modal

### 3.3 主城边界策略

- `world_main` 必须拥有显式可游玩矩形
- 边界判定优先使用主城配置矩形，而不是依赖旧的“区域自动推导”
- 玩家超出主城合法矩形时立即夹回并清零移动输入

### 3.4 小地图职责重做

- 右上角小地图从“雷达”改为“当前地图 minimap”
- 首版内容：
  - 当前地图边界框
  - 玩家位置点
  - 玩家朝向
  - 可切换出口
  - NPC / 怪物 / 中立单位点位
- 全屏地图继续展示抽象区域关系，不与 minimap 重复

### 3.5 UI 设计方向

- 主城作为世界入口，需要更强“稳定、可信、可导航”的信息感
- 顶栏提示优先表达当前区域与边缘交互，而不是长期保留操作说明
- 小地图视觉应强调：
  - 边界明确
  - 出口明确
  - 玩家朝向明确
  - 当前区域名称明确

## 4. 兼容与风险

- 对现有功能的影响：
  - 会改变地图边缘的触发体验
  - 会影响移动端交互提示文案
- 回归点：
  - `survivor_portal` 交互不能被新逻辑抢占
  - NPC 对话优先级不能异常
  - 外区返回主城的出生点不能错位
- 回滚方案：
  - 保留 `_show_exit_confirm(...)`，仅不作为默认触发入口

## 5. 实施顺序

1. 新建文档并确认主城中心架构
2. 重做边缘交互状态机
3. 修复主城边界与标签回退
4. 改造右上角 minimap
5. 完成手测检查项

## 6. 验证方式

- 运行路径：
  - `Hall -> WorldScene -> 主城边缘 -> 周边区域 -> 返回主城`
- 关键日志：
  - 主城切区日志
  - 边缘交互目标日志
  - 返回主城日志
- 手测步骤：
  - 出生后检查主城标签
  - 主城三侧边缘分别测试
  - 周边区域返回主城测试
  - 小地图与全屏地图分别检查
