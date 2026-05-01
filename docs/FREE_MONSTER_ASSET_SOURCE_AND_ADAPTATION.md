# 免费怪物素材源与适配规范

## 1) 已采用的免费包（可商用）

- 来源：Kenney `Monster Builder Pack`
- 本地包路径：`Assets/external/kenney/monster-builder-pack/`
- 许可证：CC0 1.0（可商用、可修改、无需强制署名）
- 许可证文件：`Assets/external/kenney/monster-builder-pack/License.txt`

## 2) 本项目当前使用的素材映射

- 喷吐怪（`SpitterMonster`）
  - 贴图：`Assets/external/kenney/monster-builder-pack/PNG/Default/body_greenF.png`
  - 场景：`Scenes/SpitterMonster.tscn`

- 重击怪（`BruteMonster`）
  - 贴图：`Assets/external/kenney/monster-builder-pack/PNG/Default/body_darkA.png`
  - 场景：`Scenes/BruteMonster.tscn`

## 3) 适配规范（统一口径）

1. 尺寸与缩放
   - 怪物根节点 `BodySprite.scale` 统一在 `0.50 ~ 0.70` 区间，避免体型失控。
2. 深度与遮挡
   - 怪物使用 `z_index = floor(global_position.y)` 动态排序，和玩家一致。
3. 头顶信息
   - 每只怪必须显示：`Lv.X 名字` 与 `HP 当前/上限`。
4. 攻击可读性
   - 远程怪必须有可见弹道（飞行体）再结算命中，不允许纯瞬发不可见。
5. 场景一致性
   - 大世界与试炼共享同一怪物脚本与核心攻击行为，只允许数值参数不同。

## 4) 后续可继续替换的推荐部件

可从同一 Kenney 包内替换以下分层部件（不改代码）：
- `body_*.png`（体型主轮廓）
- `eye_*.png`（眼睛风格）
- `mouth_*.png`（攻击表情）
- `detail_*_horn_*.png`、`detail_*_antenna_*.png`（辨识特征）

建议保留“怪物名字 + 攻击方式 + 色相”三元一致性，避免玩家认知混乱。

## 5) 可直接补充的免费资源（可用）

- Kenney `Tiny Dungeon`（CC0，适合背包材料图标与地表小物）
  - https://kenney.nl/assets/tiny-dungeon
- Kenney `Pixel Platformer`（CC0，可补充材料 icon 与 UI 小图）
  - https://kenney.nl/assets/pixel-platformer
- OpenGameArt `CC0 Monsters` 合集（需逐条确认 license 标签）
  - https://opengameart.org/art-search-advanced?keys=monster&field_art_type_tid%5B%5D=9&sort_by=count&sort_order=DESC&items_per_page=24

> 接入前规则：仅接收 `CC0` 或 `CC-BY`（可商用）并在项目文档记录来源与许可证。

## 6) 怪物 UI / 图鉴可用免费素材

- Kenney `UI Pack`（CC0，按钮/面板/图标底板）
  - https://kenney.nl/assets/ui-pack
- Kenney `Game Icons`（CC0，技能/状态图标）
  - https://kenney.nl/assets/game-icons
- OpenGameArt `CC0 UI Icons`（筛选 CC0 后接入）
  - https://opengameart.org/art-search-advanced?keys=ui+icon&field_art_type_tid%5B%5D=10
