# 素材统一规范

## 目标

当前项目的核心美术问题不是“缺素材”，而是“来源太杂”。  
后续无论是 AI 生成、外包、手工改图，先统一下面这些约束，否则继续加素材只会更乱。

## 统一方向

推荐把当前项目固定为：

- 类型：`2D 萌系轻奇幻 / 社区感冒险世界`
- 视角：`俯视偏斜 2D`，不要混纯侧视、纯正顶视、写实透视
- 气质：`温暖、轻松、可爱、低压迫感`
- 关键词：`moe / cozy / pastel / clean / playful / readable`

## 视觉规则

### 角色

- 头身比统一偏 Q 版，不要写实比例
- 外轮廓清晰，优先可读性，不追求细碎细节
- 明暗层数控制在 `2 到 3` 层
- 统一柔和高光，不要一部分是厚涂、一部分是像素、一部分是写实贴图

### 怪物

- 同一生态区的怪物保持同一轮廓语言
- 低级怪物圆润、简单；精英/Boss 才增加尖锐结构
- 禁止混入明显不同画风的素材包直出图
- 怪物攻击特效和本体配色要关联，避免“本体萌系 + 特效写实火焰”

### 场景装饰

- 地面、树木、石头、水塘、房屋必须统一边缘处理和明暗方向
- 装饰默认服务于地图可读性，不能比角色还抢眼
- 单张素材细节密度不能过高，否则一眼就能看出拼接来源不同

### 特效

- 世界内特效统一为轻量卡通发光
- 禁止同时混用写实爆炸、像素闪光、手绘魔法阵三种语言
- 技能特效优先强调形状和颜色识别，不靠超多粒子堆满屏

### UI

- `UI 图标优先保留 SVG/矢量体系`
- 不建议把现在的按钮和功能图标改成 AI 栅格图
- AI 更适合补：背景图、角色半身、NPC 立绘、怪物贴图、技能插画

## 配色原则

- 主世界：暖粉、奶白、浅青、嫩绿
- 城镇：偏暖，低对比
- 野区：偏绿和土黄，但饱和度不要脏
- 危险区域：可以提高冷暖对比，但不要整体转写实暗黑

建议约束：

- 高饱和强调色不超过 `2 到 3` 个
- 阴影统一偏冷或偏中性，不要每套素材都各自一套光照逻辑

## 生成优先级

### 第一批值得替换

- NPC 头像与世界内角色贴图
- 怪物基础贴图
- 地面装饰大件：树、石、水塘、草坑
- 试炼场背景与关键装饰

### 第二批再做

- 技能特效序列帧
- 掉落物图标
- 世界区域宣传图 / Hall 展示图

### 不建议现在动

- 顶栏功能图标
- 基础按钮 UI
- 纯代码生成的 HUD 元素

## AI 生成落地规则

### 输出约束

- 单体角色/怪物：留足透明边距
- 地图装饰：正交感强，避免透视漂移
- 同类素材必须按一套 prompt 模板批量出
- 每类素材至少固定：
  - 视角
  - 光照方向
  - 线条强弱
  - 阴影层数
  - 饱和度区间

### Prompt 模板

#### 1. NPC / 玩家立绘

```text
Use case: stylized-concept
Asset type: 2D game character sprite reference
Primary request: cute fantasy town resident for a cozy anime-style community adventure game
Scene/backdrop: plain solid background for later cutout
Subject: full-body chibi character, readable silhouette, friendly expression
Style/medium: clean 2D game illustration, soft cel shading, consistent outline weight
Composition/framing: centered, full body, generous padding
Lighting/mood: soft front lighting, warm and welcoming
Color palette: pastel warm tones with one accent color
Constraints: no realistic rendering, no complex background, no watermark, no text
Avoid: photorealism, gritty texture, dark horror mood, over-detailed costume
```

#### 2. 怪物贴图

```text
Use case: stylized-concept
Asset type: 2D monster sprite reference
Primary request: cute but hostile field monster for a top-down cozy fantasy action RPG
Scene/backdrop: plain solid background for later cutout
Subject: single monster, bold silhouette, readable attack posture
Style/medium: clean stylized 2D game art, soft cel shading
Composition/framing: centered, full body
Lighting/mood: simple readable lighting
Color palette: limited palette, one dominant hue family
Constraints: game-readable, not scary-gory, no background clutter, no watermark
Avoid: realistic anatomy, painterly mud, photo texture, inconsistent perspective
```

#### 3. 地图装饰

```text
Use case: stylized-concept
Asset type: 2D world prop
Primary request: hand-painted cozy fantasy environment prop for a top-down game
Scene/backdrop: plain solid background for later cutout
Subject: single prop such as tree, rock, pond, grass patch, lantern, or market object
Style/medium: clean stylized 2D illustration, simplified forms, soft shadow
Composition/framing: centered object with padding
Lighting/mood: soft daylight
Color palette: pastel natural tones
Constraints: readable at small size, no complex scene, no watermark, no text
Avoid: realistic texture noise, dramatic perspective, dark horror vibe
```

## 工程配合规则

- 新生成素材先放临时目录，再人工筛选
- 入库前统一命名和尺寸
- 一个系统只允许存在一套正式素材
- 旧素材如果还保留，必须标记 `legacy` 或 `deprecated`

## 当前建议

- 先不要立即全量重画
- 先确定一套统一风格，然后只替换最显眼的 `NPC / 怪物 / 大件装饰`
- 等 `world_scene` 结构再干净一点，再批量替换世界内容素材
