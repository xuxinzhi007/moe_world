---
name: "moe-community-scripts"
description: "脚本开发入口。用于在现有 Godot 架构中实现功能，避免碎片逻辑和重复实现。"
---

# Moe World 脚本开发技能

## 用途

编写或修改 GDScript 逻辑时使用。

## 开发约束

- 只在现有系统内扩展，不新建平行系统
- 最小必要改动
- 世界/试炼同核异皮（核心逻辑尽量共享）
- 显式考虑信号生命周期（connect/disconnect 对称）

## 任务输出格式

1. 目标
2. 修改文件
3. 关键改动点
4. 风险与回归
5. 手测步骤

## 优先读取

- `docs/AI_GAME_ENGINEERING_PROTOCOL.md`
- `docs/ARCHITECTURE.md`
- `docs/OPTIMIZATION_TEST_CHECKLIST.md`
- `docs/SCENE_STRUCTURE_CLASSIFICATION.md`
- `docs/PROJECT_FILE_STRUCTURE_CN.md`
