---
name: "moe-community-api"
description: "API 与网络相关任务入口。用于规范后端/云端联机/本地服务对接，不依赖过期端口文档。"
---

# Moe World API 技能

## 用途

处理认证、云端同步、聊天、联机状态等网络相关改动。

## 开工前检查

- 先读取当前实现而非历史记录：
  - `Scripts/auth/*.gd`
  - `Scripts/autoload/world_network.gd`
  - `Scripts/world/world_scene.gd`
- 若发现端口、URL、路径与文档冲突，以**当前代码**为准并回写文档。

## 输出要求

- 明确接口输入/输出和失败兜底
- 明确单机/联机分支行为
- 列出断网、超时、重连、重复回调的回归点

## 禁止事项

- 禁止写死本地机器绝对路径
- 禁止只改请求代码不改错误处理
