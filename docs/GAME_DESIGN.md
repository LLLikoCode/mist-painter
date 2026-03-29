# 迷雾绘者 (Mist Painter) - 游戏设计文档

> **版本:** v2.0
> **最后更新:** 2026-03-29
> **核心概念:** 探索 → 绘制 → 发现 → 深入

---

## 1. 游戏概述

### 1.1 一句话描述
> 在迷雾笼罩的古代迷宫中，你是一名依靠手绘地图求生的探险者。

### 1.2 核心循环
```
┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐
│  探索   │ → │  绘制   │ → │  发现   │ → │  深入   │
│ (移动)  │    │ (记录)  │    │ (秘密)  │    │ (下层)  │
└─────────┘    └─────────┘    └─────────┘    └────┬────┘
     ↑─────────────────────────────────────────────┘
```

### 1.3 游戏特色
- **手动绘制地图** - 不是自动全开，而是需要玩家亲手记录
- **记忆会衰退** - 长时间不回访，地图会变得模糊
- **工具有限制** - 纸张、墨水、光源都是稀缺资源
- **迷宫会变化** - 深层迷宫是动态的，考验真实记忆

---

## 2. 系统架构总览

| 系统 | 关键设计 | 复杂度 | 文档 |
|------|---------|--------|------|
| 迷雾绘制系统 | 三层视野 + 绘制工具 + 墨水消耗 | ⭐⭐⭐⭐⭐ | [mist-painting-system.md](design/mist-painting-system.md) |
| 迷宫生成系统 | 递归回溯 + 房间插入 + 动态层 | ⭐⭐⭐⭐ | [maze-generation.md](design/maze-generation.md) |
| 玩家资源系统 | HP/SP/墨水/体力 | ⭐⭐⭐ | [player-stats.md](design/player-stats.md) |
| 地图记忆系统 | 记忆衰退 + 精度误差 | ⭐⭐⭐⭐ | [map-memory-system.md](design/map-memory-system.md) |
| 光源系统 | 视野 + 光源管理 | ⭐⭐⭐ | [light-system.md](design/light-system.md) |
| 心理状态系统 | 压力/幻觉/恢复 | ⭐⭐⭐⭐ | [mental-state-system.md](design/mental-state-system.md) |
| 职业系统 | 5职业 + 技能树 | ⭐⭐⭐ | [class-system.md](design/class-system.md) |
| 难度系统 | 动态难度 + 多等级 | ⭐⭐⭐ | [difficulty-system.md](design/difficulty-system.md) |
| 进度系统 | 等级/解锁/多周目 | ⭐⭐⭐ | [progression-system.md](design/progression-system.md) |
| 关卡过渡 | 墨水晕染动画 | ⭐⭐⭐ | [level-transition-design.md](design/level-transition-design.md) |
| 存档系统 | 多槽位 + 云同步 | ⭐⭐ | [save-system.md](design/systems/save-system.md) |
| 成就系统 | 解锁/通知/奖励 | ⭐⭐ | [achievement-design.md](design/achievement-design.md) |
| 美术风格 | 羊皮纸 + 手绘感 | ⭐⭐⭐ | [art-style-guide.md](design/art/art-style-guide.md) |

---

## 3. 核心玩法机制

### 3.1 迷雾绘制 (核心机制)

玩家使用特殊能力在迷雾中绘制可见区域：

**三层视野模型:**
```
[真实视野]  ← 玩家实际能看到的范围（3-5格）
    ↓
[记忆地图]  ← 玩家绘制在纸上的地图（可能有误差）
    ↓
[迷雾区域]  ← 未探索或已遗忘的区域
```

**绘制工具:**

| 工具 | 精度 | 速度 | 可修改 | 耐久 | 墨水消耗 |
|------|------|------|--------|------|----------|
| 铅笔 | 85% | 快 | ✓ | 100划 | 低 |
| 羽毛笔 | 95% | 中 | ✗ | 50划 | 中 |
| 测绘仪 | 99% | 慢 | - | 无限 | 高 |
| 魔法卷轴 | 100% | 极快 | - | 1次 | 极高 |

详细设计: [map-memory-system.md](design/map-memory-system.md)

### 3.2 迷宫探索

**迷宫层级:**

| 层级 | 名称 | 尺寸 | 特点 | 记忆衰退 |
|------|------|------|------|----------|
| Layer 1 | 表层遗迹 | 21×21 | 教学层 | 30分钟 |
| Layer 2 | 古代回廊 | 31×31 | 中等难度 | 20分钟 |
| Layer 3 | 迷失深渊 | 41×41 | 高难度 | 10分钟 |
| Layer 4 | 混沌核心 | 51×51 | 极限挑战 | 5分钟 |

**特殊地形:**

| 类型 | 说明 | 出现层级 |
|------|------|----------|
| 入口/出口 | 上下层连接 | 所有 |
| 隐藏门 | 需发现才能通过 | L2+ |
| 传送点 | 成对瞬移 | L3+ |
| 陷阱 | 负面效果 | L2+ |
| 密室 | 宝藏房间 | L2+ |

详细设计: [maze-generation.md](design/maze-generation.md)

### 3.3 资源管理

**玩家资源:**

| 资源 | 初始值 | 上限 | 用途 |
|------|--------|------|------|
| HP (生命值) | 100 | 200 | 生存 |
| SP (精神值) | 50 | 100 | 技能 |
| 墨水 | 50 | 100 | 迷雾绘制 |
| 体力 | 100 | 200 | 移动/动作 |

**体力消耗:**

| 动作 | 消耗 |
|------|------|
| 移动1格 | 1点 |
| 奔跑1格 | 2点 |
| 绘制地图 | 5点 |
| 战斗 | 15-30点 |

详细设计: [player-stats.md](design/player-stats.md)

### 3.4 光源系统

**光源类型:**

| 类型 | 持续时间 | 照明范围 | 特殊效果 |
|------|----------|----------|----------|
| 火把 | 10分钟 | +2格 | 可投掷 |
| 提灯 | 30分钟 | +3格 | 可关闭 |
| 荧光石 | 无限 | +1格 | 微弱 |
| 魔法光球 | 5分钟 | +4格 | 跟随 |

**黑暗惩罚:**

| 黑暗程度 | 视野 | 移动惩罚 | 绘制惩罚 |
|----------|------|----------|----------|
| 微光 | -1格 | 无 | 误差+10% |
| 昏暗 | -2格 | 速度-10% | 误差+25% |
| 黑暗 | -3格 | 速度-25% | 无法绘制 |
| 漆黑 | 仅1格 | 速度-50% | 无法绘制 |

详细设计: [light-system.md](design/light-system.md)

---

## 4. 进阶系统

### 4.1 心理状态系统

**压力机制:**

| 压力范围 | 状态 | 效果 |
|----------|------|------|
| 0-30 | 冷静 | 无惩罚 |
| 30-50 | 紧张 | 绘图误差+10% |
| 50-70 | 焦虑 | 误差+20%，手抖 |
| 70-85 | 恐慌 | 误差+35%，幻觉 |
| 85-100 | 崩溃 | 误差+50%，频繁幻觉 |

**幻觉类型:**
- 虚假通道 - 墙上显示不存在的门
- 错误标记 - 已探索区域显示为未探索
- 幽灵敌人 - 不存在的怪物
- 地图扭曲 - 绘制线条偏移

详细设计: [mental-state-system.md](design/mental-state-system.md)

### 4.2 职业系统

**5种职业:**

| 职业 | 特性 | 起始装备 |
|------|------|----------|
| 测绘师 | 绘图精度+30% | 测绘仪+羊皮纸×5 |
| 探险家 | 视野+2格，移动+20% | 提灯+火把×3 |
| 考古学家 | 解读符号，发现隐藏×2 | 古文字手册 |
| 生存专家 | 体力消耗-20%，压力-30% | 食物×5+药水×2 |
| 信使 | 地图副本×2 | 魔法纸×3 |

**技能树:**
```
制图系: 精准测绘 → 快速绘图 → 记忆强化 → 预知路径
生存系: 体能训练 → 轻装上阵 → 疾行 → 危机直觉
洞察系: 细节观察 → 模式识别 → 第六感 → 历史回溯
```

详细设计: [class-system.md](design/class-system.md)

### 4.3 难度系统

**难度等级:**

| 难度 | 敌人强度 | 资源 | 记忆衰退 | 动态迷宫 |
|------|----------|------|----------|----------|
| 简单 | -30% | +30% | -30% | 关闭 |
| 普通 | 基准 | 基准 | 基准 | L3+ |
| 困难 | +30% | -30% | +30% | L2+ |
| 噩梦 | +50% | -50% | +50% | L1+ |
| 混沌 | +100% | -70% | +100% | 全部 |

详细设计: [difficulty-system.md](design/difficulty-system.md)

---

## 5. 游戏循环

### 5.1 会话结构

**目标时长:** 15-30分钟

```
[开始] → [第1层: 教学] → [第2层: 进阶] → [第3层: 高难] → [第4层: Boss] → [结算]
   │           │                │                │              │
 0:00        2:00             10:00            18:00          25:00
```

### 5.2 事件卡组系统

将任务/事件设计成"卡牌"，根据玩家状态"发牌":

| 玩家状态 | 优先事件类型 | 目的 |
|----------|--------------|------|
| 体力充足 | 探索/挑战 | 鼓励深入 |
| 体力不足 | 安全/恢复 | 提供喘息 |
| 压力低 | 发现/叙事 | 沉浸体验 |
| 压力高 | 安全/幻觉 | 制造紧张 |
| 迷路中 | 指引/线索 | 防止挫败 |

详细设计: [game-loop-design.md](design/game-loop-design.md)

---

## 6. 美术风格

### 6.1 色彩系统

```css
/* 羊皮纸色系 */
--paper-light: #f5f0e1;
--paper-medium: #e8dcc4;
--paper-dark: #d4c4a8;

/* 墨水色系 */
--ink-black: #1a1a1a;
--ink-faded: #5a5a5a;

/* 功能色 */
--accent-gold: #c9a227;
--accent-red: #8b3a3a;
--accent-green: #4a7c59;
--accent-blue: #4a6fa5;

/* 迷雾色 */
--mist-dark: #0a0a0a;
--mist-light: #2a2520;
```

### 6.2 视觉风格

- **地图界面**: 中世纪航海图、羊皮纸质感
- **游戏世界**: 像素艺术 + 手绘质感
- **UI**: 复古纸张、墨水书写
- **参考**: Darkest Dungeon, Loop Hero

详细设计: [art-style-guide.md](design/art/art-style-guide.md)

---

## 7. 扩展功能

### 7.1 Roguelike模式

- 死亡保留: 地图知识(模糊化)、等级/技能、解锁内容
- 死亡丢失: 金币(50%)、物品(全部)

### 7.2 多人合作

- 2-4人组队探索
- 地图可交换副本(可能有误差)
- 分工: 测绘师、探险家、资源官、记录员

### 7.3 每日挑战

- 固定种子迷宫
- 排行榜: 最快完成/最高完整度/最少资源

### 7.4 成就系统

| 类别 | 示例成就 |
|------|----------|
| 探索 | 深渊行者(到达第4层)、完美绘者(100%完整度) |
| 技巧 | 鹰眼(发现10个隐藏门)、黑暗大师(无光源完成) |
| 收集 | 制图师(收集所有古代地图碎片) |

详细设计: [expansion-features.md](design/expansion-features.md)

---

## 8. 技术架构

### 8.1 技术栈

```yaml
引擎: Godot 4.x
语言: GDScript
平台: PC, Web
渲染: Mobile
```

### 8.2 系统架构

```
├── Core (核心系统)
│   ├── GameStateManager (游戏状态管理)
│   ├── EventBus (事件总线)
│   └── SaveManager (存档系统)
├── Gameplay (游戏玩法)
│   ├── MistPaintingSystem (迷雾绘制系统)
│   ├── MazeGenerator (迷宫生成器)
│   ├── PlayerController (玩家控制器)
│   └── GameController (游戏主控制器)
├── Systems (游戏系统)
│   ├── VisionSystem (视野系统)
│   ├── MemorySystem (记忆系统)
│   ├── LightSystem (光源系统)
│   └── StaminaSystem (体力系统)
├── Player (玩家)
│   ├── PlayerStats (玩家资源)
│   └── Inventory (背包系统)
├── UI (用户界面)
│   ├── HUD (游戏HUD)
│   ├── MainMenu (主菜单)
│   └── MapInterface (地图界面)
├── Audio (音频)
│   └── AudioManager (音频管理器)
└── Achievements (成就)
    └── AchievementManager (成就管理器)
```

详细设计: [tech-architecture.md](design/tech-architecture.md)

---

## 9. 文档索引

### 核心玩法系统 (`design/gameplay/`)
- [迷雾绘制系统](design/gameplay/mist-painting-system.md)
- [迷宫生成系统](design/gameplay/maze-generation.md)
- [地图记忆系统](design/gameplay/map-memory-system.md)
- [光源系统](design/gameplay/light-system.md)
- [心理状态系统](design/gameplay/mental-state-system.md)
- [游戏循环设计](design/gameplay/game-loop-design.md)
- [关卡过渡设计](design/gameplay/level-transition-design.md)
- [扩展功能设计](design/gameplay/expansion-features.md)

### 玩家系统 (`design/player/`)
- [玩家资源系统](design/player/player-stats.md)
- [职业系统](design/player/class-system.md)

### 技术文档 (`design/technical/`)
- [技术架构](design/technical/tech-architecture.md)
- [核心接口](design/technical/core-interfaces.md)
- [UI系统设计](design/technical/ui-system-design.md)
- [音频系统](design/technical/audio-system.md)
- [CI/CD配置](design/technical/ci-cd-setup.md)

### 系统设计 (`design/`)
- [难度系统](design/difficulty-curve.md)
- [进度系统](design/progression-system.md)
- [成就系统](design/achievement-design.md)
- [存档系统](design/systems/save-system.md)

### 美术文档 (`design/art/`)
- [美术风格指南](design/art/art-style-guide.md)
- [角色精灵规范](design/art/character-sprite-spec.md)
- [Tileset设计](design/art/tileset-design.md)
- [特效设计](design/art/effects_design_doc.md)

### 性能优化 (`performance/`)
- [迷雾优化](performance/mist-optimization.md)
- [性能测试数据](performance/performance-test-data.md)

### 参考文档 (`design/reference/`)
- [核心玩法参考](design/reference/01-core-gameplay.md)
- [地图绘制参考](design/reference/02-map-drawing.md)
- [迷宫生成参考](design/reference/03-maze-generation.md)
- [数值平衡参考](design/reference/04-game-balance.md)
- [美术风格参考](design/reference/05-art-style.md)
- [扩展玩法参考](design/reference/06-expansion.md)
- [技术规格参考](design/reference/07-technical-spec.md)

---

*文档最后更新: 2026-03-29*