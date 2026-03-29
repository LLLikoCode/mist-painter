# 地图记忆系统

> **系统:** Map Memory System
> **重要性:** ⭐ 核心机制
> **设计理念:** 记忆不是永恒的，地图需要维护

---

## 1. 系统概述

### 1.1 核心概念

玩家绘制的地图不是永久准确的，会随着时间推移而衰退。这创造了一个独特的游戏循环：探索 → 绘制 → 回访确认 → 深入。

### 1.2 记忆模型

```
[当前视野]  →  [绘制到地图]  →  [存储为记忆]  →  [随时间衰退]
      ↓              ↓               ↓               ↓
   100%准确       可能有误差       固定准确度       逐渐模糊
```

---

## 2. 记忆衰退机制

### 2.1 衰退公式

```
记忆清晰度 = max(最低保留值, 初始准确度 - (经过时间 / 衰退周期) × 衰退率)
```

### 2.2 层级衰退参数

| 层级 | 衰退周期 | 衰退率 | 最低保留 |
|------|----------|--------|----------|
| 表层遗迹 | 30分钟 | 20% | 20% |
| 古代回廊 | 20分钟 | 35% | 15% |
| 迷失深渊 | 10分钟 | 50% | 10% |
| 混沌核心 | 5分钟 | 80% | 5% |

### 2.3 衰退视觉表现

```
清晰度 100%:  ████████████████████  深黑，清晰
清晰度 70%:   █████████████████░░░  略淡，轻微模糊
清晰度 50%:   █████████████░░░░░░░  明显变淡
清晰度 30%:   ███████░░░░░░░░░░░░░  只剩轮廓
清晰度 10%:   ██░░░░░░░░░░░░░░░░░░  几乎消失
```

---

## 3. 准确度与误差

### 3.1 初始准确度

绘制时的准确度取决于：

| 因素 | 影响 |
|------|------|
| 工具精度 | 铅笔85%，羽毛笔95%，测绘仪99% |
| 环境条件 | 黑暗-20%，迷雾-25% |
| 玩家状态 | 疲劳-10%，恐慌-25% |
| 是否移动 | 移动中+15%误差 |

### 3.2 误差类型

#### 距离误差
```
实际:     绘制:
┌───┐     ┌───┐
│ A ══ B  │ A ═ B  (距离缩短)
└───┘     └───┘
```

#### 角度误差
```
实际:     绘制:
  B         B
 /          |
A           A─── (角度变直)
```

#### 遗漏误差
```
实际:     绘制:
A ═══ B   A ═══ B
║     ║   ║
C ═══ D   C     D (遗漏通道)
```

#### 幻觉误差 (深层特有)
```
实际:     绘制:
┌───┐     ┌───┬───┐
│ A │     │ A │幻觉│
└───┘     └───┴───┘
```

### 3.3 误差检测

| 方式 | 成功率 | 说明 |
|------|--------|------|
| 回访验证 | 100% | 亲自回到该位置 |
| 测绘仪 | 90% | 使用测绘仪测量 |
| 地标对照 | 100% | 特殊地标不会出错 |
| 古地图碎片 | 80% | 对照真实地图 |

---

## 4. 记忆保护机制

### 4.1 不衰退的元素

- **地标** - 特殊地标（入口、Boss房等）永久清晰
- **羽毛笔绘制** - 使用墨水绘制的内容不衰退
- **魔法卷轴** - 100%准确，永久保存
- **重要标记** - 玩家特别标记的位置

### 4.2 记忆强化方式

| 方式 | 效果 | 持续时间 |
|------|------|----------|
| 回访区域 | +20%准确度 | 立即 |
| 记忆强化技能 | 衰退速度-30% | 永久被动 |
| 锚定地标 | 该位置不衰退 | 永久 |
| 魔法物品 | 区域记忆锁定 | 持续一定时间 |

---

## 5. 地图矛盾系统

### 5.1 矛盾检测

当玩家绘制的地图与实际不符时触发：

```typescript
enum MapContradiction {
    WALL_PATH_MISMATCH,  // 画成通道实际有墙
    CONNECTIVITY_ERROR,  // 连通性错误
    DISTANCE_MISMATCH,   // 距离不符
    IMPOSSIBLE_GEOMETRY, // 几何不可能
}
```

### 5.2 矛盾表现

- 地图界面出现视觉扭曲
- 无法信任自己的地图
- 必须找到参考点重新校准

### 5.3 修正方式

| 方式 | 成本 | 限制 |
|------|------|------|
| 铅笔修改 | 橡皮耐久-1 | 仅铅笔绘制可改 |
| 墨水覆盖 | 无法覆盖 | 必须重绘 |
| 贴修正纸 | 纸张-1 | 仅限粗糙纸 |
| 重绘区域 | 时间+体力 | 最彻底 |

---

## 6. 技术实现

### 6.1 数据结构

```gdscript
## 玩家地图数据
class_name PlayerMapData

var layer: int                           # 所属层级
var cells: Dictionary = {}               # key: "x,y", value: DrawnCell
var last_visited: Dictionary = {}        # key: "x,y", value: timestamp
var marks: Array = []                    # 地图标记

## 绘制的单元格
class DrawnCell:
    var x: int
    var y: int
    var drawn_type: int                  # 玩家绘制的类型
    var accuracy: float = 1.0            # 准确度 0-1
    var timestamp: int                   # 绘制时间
    var tool_used: String                # 使用的工具
    var is_permanent: bool = false       # 是否永久（墨水绘制）
```

### 6.2 衰退计算

```gdscript
## 更新记忆衰退
func update_memory_decay(delta: float) -> void:
    var current_time = Time.get_ticks_msec()

    for key in cells:
        var cell = cells[key]

        # 永久记忆不衰退
        if cell.is_permanent:
            continue

        # 计算时间差
        var time_since_visit = (current_time - last_visited.get(key, 0)) / 60000.0

        # 根据层级获取衰退率
        var decay_rate = get_decay_rate_for_layer(layer)
        var decay_period = get_decay_period_for_layer(layer)

        # 计算衰退
        if time_since_visit > 0:
            var decay = (time_since_visit / decay_period) * decay_rate * delta
            cell.accuracy = max(0.05, cell.accuracy - decay)
```

### 6.3 准确度计算

```gdscript
## 计算绘制准确度
func calculate_drawing_accuracy(tool: DrawingTool, conditions: Dictionary) -> float:
    var base_accuracy = tool.accuracy

    # 环境惩罚
    if conditions.get("is_dark", false):
        base_accuracy -= 0.2
    if conditions.get("in_mist", false):
        base_accuracy -= 0.25

    # 状态惩罚
    if conditions.get("is_fatigued", false):
        base_accuracy -= 0.1
    if conditions.get("is_panicked", false):
        base_accuracy -= 0.25

    # 移动惩罚
    if conditions.get("is_moving", false):
        base_accuracy -= 0.15

    return clamp(base_accuracy, 0.1, 1.0)
```

---

*"你的地图就是你的生命线。保护好它，就像保护你的心脏。"*