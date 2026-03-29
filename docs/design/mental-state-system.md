# 心理状态系统

> **系统:** Mental State System
> **重要性:** ⭐⭐⭐ 进阶机制
> **设计理念:** 恐惧是最好的调味剂

---

## 1. 系统概述

### 1.1 核心概念

玩家的心理状态会影响游戏体验。压力积累会导致各种负面效果，甚至产生幻觉。

### 1.2 压力值机制

```gdscript
## 心理状态
class_name MentalState

var stress_level: float = 0.0           # 压力值 0-100
var hallucination_chance: float = 0.0   # 幻觉概率
var accuracy_penalty: float = 0.0       # 精度惩罚
```

---

## 2. 压力来源

### 2.1 环境压力

| 情况 | 压力增加 | 说明 |
|------|----------|------|
| 在黑暗中每5分钟 | +5 | 未知带来恐惧 |
| 迷路时每分钟 | +10 | 恐慌累积 |
| 发现尸体/遗迹 | +15 | 心理冲击 |
| 被追逐时 | +20 | 生存压力 |
| 地图出现矛盾 | +8 | 认知失调 |

### 2.2 状态压力

| 情况 | 压力增加 | 说明 |
|------|----------|------|
| 体力低于20% | +10 | 生理影响心理 |
| HP低于30% | +15 | 濒死恐惧 |
| 墨水耗尽 | +5 | 无助感 |
| 光源即将耗尽 | +8 | 黑暗恐惧 |

### 2.3 深层压力

| 层级 | 基础压力/分钟 | 说明 |
|------|---------------|------|
| 表层遗迹 | 0 | 无环境压力 |
| 古代回廊 | +1 | 轻微压迫感 |
| 迷失深渊 | +2 | 明显压迫感 |
| 混沌核心 | +5 | 极度压迫感 |

---

## 3. 压力影响

### 3.1 压力等级

| 压力范围 | 状态 | 效果 |
|----------|------|------|
| 0-30 | 冷静 | 无惩罚，可能+5%精度 |
| 30-50 | 紧张 | 绘图误差+10% |
| 50-70 | 焦虑 | 误差+20%，手抖动画 |
| 70-85 | 恐慌 | 误差+35%，开始出现幻觉 |
| 85-100 | 崩溃 | 误差+50%，频繁幻觉，视野闪烁 |

### 3.2 视觉效果

| 状态 | 视觉表现 |
|------|----------|
| 紧张 | 轻微视野抖动 |
| 焦虑 | 明显手抖，绘制线条不稳 |
| 恐慌 | 边缘幻觉，视野轻微扭曲 |
| 崩溃 | 频繁幻觉，屏幕闪烁，颜色失真 |

---

## 4. 幻觉系统

### 4.1 幻觉类型

#### 虚假通道
- 在墙上显示不存在的门
- 玩家尝试通过会撞墙
- 发现后压力+5

#### 错误标记
- 已探索区域显示为未探索
- 迷惑玩家方向感
- 加剧迷路焦虑

#### 幽灵敌人
- 看到不存在的怪物
- 无法交互但会追踪
- 消失时压力+10

#### 地图扭曲
- 已绘制的线条轻微偏移
- 影响地图准确性
- 需要重新验证

#### 声音幻听
- 听到脚步声、低语
- 增加紧张氛围
- 无实际威胁

### 4.2 幻觉概率

```gdscript
## 计算幻觉概率
func calculate_hallucination_chance() -> float:
    var base_chance = 0.0

    if stress_level >= 70:
        base_chance = (stress_level - 70) / 30.0 * 0.5

    # 深层加成
    if current_layer >= 3:
        base_chance += 0.1

    # 夜间加成
    if is_night_time():
        base_chance += 0.15

    return min(base_chance, 0.8)
```

### 4.3 幻觉检测

| 方式 | 成功率 | 说明 |
|------|--------|------|
| 测绘仪验证 | 90% | 可验证地图幻觉 |
| 等待观察 | 70% | 幻觉会在一段时间后消失 |
| 高压力消退 | 100% | 压力降低后自动发现 |
| 队友确认 | 100% | 多人模式下队友可确认 |

---

## 5. 压力恢复

### 5.1 恢复方式

| 方式 | 恢复量 | 条件 |
|------|--------|------|
| 安全区域休息 | -15/分钟 | 无威胁 |
| 完成准确绘图 | -20 | 准确度>90% |
| 镇定药水 | -30 | 消耗品 |
| 发现出口 | -40 | 希望恢复 |
| 到达新层 | -25 | 成就感 |

### 5.2 恢复物品

| 物品 | 效果 | 价格 | 稀有度 |
|------|------|------|--------|
| 草药茶 | 压力-20 | 30 | 常见 |
| 镇定剂 | 压力-40 | 80 | 普通 |
| 冥想卷轴 | 压力清零 | 200 | 稀有 |

---

## 6. 职业影响

### 6.1 职业压力抗性

| 职业 | 压力抗性 | 特殊能力 |
|------|----------|----------|
| 测绘师 | 标准 | 绘图成功额外减压 |
| 探险家 | +20% | 迷路压力减半 |
| 考古学家 | +10% | 发现遗迹减压 |
| 生存专家 | +30% | 所有压力来源减少 |
| 信使 | -10% | 脆弱但合作加成 |

### 6.2 技能树影响

```
洞察系:
└─ 心灵坚韧 (压力上限+20)
    └─ 冷静分析 (压力恢复+50%)
        └─ 恐惧免疫 (幻觉概率-50%)
```

---

## 7. 技术实现

### 7.1 数据结构

```gdscript
class_name MentalStateSystem
extends Node

# 压力值
var stress_level: float = 0.0
var max_stress: float = 100.0

# 幻觉
var active_hallucinations: Array = []
var hallucination_cooldown: float = 0.0

# 信号
signal stress_changed(level: float)
signal stress_threshold_crossed(threshold: String)
signal hallucination_triggered(type: String)
signal mental_breakdown
```

### 7.2 压力更新

```gdscript
func update_stress(delta: float) -> void:
    # 环境压力
    if is_in_darkness():
        stress_level += 5.0 * delta / 300.0  # 每5分钟+5

    # 深层压力
    var layer_stress = get_layer_stress_rate()
    stress_level += layer_stress * delta / 60.0

    # 恢复
    if is_in_safe_zone():
        stress_level -= 15.0 * delta / 60.0

    stress_level = clamp(stress_level, 0, max_stress)
    stress_changed.emit(stress_level)

    # 检查阈值
    check_stress_thresholds()
```

### 7.3 幻觉生成

```gdscript
func try_spawn_hallucination() -> void:
    if hallucination_cooldown > 0:
        return

    var chance = calculate_hallucination_chance()
    if randf() < chance:
        var type = pick_hallucination_type()
        spawn_hallucination(type)
        hallucination_cooldown = 30.0  # 30秒冷却
        hallucination_triggered.emit(type)
```

---

*"恐惧是迷宫的武器，但你的意志是盾牌。"*