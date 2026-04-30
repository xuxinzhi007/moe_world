---
name: "moe-community-nodes"
description: "场景与节点任务入口。用于修改 .tscn 前确认真实节点结构，避免引用过期路径。"
---

# Moe World 节点结构技能

## 用途

修改任何场景/节点前使用，确保脚本路径与节点层级一致。

## 标准步骤

1. 先读目标 `.tscn` 真实结构（不要依赖旧文档复制）
2. 对照调用脚本中的 `@onready` 路径
3. 修改后执行路径回归（关键交互至少 1 次）

## 必查文件

- `Scenes/**/*.tscn`
- `Scripts/world/world_scene.gd`
- `Scripts/player/player.gd`
- `Scripts/survivor/survivor_arena.gd`

## 输出要求

- 列出改动节点路径
- 列出受影响脚本路径
- 给出“路径契约未破坏”的验证步骤
