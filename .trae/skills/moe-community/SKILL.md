---
name: "moe-community"
description: "Moe World 主入口技能。用于分发到 core/nodes/scripts/api/check 子技能，并强制遵循工程化开发协议。"
---

# Moe World 主入口技能

## 用途

当你需要开发、修复或规划本项目时，先调用本技能，再按任务类型调用子技能。

## 强制流程

1. 先调用 `moe-community-core`（确认当前项目状态与约束）
2. 根据任务类型调用以下之一：
   - 节点/场景：`moe-community-nodes`
   - 脚本/逻辑：`moe-community-scripts`
   - API/网络：`moe-community-api`
   - 回归/排错：`moe-community-check`
3. 开发完成后必须回到 `moe-community-check` 做收口

## 工程约束（必须）

- 先架构后功能，先闭环后扩展
- 禁止碎片代码与平行系统
- 最小改动优先
- 世界/试炼遵循同核异皮

## 权威文档

- `docs/AI_GAME_ENGINEERING_PROTOCOL.md`
- `docs/PRODUCT_MANAGER_GAME_WORLD_PLAN.md`
- `docs/SUBAGENT_EXECUTION_BOARD.md`
- `docs/OPTIMIZATION_TEST_CHECKLIST.md`
