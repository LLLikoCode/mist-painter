# 迷雾绘者 (Mist Painter) - 玩家成长曲线调整方案

**文档版本**: 1.0  
**创建日期**: 2026-03-29  
**任务ID**: TASK-022  
**状态**: 设计完成

---

## 1. 玩家属性成长系统

### 1.1 属性配置表

创建文件: `assets/data/player_progression_config.json`

```json
{
  "version": "1.0.0",
  "description": "玩家成长配置 - 定义属性成长曲线和能力解锁",
  "attributes": {
    "ink_capacity": {
      "name": "墨水上限",
      "description": "玩家可携带的最大墨水量",
      "initial_value": 50,
      "max_value": 200,
      "growth_curve": "exponential_slow",
      "levels": {
        "tutorial": 50,
        "level_1": 75,
        "level_2": 100,
        "level_3": 130,
        "level_4": 160,
        "level_5": 200
      }
    },
    "ink_regen": {
      "name": "墨水恢复",
      "description": "每房间恢复的墨水量",
      "initial_value": 10,
      "max_value": 25,
      "growth_curve": "linear",
      "levels": {
        "tutorial": 10,
        "level_1": 12,
        "level_2": 15,
        "level_3": 18,
        "level_4": 22,
        "level_5": 25
      }
    },
    "vision_range": {
      "name": "视野范围",
      "description": "玩家可见的格子范围",
      "initial_value": 3,
      "max_value": 6,
      "unit": "tiles",
      "growth_curve": "step",
      "levels": {
        "tutorial": 3,
        "level_1": 4,
        "level_2": 4,
        "level_3": 5,
        "level_4": 5,
        "level_5": 6
      }
    },
    "paint_speed": {
      "name": "绘制速度",
      "description": "迷雾绘制的速度倍率",
      "initial_value": 1.0,
      "max_value": 1.5,
      "growth_curve": "linear_slow",
      "levels": {
        "tutorial": 1.0,
        "level_1": 1.1,
        "level_2": 1.2,
        "level_3": 1.3,
        "level_4": 1.4,
        "level_5": 1.5
      }
    },
    "undo_count": {
      "name": "撤销次数",
      "description": "可撤销的操作次数",
      "initial_value": 1,
      "max_value": 6,
      "growth_curve": "step",
      "levels": {
        "tutorial": 1,
        "level_1": 2,
        "level_2": 3,
        "level_3": 4,
        "level_4": 5,
        "level_5": 6
      }
    },
    "hint_cooldown": {
      "name": "提示冷却",
      "description": "提示系统的冷却时间（秒）",
      "initial_value": 60,
      "max_value": 20,
      "growth_curve": "exponential_fast",
      "levels": {
        "tutorial": 60,
        "level_1": 50,
        "level_2": 40,
        "level_3": 30,
        "level_4": 20,
        "level_5": 20
      }
    }
  },
  "abilities": {
    "basic_paint": {
      "id": "basic_paint",
      "name": "基础画笔",
      "description": "单点绘制迷雾",
      "unlock_level": "tutorial",
      "unlock_condition": "start",
      "icon": "res://assets/ui/abilities/basic_paint.png"
    },
    "line_paint": {
      "id": "line_paint",
      "name": "连线绘制",
      "description": "按住拖动绘制路径",
      "unlock_level": "level_1",
      "unlock_condition": "puzzle_complete",
      "unlock_params": {"puzzle_id": "L1_P1"},
      "icon": "res://assets/ui/abilities/line_paint.png"
    },
    "fill_paint": {
      "id": "fill_paint",
      "name": "区域填充",
      "description": "绘制闭合图形填充区域",
      "unlock_level": "level_1",
      "unlock_condition": "puzzle_complete",
      "unlock_params": {"puzzle_id": "L1_P3"},
      "icon": "res://assets/ui/abilities/fill_paint.png"
    },
    "minimap": {
      "id": "minimap",
      "name": "小地图",
      "description": "显示已探索区域的小地图",
      "unlock_level": "level_1",
      "unlock_condition": "level_complete",
      "icon": "res://assets/ui/abilities/minimap.png"
    },
    "red_brush": {
      "id": "red_brush",
      "name": "红色画笔",
      "description": "绘制红色迷雾，可激活红色符文",
      "unlock_level": "level_2",
      "unlock_condition": "puzzle_complete",
      "unlock_params": {"puzzle_id": "L2_P2"},
      "icon": "res://assets/ui/abilities/red_brush.png"
    },
    "blue_brush": {
      "id": "blue_brush",
      "name": "蓝色画笔",
      "description": "绘制蓝色迷雾，可激活蓝色符文",
      "unlock_level": "level_2",
      "unlock_condition": "puzzle_complete",
      "unlock_params": {"puzzle_id": "L2_P4"},
      "icon": "res://assets/ui/abilities/blue_brush.png"
    },
    "green_brush": {
      "id": "green_brush",
      "name": "绿色画笔",
      "description": "绘制绿色迷雾，可激活绿色符文",
      "unlock_level": "level_2",
      "unlock_condition": "level_complete",
      "icon": "res://assets/ui/abilities/green_brush.png"
    },
    "element_interact": {
      "id": "element_interact",
      "name": "元素互动",
      "description": "火融冰、水导电等互动",
      "unlock_level": "level_2",
      "unlock_condition": "exploration",
      "unlock_params": {"percentage": 80},
      "icon": "res://assets/ui/abilities/element_interact.png"
    },
    "piercing_paint": {
      "id": "piercing_paint",
      "name": "透视画笔",
      "description": "短暂看穿迷雾",
      "unlock_level": "level_3",
      "unlock_condition": "puzzle_complete",
      "unlock_params": {"puzzle_id": "L3_P1"},
      "cooldown": 30,
      "duration": 5,
      "icon": "res://assets/ui/abilities/piercing_paint.png"
    },
    "memory_mark": {
      "id": "memory_mark",
      "name": "记忆标记",
      "description": "在迷雾中做标记",
      "unlock_level": "level_3",
      "unlock_condition": "puzzle_complete",
      "unlock_params": {"puzzle_id": "L3_P3"},
      "icon": "res://assets/ui/abilities/memory_mark.png"
    },
    "rune_identify": {
      "id": "rune_identify",
      "name": "符文识别",
      "description": "自动识别符文类型",
      "unlock_level": "level_3",
      "unlock_condition": "level_complete",
      "icon": "res://assets/ui/abilities/rune_identify.png"
    },
    "copy_paint": {
      "id": "copy_paint",
      "name": "复制画笔",
      "description": "复制已绘制区域",
      "unlock_level": "level_4",
      "unlock_condition": "puzzle_complete",
      "unlock_params": {"puzzle_id": "L4_P2"},
      "ink_cost": 30,
      "icon": "res://assets/ui/abilities/copy_paint.png"
    },
    "time_slow": {
      "id": "time_slow",
      "name": "时间减缓",
      "description": "短暂放慢时间",
      "unlock_level": "level_4",
      "unlock_condition": "puzzle_complete",
      "unlock_params": {"puzzle_id": "L4_P5"},
      "cooldown": 60,
      "duration": 10,
      "slow_factor": 0.5,
      "icon": "res://assets/ui/abilities/time_slow.png"
    },
    "path_predict": {
      "id": "path_predict",
      "name": "路径预测",
      "description": "显示可能路径",
      "unlock_level": "level_4",
      "unlock_condition": "level_complete",
      "icon": "res://assets/ui/abilities/path_predict.png"
    },
    "ultimate_brush": {
      "id": "ultimate_brush",
      "name": "终极画笔",
      "description": "穿透迷雾直接绘制",
      "unlock_level": "level_5",
      "unlock_condition": "puzzle_complete",
      "unlock_params": {"puzzle_id": "L5_P1"},
      "ink_cost": 50,
      "icon": "res://assets/ui/abilities/ultimate_brush.png"
    },
    "global_dispel": {
      "id": "global_dispel",
      "name": "全局驱散",
      "description": "一次性驱散大范围迷雾",
      "unlock_level": "level_5",
      "unlock_condition": "puzzle_complete",
      "unlock_params": {"puzzle_id": "L5_P4"},
      "cooldown": 120,
      "ink_cost": 80,
      "icon": "res://assets/ui/abilities/global_dispel.png"
    },
    "perfect_paint": {
      "id": "perfect_paint",
      "name": "完美绘制",
      "description": "自动优化绘制路径",
      "unlock_level": "level_5",
      "unlock_condition": "level_complete",
      "icon": "res://assets/ui/abilities/perfect_paint.png"
    }
  },
  "ability_slots": {
    "max_active": 4,
    "unlock_progression": ["tutorial", "level_1", "level_3", "level_5"]
  }
}
```

---

## 2. 属性成长曲线

### 2.1 成长曲线可视化

```
墨水上限成长:
教学:  ████░░░░░░░░░░░░░░░░ 50
第1层: ██████░░░░░░░░░░░░░░ 75 (+50%)
第2层: ████████░░░░░░░░░░░░ 100 (+33%)
第3层: ██████████░░░░░░░░░░ 130 (+30%)
第4层: ████████████░░░░░░░░ 160 (+23%)
第5层: ████████████████░░░░ 200 (+25%)

墨水恢复成长:
教学:  ████░░░░░░░░░░░░░░░░ 10
第1层: █████░░░░░░░░░░░░░░░ 12 (+20%)
第2层: ██████░░░░░░░░░░░░░░ 15 (+25%)
第3层: ███████░░░░░░░░░░░░░ 18 (+20%)
第4层: █████████░░░░░░░░░░░ 22 (+22%)
第5层: ██████████░░░░░░░░░░ 25 (+14%)

视野范围成长:
教学:  ██████░░░░░░░░░░░░░░ 3x3 (面积: 9)
第1层: ████████░░░░░░░░░░░░ 4x4 (面积: 16) (+78%)
第2层: ████████░░░░░░░░░░░░ 4x4 (维持)
第3层: ██████████░░░░░░░░░░ 5x5 (面积: 25) (+56%)
第4层: ██████████░░░░░░░░░░ 5x5 (维持)
第5层: ████████████░░░░░░░░ 6x6 (面积: 36) (+44%)

综合战力指数:
教学:  ████░░░░░░░░░░░░░░░░ 1.0
第1层: ██████░░░░░░░░░░░░░░ 1.5 (+50%)
第2层: █████████░░░░░░░░░░░ 2.2 (+47%)
第3层: ███████████░░░░░░░░░ 3.0 (+36%)
第4层: ██████████████░░░░░░ 4.0 (+33%)
第5层: █████████████████░░░ 5.0 (+25%)
Boss:  ███████████████████░ 5.5 (+10%)

战力增长采用递减率，避免后期数值膨胀
```

### 2.2 成长曲线公式

```gdscript
# src/utils/ProgressionCalculator.gd
class_name ProgressionCalculator

# 属性成长计算
static func calculate_attribute(level: String, attribute_name: String) -> float:
    var config = load("res://assets/data/player_progression_config.json")
    var attr = config.attributes[attribute_name]
    
    var initial = attr.initial_value
    var max_val = attr.max_value
    var current = attr.levels[level]
    
    return current

# 计算成长倍率
static func get_growth_multiplier(current: float, initial: float) -> float:
    return current / initial

# 计算与关卡难度的平衡系数
static func calculate_balance_coefficient(player_level: String, level_difficulty: float) -> float:
    var player_power = get_player_power(player_level)
    return player_power / level_difficulty

static func get_player_power(level: String) -> float:
    var config = load("res://assets/data/player_progression_config.json")
    var ink = config.attributes.ink_capacity.levels[level]
    var vision = config.attributes.vision_range.levels[level]
    var speed = config.attributes.paint_speed.levels[level]
    var undo = config.attributes.undo_count.levels[level]
    
    # 综合战力公式
    return (ink / 50.0) * (vision / 3.0) * speed * (undo / 1.0)
```

### 2.3 平衡系数目标

| 关卡 | 玩家战力 | 关卡难度 | 目标平衡系数 | 体验描述 |
|------|----------|----------|--------------|----------|
| 教学 | 1.0 | 0.5 | 2.0 | 轻松学习 |
| 第1层 | 1.5 | 0.7 | 2.1 | 建立信心 |
| 第2层 | 2.2 | 1.0 | 2.2 | 舒适挑战 |
| 第3层 | 3.0 | 1.3 | 2.3 | 需要思考 |
| 第4层 | 4.0 | 1.6 | 2.5 | 紧张刺激 |
| 第5层 | 5.0 | 2.0 | 2.5 | 极限挑战 |
| Boss战 | 5.5 | 2.2 | 2.5 | 综合考验 |

---

## 3. 能力解锁系统

### 3.1 解锁条件类型

```gdscript
# src/player/AbilityUnlockManager.gd
class_name AbilityUnlockManager
extends Node

var unlocked_abilities: Array[String] = []
var ability_slots: int = 1

signal ability_unlocked(ability_id: String)
signal ability_slot_increased(new_count: int)

func check_unlock_conditions(event_type: String, event_data: Dictionary) -> void:
    var config = load("res://assets/data/player_progression_config.json")
    
    for ability_id in config.abilities.keys():
        if ability_id in unlocked_abilities:
            continue
        
        var ability = config.abilities[ability_id]
        var condition = ability.unlock_condition
        
        var should_unlock = false
        
        match condition:
            "start":
                should_unlock = true
            "level_complete":
                should_unlock = (event_type == "level_complete" and 
                               event_data.get("level") == ability.unlock_level)
            "puzzle_complete":
                should_unlock = (event_type == "puzzle_complete" and 
                               event_data.get("puzzle_id") == ability.unlock_params.puzzle_id)
            "exploration":
                should_unlock = (event_type == "exploration" and 
                               event_data.get("percentage", 0) >= ability.unlock_params.percentage)
            "achievement":
                should_unlock = (event_type == "achievement_unlocked" and 
                               event_data.get("achievement_id") == ability.unlock_params.achievement_id)
        
        if should_unlock:
            unlock_ability(ability_id)

func unlock_ability(ability_id: String) -> void:
    if ability_id in unlocked_abilities:
        return
    
    unlocked_abilities.append(ability_id)
    ability_unlocked.emit(ability_id)
    
    # 显示解锁通知
    show_unlock_notification(ability_id)

func show_unlock_notification(ability_id: String) -> void:
    var config = load("res://assets/data/player_progression_config.json")
    var ability = config.abilities[ability_id]
    
    # 触发UI显示
    AutoLoad.event_bus.emit(EventBus.EventType.ABILITY_UNLOCKED, {
        "ability_id": ability_id,
        "name": ability.name,
        "description": ability.description,
        "icon": ability.icon
    })

func increase_ability_slots() -> void:
    ability_slots += 1
    ability_slot_increased.emit(ability_slots)

func is_ability_unlocked(ability_id: String) -> bool:
    return ability_id in unlocked_abilities

func get_unlocked_abilities() -> Array[String]:
    return unlocked_abilities.duplicate()
```

### 3.2 能力解锁时间表

```
能力解锁路线图:

教学关卡:
  [基础画笔]────────────────────────────────────────

第1层:
  [基础画笔][连线绘制][区域填充][小地图]──────────────

第2层:
  [基础画笔][连线绘制][区域填充][小地图]
  [红色画笔][蓝色画笔][绿色画笔][元素互动]────────────

第3层:
  [基础画笔][连线绘制][区域填充][小地图]
  [红色画笔][蓝色画笔][绿色画笔][元素互动]
  [透视画笔][记忆标记][符文识别]─────────────────────

第4层:
  [基础画笔][连线绘制][区域填充][小地图]
  [红色画笔][蓝色画笔][绿色画笔][元素互动]
  [透视画笔][记忆标记][符文识别]
  [复制画笔][时间减缓][路径预测]─────────────────────

第5层:
  [基础画笔][连线绘制][区域填充][小地图]
  [红色画笔][蓝色画笔][绿色画笔][元素互动]
  [透视画笔][记忆标记][符文识别]
  [复制画笔][时间减缓][路径预测]
  [终极画笔][全局驱散][完美绘制]─────────────────────

Boss战:
  [所有能力可用]────────────────────────────────────

解锁节奏: 每层解锁3-4个新能力，保持新鲜感
```

### 3.3 能力槽位系统

```gdscript
# 能力槽位管理
const MAX_ABILITY_SLOTS = 4

var active_abilities: Array[String] = []
var available_slots: int = 1

func unlock_slot(level_id: String) -> void:
    var config = load("res://assets/data/player_progression_config.json")
    var slot_progression = config.ability_slots.unlock_progression
    
    var slot_index = slot_progression.find(level_id)
    if slot_index >= 0:
        available_slots = slot_index + 1
        ability_slot_increased.emit(available_slots)

func equip_ability(ability_id: String) -> bool:
    if active_abilities.size() >= available_slots:
        return false
    
    if ability_id not in unlocked_abilities:
        return false
    
    if ability_id in active_abilities:
        return false
    
    active_abilities.append(ability_id)
    return true

func unequip_ability(ability_id: String) -> bool:
    if ability_id not in active_abilities:
        return false
    
    active_abilities.erase(ability_id)
    return true

func switch_ability(old_id: String, new_id: String) -> bool:
    if old_id not in active_abilities:
        return false
    
    if new_id not in unlocked_abilities:
        return false
    
    var index = active_abilities.find(old_id)
    active_abilities[index] = new_id
    return true
```

---

## 4. 道具获取节奏

### 4.1 道具配置

```json
{
  "items": {
    "ink_orb_small": {
      "id": "ink_orb_small",
      "name": "小型墨珠",
      "type": "consumable",
      "effect": {"ink_restore": 20},
      "rarity": "common",
      "spawn_rate": {"tutorial": 0.3, "level_1": 0.25, "level_2": 0.2, "level_3": 0.15, "level_4": 0.1, "level_5": 0.08}
    },
    "ink_orb_medium": {
      "id": "ink_orb_medium",
      "name": "中型墨珠",
      "type": "consumable",
      "effect": {"ink_restore": 50},
      "rarity": "uncommon",
      "spawn_rate": {"tutorial": 0.1, "level_1": 0.15, "level_2": 0.2, "level_3": 0.2, "level_4": 0.15, "level_5": 0.12}
    },
    "ink_orb_large": {
      "id": "ink_orb_large",
      "name": "大型墨珠",
      "type": "consumable",
      "effect": {"ink_restore": 100},
      "rarity": "rare",
      "spawn_rate": {"tutorial": 0, "level_1": 0.05, "level_2": 0.08, "level_3": 0.1, "level_4": 0.12, "level_5": 0.15}
    },
    "vision_scroll": {
      "id": "vision_scroll",
      "name": "视野卷轴",
      "type": "consumable",
      "effect": {"vision_boost": 2, "duration": 30},
      "rarity": "uncommon",
      "spawn_rate": {"tutorial": 0, "level_1": 0.08, "level_2": 0.1, "level_3": 0.12, "level_4": 0.1, "level_5": 0.08}
    },
    "hint_crystal": {
      "id": "hint_crystal",
      "name": "提示水晶",
      "type": "consumable",
      "effect": {"instant_hint": true},
      "rarity": "rare",
      "spawn_rate": {"tutorial": 0.05, "level_1": 0.05, "level_2": 0.06, "level_3": 0.06, "level_4": 0.05, "level_5": 0.04}
    },
    "speed_potion": {
      "id": "speed_potion",
      "name": "速度药水",
      "type": "consumable",
      "effect": {"speed_boost": 1.5, "duration": 60},
      "rarity": "uncommon",
      "spawn_rate": {"tutorial": 0, "level_1": 0.05, "level_2": 0.08, "level_3": 0.08, "level_4": 0.06, "level_5": 0.05}
    }
  }
}
```

### 4.2 道具获取节奏

| 关卡 | 道具总数 | 必需道具 | 可选道具 | 稀有道具 | 获取频率 |
|------|----------|----------|----------|----------|----------|
| 教学 | 3 | 2 | 1 | 0 | 每房间0.75个 |
| 第1层 | 6 | 3 | 3 | 0-1 | 每房间0.75个 |
| 第2层 | 8 | 4 | 4 | 1 | 每房间0.8个 |
| 第3层 | 10 | 5 | 5 | 1-2 | 每房间0.83个 |
| 第4层 | 12 | 6 | 6 | 2 | 每房间0.86个 |
| 第5层 | 14 | 7 | 7 | 2-3 | 每房间0.88个 |

### 4.3 道具生成算法

```gdscript
# src/gameplay/ItemSpawnManager.gd
class_name ItemSpawnManager

static func spawn_items_for_room(room_id: String, level_id: String, intensity: float) -> Array:
    var config = load("res://assets/data/item_config.json")
    var items = []
    
    # 根据强度调整道具数量
    var base_count = 1
    if intensity < 0.4:
        base_count = 2  # 休息点更多道具
    elif intensity > 0.8:
        base_count = 0  # 高强度区域减少道具
    
    for i in range(base_count):
        var item = roll_item(config.items, level_id)
        if item:
            items.append(item)
    
    return items

static func roll_item(item_pool: Dictionary, level_id: String) -> Dictionary:
    var available_items = []
    var total_weight = 0.0
    
    for item_id in item_pool.keys():
        var item = item_pool[item_id]
        var spawn_rate = item.spawn_rate.get(level_id, 0)
        
        if spawn_rate > 0:
            available_items.append({"item": item, "weight": spawn_rate})
            total_weight += spawn_rate
    
    if available_items.is_empty():
        return {}
    
    # 加权随机
    var roll = randf() * total_weight
    var current_weight = 0.0
    
    for entry in available_items:
        current_weight += entry.weight
        if roll <= current_weight:
            return entry.item
    
    return available_items[-1].item
```

---

## 5. 成长感知设计

### 5.1 成长里程碑

| 里程碑 | 触发条件 | 奖励 | UI效果 |
|--------|----------|------|--------|
| 初出茅庐 | 完成教学 | 解锁第1层 | 闪光特效+音效 |
| 迷雾行者 | 完成第1层 | 小地图+连线绘制 | 能力解锁动画 |
| 符文学徒 | 完成第2层 | 颜色画笔 | 画笔变色特效 |
| 深渊探索者 | 完成第3层 | 透视能力 | 屏幕特效 |
| 镜像大师 | 完成第4层 | 复制+时间减缓 | 时间扭曲特效 |
| 时空绘者 | 完成第5层 | 终极画笔 | 全屏特效 |
| 迷雾之主 | 击败Boss | 无尽模式解锁 | 通关动画 |

### 5.2 成长可视化

```gdscript
# 属性变化时的视觉反馈
func on_attribute_changed(attribute: String, old_value: float, new_value: float) -> void:
    var change = new_value - old_value
    var percentage = (new_value / old_value - 1.0) * 100.0
    
    # 显示属性变化UI
    var notification = {
        "attribute": attribute,
        "old_value": old_value,
        "new_value": new_value,
        "change": change,
        "percentage": percentage
    }
    
    AutoLoad.event_bus.emit(EventBus.EventType.ATTRIBUTE_CHANGED, notification)
    
    # 播放特效
    if percentage >= 20:
        play_major_upgrade_effect()
    elif percentage >= 10:
        play_minor_upgrade_effect()
```

---

## 6. 实施计划

### 6.1 第一阶段：属性系统（1周）

- [ ] 创建 `player_progression_config.json`
- [ ] 更新 PlayerController 支持属性
- [ ] 实现 ProgressionCalculator
- [ ] 添加属性成长UI

### 6.2 第二阶段：能力系统（1周）

- [ ] 实现 AbilityUnlockManager
- [ ] 创建能力图标资源
- [ ] 实现能力槽位系统
- [ ] 添加能力切换UI

### 6.3 第三阶段：道具系统（1周）

- [ ] 创建 `item_config.json`
- [ ] 实现 ItemSpawnManager
- [ ] 添加道具收集逻辑
- [ ] 实现道具使用效果

### 6.4 第四阶段：反馈优化（1周）

- [ ] 添加成长里程碑
- [ ] 实现属性变化特效
- [ ] 添加解锁动画
- [ ] 优化成长感知

---

## 7. 预期效果

### 7.1 成长曲线目标

```
预期玩家感知:

教学 → 第1层: "我学会了新技能！" (+50%能力提升)
第1层 → 第2层: "我能处理更复杂的谜题了" (+47%能力提升)
第2层 → 第3层: "我开始理解游戏机制了" (+36%能力提升)
第3层 → 第4层: "挑战变得有趣了" (+33%能力提升)
第4层 → 第5层: "我准备好面对最终挑战了" (+25%能力提升)

成长感知保持正向，每关都有明显进步感
```

### 7.2 留存目标

| 指标 | 目标值 | 验证方法 |
|------|--------|----------|
| 第1层完成率 | >85% | 关卡完成统计 |
| 第3层完成率 | >60% | 关卡完成统计 |
| 通关率 | >30% | 通关统计 |
| 能力使用频率 | >70% | 行为追踪 |
| 成长满意度 | >4.0/5.0 | 问卷调查 |

---

*方案完成 - 调月莉音*
