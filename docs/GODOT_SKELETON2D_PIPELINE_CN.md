# Godot 骨骼动画实施指南（Skeleton2D + AnimationPlayer）

> 目标：在本项目中用“骨骼动画”替代不稳定的 AI 序列帧方案，实现角色行走/攻击动作稳定迭代。  
> 适用版本：Godot 4.4

---

## 1. 为什么选骨骼动画

- 动作稳定：不再依赖 8/12 帧序列图的一致性。
- 风格统一：同一套角色部件驱动所有动作，脸和比例不漂移。
- 迭代成本低：改动作只改关键帧，不需要整套重画。
- 项目友好：可逐步接入，不用一次性推翻现有逻辑。

---

## 2. 在当前项目中的接入策略（最小改动）

当前 `Player` 逻辑已经兼容 `AnimatedSprite2D` 或 `Sprite2D` 两种视觉模式，建议新增第三种：

- 新建一个角色场景：`Scenes/actors/PlayerSkeleton.tscn`
- 场景根节点仍为 `CharacterBody2D`，继续挂 `Scripts/player/player.gd`
- 只替换“视觉节点层”，移动、战斗、碰撞、联机同步逻辑保持不变

> 先做“本地玩家（单机）可见”的骨骼动画，稳定后再扩到远端玩家/NPC。

---

## 3. 建议节点结构模板

```text
Player (CharacterBody2D) [script: Scripts/player/player.gd]
├── VisualRoot (Node2D)
│   ├── Skeleton2D
│   │   ├── Bone2D_Torso
│   │   │   ├── Bone2D_Head
│   │   │   ├── Bone2D_Arm_L
│   │   │   │   └── Bone2D_Hand_L
│   │   │   ├── Bone2D_Arm_R
│   │   │   │   └── Bone2D_Hand_R
│   │   │   ├── Bone2D_Leg_L
│   │   │   │   └── Bone2D_Foot_L
│   │   │   └── Bone2D_Leg_R
│   │   │       └── Bone2D_Foot_R
│   │   ├── Sprite2D_Body
│   │   ├── Sprite2D_Head
│   │   ├── Sprite2D_Arm_L
│   │   ├── Sprite2D_Arm_R
│   │   ├── Sprite2D_Leg_L
│   │   ├── Sprite2D_Leg_R
│   │   └── Sprite2D_Weapon
│   ├── AnimationPlayer
│   └── AnimationTree (可选，后续再加)
└── CollisionShape2D
```

命名建议：

- 骨骼节点统一 `Bone2D_*`
- 部件图统一 `Sprite2D_*`
- 动画命名统一：`idle` / `walk` / `attack` / `hit` / `death`

---

## 4. 美术拆件规范（非常关键）

每个角色至少拆为：

- 头（Head）
- 身体（Torso/Body）
- 左臂、右臂（Arm_L/Arm_R）
- 左腿、右腿（Leg_L/Leg_R）
- 武器（Weapon，建议独立）

资源规范：

- 推荐 PNG 透明底
- 每个部件在同一原点体系导出（避免导入后漂移）
- 命名统一：`char_warrior_head.png`、`char_warrior_arm_l.png`
- 放置目录建议：`Assets/characters/skeleton/<角色名>/`

---

## 5. 动画制作流程（Godot 内）

## 5.1 绑定阶段

1. 创建 `Skeleton2D` 和骨骼层级  
2. 将每个 `Sprite2D_*` 放到对应骨骼下  
3. 校准初始 T-Pose / Idle Pose

## 5.2 动画阶段（先做 walk）

在 `AnimationPlayer` 新建 `walk`：

- 时长建议：0.6~0.8 秒
- 循环：开启 loop
- 关键轨道：
  - 双腿旋转（交替摆动）
  - 双臂反向摆动
  - Torso 轻微上下浮动（2~4 像素）
- 注意保持武器长度、手部握点稳定

## 5.3 攻击动画（attack）

- 时长建议：0.25~0.45 秒
- 分三段：
  - 蓄力（0~30%）
  - 出手（30~70%）
  - 收招（70~100%）
- 在“出手”时间点打 `call method track` 触发命中判定（后续可接）

---

## 6. 与现有脚本的衔接建议

当前 `player.gd` 里 `_setup_visuals()` 会优先找 `AnimatedSprite2D`。  
要接入骨骼动画，建议新增轻量分支：

- 优先检测 `VisualRoot/Skeleton2D` 是否存在
- 存在则跳过 `AnimatedSprite2D` 与 `CharacterSprite` 自动创建逻辑
- 新增 `_play_anim(name)`，根据移动/攻击状态触发 `AnimationPlayer`

状态映射建议：

- 速度接近 0 -> `idle`
- 正在移动 -> `walk`
- 攻击输入触发 -> `attack`

> 保持 `CollisionShape2D`、血条、名字、经验条逻辑不动，避免引入额外风险。

---

## 7. 分阶段落地计划（推荐）

### Phase 1（1-2 天）

- 战士单角色接入骨骼 `idle + walk`
- 单机场景验证移动与头顶 UI 不抖动

### Phase 2（1 天）

- 补 `attack` 动画
- 接通攻击节奏点（方法轨道）

### Phase 3（1-2 天）

- 扩展到弓手/法师/牧师
- 统一命名和资源目录

### Phase 4（可选）

- 加 `AnimationTree` 做状态机过渡（idle<->walk 更平滑）

---

## 8. 验收清单（你可直接照测）

- [ ] 行走循环无“抽搐/断帧/脚滑”
- [ ] 攻击动作武器轨迹稳定，不穿帮
- [ ] 角色镜像翻转后动作仍正确（左右朝向）
- [ ] 头顶 UI（名字/血条/经验条）位置稳定
- [ ] 与现有碰撞、受击、技能逻辑不冲突
- [ ] 大世界与试炼场景都可正常显示与播放动作

---

## 9. 常见坑与规避

- 坑：部件原点不统一 -> 动作时“肢体飞走”  
  规避：导出前统一部件坐标系与锚点。

- 坑：武器跟手点不固定 -> 攻击抖动  
  规避：武器挂在 `Hand` 子骨骼，出手只旋转上臂/前臂。

- 坑：先做复杂状态机 -> 调试困难  
  规避：先用 `AnimationPlayer` 直连状态，稳定后再上 `AnimationTree`。

- 坑：一次替换全部职业 -> 回归风险高  
  规避：按职业逐步替换，先战士打样。

---

## 10. 建议新增目录

```text
Assets/characters/skeleton/
├── warrior/
│   ├── body.png
│   ├── head.png
│   ├── arm_l.png
│   ├── arm_r.png
│   ├── leg_l.png
│   ├── leg_r.png
│   └── weapon.png
└── mage/...
```

---

## 11. 与现有文档关系

- 场景分类规范：`docs/SCENE_STRUCTURE_CLASSIFICATION.md`
- 项目结构总览：`docs/PROJECT_FILE_STRUCTURE_CN.md`
- 架构基线：`docs/ARCHITECTURE.md`
- 测试回归：`docs/OPTIMIZATION_TEST_CHECKLIST.md`
