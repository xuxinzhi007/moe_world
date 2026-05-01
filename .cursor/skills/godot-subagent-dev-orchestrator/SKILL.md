---
name: godot-subagent-dev-orchestrator
description: 用于 Godot 项目“子代理协调开发”，把地图、角色、背景、任务、材料图标、音频、动作、怪物拆分为可并行模块并统一验收。用户提到“子代理协调开发、分工并行、完整实现游戏功能”时使用。
---

# Godot 子代理协调开发总控

## 目标

把复杂游戏功能拆成多个子代理并行推进，避免“多人并行但接口不一致”。

## 触发场景

- 需要同时推进地图、角色、怪物、任务、音频等多个模块。
- 需求跨度大，单次对话无法稳定覆盖完整闭环。
- 需要“分析 -> 设计 -> 实现 -> 回归”的分工协作。

## 子代理分工矩阵（本项目建议）

1. 总控与排期：`godot-dev-lead`
2. 架构契约审查：`godot-architecture-auditor`
3. 地图/背景规划：`godot-map-background-planner`
4. 角色/动作设计：`godot-character-action-designer`
5. 任务推进设计：`godot-quest-progression-designer`
6. 材料/图标管线：`godot-material-icon-pipeline`
7. 音频事件规划：`godot-audio-event-designer`
8. 怪物遭遇设计：`godot-monster-encounter-designer`
9. UI布局实现：`godot-ui-layout-engineer`
10. 玩法实现：`godot-gameplay-programmer`
11. 异常与性能排查：`godot-tech-troubleshooter`
12. 文档与清单同步：`godot-docs-maintainer`

## 模块到子代理映射（本次需求）

- 地图：`godot-map-background-planner` -> `godot-ui-layout-engineer` + `godot-gameplay-programmer`
- 角色：`godot-character-action-designer` -> `godot-gameplay-programmer`
- 背景：`godot-map-background-planner` -> `godot-ui-layout-engineer`
- 任务：`godot-quest-progression-designer` -> `godot-gameplay-programmer`
- 材料与图标：`godot-material-icon-pipeline` -> `godot-ui-layout-engineer` + `godot-gameplay-programmer`
- 音频文件：`godot-audio-event-designer` -> `godot-tech-troubleshooter` + `godot-gameplay-programmer`
- 动作系统：`godot-character-action-designer` -> `godot-gameplay-programmer`
- 怪物：`godot-monster-encounter-designer` -> `godot-gameplay-programmer`

## 执行节奏（固定）

1. **盘点阶段（只读）**  
   各子代理先输出“已有能力/缺口/风险/优先级（P0-P2）”。
2. **契约阶段（统一接口）**  
   先锁定节点路径、输入动作、公共方法签名，禁止边写边改接口。
3. **实现阶段（最小可用）**  
   先打通 P0 主链路（大厅 -> 世界 -> 战斗/交互 -> 返回）。
4. **回归阶段（跨模块）**  
   覆盖移动、交互、战斗、地图开关、音频触发、怪物刷新。
5. **收口阶段（文档与风险）**  
   产出“已完成/未完成/风险/下一步”。

## 标准编排顺序（建议）

1. `godot-dev-lead` 汇总目标与模块拆解。
2. 并行运行 6 个设计型子代理（地图背景/角色动作/任务/材料图标/音频/怪物）做只读盘点。
3. `godot-architecture-auditor` 统一契约（节点路径、输入动作、公共方法签名）。
4. `godot-ui-layout-engineer` 与 `godot-gameplay-programmer` 按契约做最小实现。
5. `godot-tech-troubleshooter` 跑跨场景回归，确认无空引用和信号异常。
6. `godot-docs-maintainer` 更新任务清单与验收记录。

## 统一约束

- 必须遵循 `docs/AI_GAME_ENGINEERING_PROTOCOL.md`。
- 禁止同一能力出现两套并行逻辑（如世界和试炼各自维护一套移动/战斗）。
- 任何公共方法改动都要同步检查 `Scripts/` 全量调用点。
- 优先做最小增量，避免一次性大重构。

## 输出模板

- 模块：<地图/角色/任务/...>
- 当前状态：<已实现能力>
- 缺口与风险：<按 P0/P1/P2>
- 实施建议：<最小改动路径>
- 回归清单：<场景切换、输入、节点路径、音频、战斗>

## 完成前检查

- [ ] 世界主流程可运行（进入、移动、交互、返回）
- [ ] 动作与输入映射一致（`project.godot` 与脚本匹配）
- [ ] 怪物与任务链路无空引用节点
- [ ] 材料/图标资源路径正确且 UI 可显示
- [ ] BGM/SFX 在正确时机触发且不重叠失控
