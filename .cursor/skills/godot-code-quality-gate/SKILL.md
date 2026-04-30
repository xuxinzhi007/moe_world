---
name: godot-code-quality-gate
description: 在提交前执行 Godot 项目代码质量门禁，检查脚本契约、节点路径、输入映射和模式分支风险。用户提到质量检查、提交前审核、回归风险时使用。
---

# 代码质量门禁

## 目标

在开发完成后做一次统一质量门禁，降低回归风险。

## 门禁项

1. 脚本契约：公共方法改动是否同步所有调用点。
2. 节点路径：脚本引用路径是否与 `.tscn` 一致。
3. 输入映射：`project.godot` 与脚本动作名是否一致。
4. 模式分支：单机/联机、世界/试炼是否都验证过。
5. UI 叠层：弹层优先级与输入阻断是否符合预期。

## 重点文件

- `project.godot`
- `Scripts/world/world_scene.gd`
- `Scripts/player/player.gd`
- `Scripts/survivor/survivor_arena.gd`
- `Scenes/ui/*.tscn`

## 输出格式

- 风险分级（高/中/低）
- 每条风险的影响范围
- 最小修复建议
- 提交前手测清单
