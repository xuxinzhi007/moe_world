---
name: godot-flow-consistency-check
description: 审查并修复大厅、登录、世界、试炼、返回路径的流程一致性问题。用户提到“流程不完整、跳转异常、状态不一致、入口出口检查”时使用。
---

# 流程一致性检查

## 目标

保证主流程闭环可用：启动 -> 大厅 -> 登录/联机 -> 世界 -> 试炼 -> 返回。

## 检查清单

1. 入口是否清晰：大厅按钮、登录跳转、联机房间输入。
2. 退出是否清晰：返回大厅、退出游戏、试炼回城。
3. 失败分支是否可恢复：联机失败、超时、鉴权失败。
4. 状态是否一致：登录态/游客态、单机/联机 HUD 差异。
5. 输入是否冲突：地图、对话、攻击、移动端按钮。

## 重点文件

- `Scripts/meta/hall_scene.gd`
- `Scripts/auth/login_screen.gd`
- `Scripts/world/world_scene.gd`
- `Scripts/survivor/survivor_arena.gd`
- `Scripts/autoload/world_network.gd`

## 输出格式

- 问题清单（按严重度）
- 每个问题的最小修复方案
- 回归测试步骤（按流程顺序）

## 完成标准

- 所有主路径都能“进得去、退得出、失败可恢复”。
