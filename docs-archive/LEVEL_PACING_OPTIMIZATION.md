# 迷雾绘者 (Mist Painter) - 关卡节奏优化方案

**文档版本**: 1.0  
**创建日期**: 2026-03-29  
**任务ID**: TASK-022  
**状态**: 设计完成

---

## 1. 关卡结构设计

### 1.1 关卡元数据配置

创建文件: `assets/data/level_structure_config.json`

```json
{
  "version": "1.0.0",
  "description": "关卡结构配置 - 定义各关卡的房间数量、检查点分布、完成条件",
  "levels": {
    "tutorial": {
      "level_id": "tutorial",
      "level_name": "教学关卡",
      "level_index": 0,
      "structure": {
        "total_rooms": 4,
        "room_layout": "linear",
        "start_room": "tutorial_start",
        "end_room": "tutorial_end"
      },
      "checkpoints": {
        "interval": 2,
        "positions": ["room_2", "tutorial_end"],
        "auto_save": true
      },
      "completion_criteria": {
        "required_puzzles": 3,
        "required_exploration": 50,
        "time_limit": 0
      },
      "pacing": {
        "target_duration": 600,
        "intensity_curve": [0.3, 0.4, 0.5, 0.3],
        "rest_points": ["room_2"]
      }
    },
    "level_1": {
      "level_id": "level_1",
      "level_name": "第1层 - 初探迷雾",
      "level_index": 1,
      "structure": {
        "total_rooms": 8,
        "room_layout": "branching",
        "start_room": "l1_start",
        "end_room": "l1_boss_gate",
        "branching_factor": 1.5
      },
      "checkpoints": {
        "interval": 3,
        "positions": ["room_3", "room_6", "l1_boss_gate"],
        "auto_save": true
      },
      "completion_criteria": {
        "required_puzzles": 5,
        "required_exploration": 60,
        "optional_puzzles": 2,
        "time_limit": 0
      },
      "pacing": {
        "target_duration": 720,
        "intensity_curve": [0.3, 0.4, 0.5, 0.6, 0.5, 0.4, 0.3],
        "rest_points": ["room_3", "room_6"]
      }
    },
    "level_2": {
      "level_id": "level_2",
      "level_name": "第2层 - 符文觉醒",
      "level_index": 2,
      "structure": {
        "total_rooms": 10,
        "room_layout": "hub_spoke",
        "start_room": "l2_start",
        "end_room": "l2_boss_gate",
        "hub_room": "l2_central"
      },
      "checkpoints": {
        "interval": 3,
        "positions": ["l2_central", "room_7", "l2_boss_gate"],
        "auto_save": true
      },
      "completion_criteria": {
        "required_puzzles": 6,
        "required_exploration": 65,
        "optional_puzzles": 3,
        "time_limit": 0
      },
      "pacing": {
        "target_duration": 900,
        "intensity_curve": [0.4, 0.5, 0.6, 0.5, 0.7, 0.6, 0.5, 0.4],
        "rest_points": ["l2_central", "room_7"]
      }
    },
    "level_3": {
      "level_id": "level_3",
      "level_name": "第3层 - 迷雾深渊",
      "level_index": 3,
      "structure": {
        "total_rooms": 12,
        "room_layout": "maze",
        "start_room": "l3_start",
        "end_room": "l3_boss_gate",
        "loopback_paths": 2
      },
      "checkpoints": {
        "interval": 4,
        "positions": ["room_4", "room_8", "l3_boss_gate"],
        "auto_save": true
      },
      "completion_criteria": {
        "required_puzzles": 7,
        "required_exploration": 70,
        "optional_puzzles": 4,
        "time_limit": 0
      },
      "pacing": {
        "target_duration": 1200,
        "intensity_curve": [0.5, 0.6, 0.7, 0.6, 0.8, 0.7, 0.6, 0.8, 0.7, 0.5],
        "rest_points": ["room_4", "room_8"]
      }
    },
    "level_4": {
      "level_id": "level_4",
      "level_name": "第4层 - 镜像迷宫",
      "level_index": 4,
      "structure": {
        "total_rooms": 14,
        "room_layout": "symmetric",
        "start_room": "l4_start",
        "end_room": "l4_boss_gate",
        "mirror_axis": "vertical"
      },
      "checkpoints": {
        "interval": 4,
        "positions": ["room_4", "room_9", "l4_boss_gate"],
        "auto_save": true
      },
      "completion_criteria": {
        "required_puzzles": 8,
        "required_exploration": 75,
        "optional_puzzles": 4,
        "time_limit": 0
      },
      "pacing": {
        "target_duration": 1500,
        "intensity_curve": [0.6, 0.7, 0.8, 0.7, 0.9, 0.8, 0.7, 0.9, 0.8, 0.7, 0.6],
        "rest_points": ["room_4", "room_9"]
      }
    },
    "level_5": {
      "level_id": "level_5",
      "level_name": "第5层 - 时空绘卷",
      "level_index": 5,
      "structure": {
        "total_rooms": 16,
        "room_layout": "layered",
        "start_room": "l5_start",
        "end_room": "l5_boss_gate",
        "layers": 3
      },
      "checkpoints": {
        "interval": 5,
        "positions": ["layer_1_end", "layer_2_end", "l5_boss_gate"],
        "auto_save": true
      },
      "completion_criteria": {
        "required_puzzles": 8,
        "required_exploration": 80,
        "optional_puzzles": 5,
        "time_limit": 0
      },
      "pacing": {
        "target_duration": 1800,
        "intensity_curve": [0.7, 0.8, 0.9, 0.8, 0.9, 1.0, 0.9, 1.0, 0.9, 0.8, 0.9, 0.7],
        "rest_points": ["layer_1_end", "layer_2_end"]
      }
    },
    "boss": {
      "level_id": "boss",
      "level_name": "Boss战 - 迷雾之主",
      "level_index": 6,
      "structure": {
        "total_rooms": 5,
        "room_layout": "arena",
        "start_room": "boss_arena",
        "end_room": "victory_room"
      },
      "checkpoints": {
        "interval": 2,
        "positions": ["phase_2", "phase_3"],
        "auto_save": true,
        "boss_phases": 3
      },
      "completion_criteria": {
        "required_puzzles": 5,
        "required_exploration": 0,
        "time_limit": 0
      },
      "pacing": {
        "target_duration": 2400,
        "intensity_curve": [0.8, 0.9, 1.0, 0.9, 0.8],
        "rest_points": [],
        "phase_transitions": ["phase_1", "phase_2", "phase_3"]
      }
    }
  }
}
```

### 1.2 关卡长度分布

```
关卡长度对比:

教学关卡:  ████░░░░░░░░░░░░░░░░ 4房间  (约10分钟)
第1层:     ████████░░░░░░░░░░░░ 8房间  (约12分钟)
第2层:     ██████████░░░░░░░░░░ 10房间 (约15分钟)
第3层:     ████████████░░░░░░░░ 12房间 (约20分钟)
第4层:     ██████████████░░░░░░ 14房间 (约25分钟)
第5层:     ████████████████░░░░ 16房间 (约30分钟)
Boss战:    █████░░░░░░░░░░░░░░░ 5房间  (约40分钟，高强度)

房间数增长率: 第1-2层 +25%, 第2-3层 +20%, 第3-4层 +17%, 第4-5层 +14%
采用递减增长率，避免后期关卡过于冗长
```

---

## 2. 检查点系统设计

### 2.1 检查点配置

```gdscript
# src/gameplay/CheckpointSystem.gd
class_name CheckpointSystem
extends Node

# 检查点数据
var checkpoints: Dictionary = {}
var current_checkpoint: String = ""
var level_config: Dictionary = {}

# 信号
signal checkpoint_reached(checkpoint_id: String)
signal checkpoint_loaded(checkpoint_data: Dictionary)

func initialize(level_id: String) -> void:
    var config = load("res://assets/data/level_structure_config.json")
    level_config = config.levels[level_id]
    
    # 初始化检查点
    for checkpoint_id in level_config.checkpoints.positions:
        checkpoints[checkpoint_id] = {
            "id": checkpoint_id,
            "reached": false,
            "timestamp": 0,
            "player_state": {},
            "level_state": {}
        }

func reach_checkpoint(checkpoint_id: String, player: Node, level_state: Dictionary) -> void:
    if not checkpoints.has(checkpoint_id):
        return
    
    var checkpoint = checkpoints[checkpoint_id]
    checkpoint.reached = true
    checkpoint.timestamp = Time.get_unix_time_from_system()
    checkpoint.player_state = capture_player_state(player)
    checkpoint.level_state = level_state.duplicate()
    
    current_checkpoint = checkpoint_id
    checkpoint_reached.emit(checkpoint_id)
    
    # 自动保存
    if level_config.checkpoints.auto_save:
        AutoLoad.save_manager.create_checkpoint_save(checkpoint_id, checkpoint)

func capture_player_state(player: Node) -> Dictionary:
    return {
        "position": {"x": player.global_position.x, "y": player.global_position.y},
        "ink": player.ink if player.has_method("get_ink") else 0,
        "unlocked_abilities": player.unlocked_abilities if player.has_method("get_unlocked_abilities") else [],
        "facing_direction": player.facing_direction if player.has("facing_direction") else "down"
    }

func load_checkpoint(checkpoint_id: String) -> Dictionary:
    if not checkpoints.has(checkpoint_id):
        return {}
    
    var checkpoint = checkpoints[checkpoint_id]
    if not checkpoint.reached:
        return {}
    
    checkpoint_loaded.emit(checkpoint)
    return checkpoint

func get_last_reached_checkpoint() -> String:
    var last_checkpoint = ""
    var last_time = 0
    
    for checkpoint_id in checkpoints.keys():
        var checkpoint = checkpoints[checkpoint_id]
        if checkpoint.reached and checkpoint.timestamp > last_time:
            last_time = checkpoint.timestamp
            last_checkpoint = checkpoint_id
    
    return last_checkpoint

func get_checkpoint_interval() -> int:
    return level_config.checkpoints.interval
```

### 2.2 检查点分布表

| 关卡 | 房间数 | 检查点间隔 | 检查点数量 | 覆盖度 |
|------|--------|------------|------------|--------|
| 教学 | 4 | 每2房间 | 2 | 50% |
| 第1层 | 8 | 每3房间 | 3 | 38% |
| 第2层 | 10 | 每3房间 | 3 | 30% |
| 第3层 | 12 | 每4房间 | 3 | 25% |
| 第4层 | 14 | 每4房间 | 3 | 21% |
| 第5层 | 16 | 每5房间 | 3 | 19% |
| Boss | 5 | 每2房间 | 3 | 60% |

**设计原则**:
- 简单关卡：检查点密集，降低挫败感
- 困难关卡：检查点稀疏，增加挑战
- Boss战：检查点密集，允许多次尝试

### 2.3 死亡恢复机制

```gdscript
# src/gameplay/DeathRecovery.gd
class_name DeathRecovery
extends Node

enum RecoveryType {
    CHECKPOINT,     # 恢复到检查点
    ROOM_START,     # 当前房间开始
    LEVEL_START     # 本层开始
}

const RECOVERY_PENALTIES = {
    "easy": {"ink_loss": 0, "reset_items": false},
    "normal": {"ink_loss": 0.10, "reset_items": false},
    "hard": {"ink_loss": 0.25, "reset_items": true},
    "extreme": {"ink_loss": 0.50, "reset_items": true}
}

static func handle_death(player: Node, level_controller: Node) -> Dictionary:
    var difficulty = AutoLoad.config_manager.get_setting("game_difficulty", 1)
    var difficulty_key = ["easy", "normal", "hard", "extreme"][difficulty]
    var penalty = RECOVERY_PENALTIES[difficulty_key]
    
    # 获取最后检查点
    var checkpoint_system = level_controller.checkpoint_system
    var last_checkpoint = checkpoint_system.get_last_reached_checkpoint()
    
    var recovery_options = []
    
    if last_checkpoint != "":
        recovery_options.append({
            "type": RecoveryType.CHECKPOINT,
            "label": "从检查点继续",
            "checkpoint_id": last_checkpoint,
            "penalty": penalty
        })
    
    recovery_options.append({
        "type": RecoveryType.ROOM_START,
        "label": "当前房间重新开始",
        "penalty": {"ink_loss": penalty.ink_loss * 1.5, "reset_items": penalty.reset_items}
    })
    
    recovery_options.append({
        "type": RecoveryType.LEVEL_START,
        "label": "本层重新开始",
        "penalty": {"ink_loss": 0, "reset_items": true}
    })
    
    return {
        "options": recovery_options,
        "recommended": 0 if recovery_options.size() > 0 else 1
    }

static func apply_recovery(player: Node, recovery_data: Dictionary) -> void:
    var penalty = recovery_data.penalty
    
    # 扣除墨水
    if penalty.ink_loss > 0 and player.has_method("consume_ink"):
        var current_ink = player.ink if player.has("ink") else 100
        var loss_amount = int(current_ink * penalty.ink_loss)
        player.consume_ink(loss_amount)
    
    # 重置道具
    if penalty.reset_items and player.has_method("reset_collected_items"):
        player.reset_collected_items()
```

---

## 3. 节奏控制机制

### 3.1 强度曲线实现

```gdscript
# src/gameplay/PacingController.gd
class_name PacingController
extends Node

var level_config: Dictionary = {}
var current_room_index: int = 0
var room_intensities: Array = []

signal intensity_changed(new_intensity: float)
signal rest_point_reached(room_id: String)
signal climax_approaching()

func initialize(level_id: String) -> void:
    var config = load("res://assets/data/level_structure_config.json")
    level_config = config.levels[level_id]
    room_intensities = level_config.pacing.intensity_curve

func enter_room(room_index: int, room_id: String) -> void:
    current_room_index = room_index
    
    var intensity = 0.5
    if room_index < room_intensities.size():
        intensity = room_intensities[room_index]
    
    intensity_changed.emit(intensity)
    
    # 检查是否是休息点
    if room_id in level_config.pacing.rest_points:
        rest_point_reached.emit(room_id)
    
    # 检查是否接近高潮
    var total_rooms = level_config.structure.total_rooms
    if room_index >= total_rooms - 2:
        climax_approaching.emit()

func get_current_intensity() -> float:
    if current_room_index < room_intensities.size():
        return room_intensities[current_room_index]
    return 0.5

func get_progress_percentage() -> float:
    var total = level_config.structure.total_rooms
    return float(current_room_index) / float(total) * 100.0
```

### 3.2 节奏调整参数

| 强度等级 | 迷雾密度 | 谜题密度 | 资源稀缺度 | 音乐强度 |
|----------|----------|----------|------------|----------|
| 0.3 (低) | 30% | 1谜题/3房间 | 丰富 | 舒缓 |
| 0.5 (中) | 50% | 1谜题/2房间 | 正常 | 平静 |
| 0.7 (高) | 70% | 1谜题/房间 | 紧张 | 紧张 |
| 0.9 (极高) | 85% | 2谜题/房间 | 稀缺 | 激烈 |
| 1.0 (峰值) | 90% | Boss谜题 | 极限 | 高潮 |

### 3.3 动态节奏调整

```gdscript
# 根据玩家表现调整节奏
func adjust_pacing_based_on_performance(metrics: Dictionary) -> void:
    var avg_puzzle_time = metrics.get("avg_puzzle_time", 60.0)
    var death_count = metrics.get("death_count", 0)
    var target_time = level_config.pacing.target_duration
    
    var time_ratio = avg_puzzle_time / (target_time / level_config.structure.total_rooms)
    
    # 如果玩家进展太快，增加强度
    if time_ratio < 0.7 and death_count < 2:
        increase_intensity(0.1)
    
    # 如果玩家进展太慢，降低强度
    if time_ratio > 1.5 or death_count > 5:
        decrease_intensity(0.1)

func increase_intensity(amount: float) -> void:
    for i in range(room_intensities.size()):
        room_intensities[i] = min(1.0, room_intensities[i] + amount)

func decrease_intensity(amount: float) -> void:
    for i in range(room_intensities.size()):
        room_intensities[i] = max(0.3, room_intensities[i] - amount)
```

---

## 4. 完成条件设计

### 4.1 多维度完成判定

```gdscript
# src/gameplay/LevelCompletionController.gd
class_name LevelCompletionController
extends Node

var completion_criteria: Dictionary = {}
var current_progress: Dictionary = {
    "puzzles_solved": [],
    "rooms_explored": [],
    "exploration_percentage": 0.0,
    "optional_puzzles_solved": []
}

signal completion_requirement_met(type: String)
signal level_completed(completion_data: Dictionary)

func initialize(level_id: String) -> void:
    var config = load("res://assets/data/level_structure_config.json")
    completion_criteria = config.levels[level_id].completion_criteria

func check_completion() -> bool:
    var required_puzzles_met = current_progress.puzzles_solved.size() >= completion_criteria.required_puzzles
    var exploration_met = current_progress.exploration_percentage >= completion_criteria.required_exploration
    
    if required_puzzles_met and not completion_requirement_met.is_null():
        completion_requirement_met.emit("puzzles")
    
    if exploration_met and not completion_requirement_met.is_null():
        completion_requirement_met.emit("exploration")
    
    var completed = required_puzzles_met and exploration_met
    
    if completed:
        var completion_data = {
            "puzzles_solved": current_progress.puzzles_solved.size(),
            "optional_puzzles": current_progress.optional_puzzles_solved.size(),
            "exploration": current_progress.exploration_percentage,
            "completion_rate": calculate_completion_rate()
        }
        level_completed.emit(completion_data)
    
    return completed

func calculate_completion_rate() -> float:
    var puzzle_rate = float(current_progress.puzzles_solved.size()) / float(completion_criteria.required_puzzles)
    var exploration_rate = current_progress.exploration_percentage / float(completion_criteria.required_exploration)
    var optional_rate = 0.0
    
    if completion_criteria.has("optional_puzzles"):
        optional_rate = float(current_progress.optional_puzzles_solved.size()) / float(completion_criteria.optional_puzzles)
    
    return (puzzle_rate + exploration_rate + optional_rate) / 3.0 * 100.0

func on_puzzle_solved(puzzle_id: String, is_optional: bool = false) -> void:
    if is_optional:
        if puzzle_id not in current_progress.optional_puzzles_solved:
            current_progress.optional_puzzles_solved.append(puzzle_id)
    else:
        if puzzle_id not in current_progress.puzzles_solved:
            current_progress.puzzles_solved.append(puzzle_id)
    
    check_completion()

func on_room_explored(room_id: String, total_rooms: int) -> void:
    if room_id not in current_progress.rooms_explored:
        current_progress.rooms_explored.append(room_id)
    
    current_progress.exploration_percentage = float(current_progress.rooms_explored.size()) / float(total_rooms) * 100.0
    check_completion()
```

### 4.2 完成度评级

| 评级 | 完成率 | 谜题完成 | 探索度 | 奖励 |
|------|--------|----------|--------|------|
| S | 100%+ | 全部 | 100% | 额外墨水+50，解锁隐藏皮肤 |
| A | 90-99% | 全部 | ≥90% | 额外墨水+30 |
| B | 75-89% | 全部 | ≥75% | 额外墨水+15 |
| C | 60-74% | 全部 | ≥60% | 无额外奖励 |
| D | <60% | - | - | 建议重试 |

### 4.3 关卡统计追踪

```gdscript
# 关卡完成时统计
static func generate_level_stats(level_id: String, progress: Dictionary) -> Dictionary:
    return {
        "level_id": level_id,
        "completion_time": progress.get("completion_time", 0),
        "puzzles_solved": progress.puzzles_solved.size(),
        "optional_puzzles_solved": progress.optional_puzzles_solved.size(),
        "exploration_percentage": progress.exploration_percentage,
        "death_count": progress.get("death_count", 0),
        "hint_usage": progress.get("hint_usage", 0),
        "ink_consumed": progress.get("ink_consumed", 0),
        "ink_collected": progress.get("ink_collected", 0),
        "completion_rate": calculate_completion_rate_from_progress(progress),
        "rating": calculate_rating(progress)
    }

static func calculate_rating(progress: Dictionary) -> String:
    var completion_rate = calculate_completion_rate_from_progress(progress)
    
    if completion_rate >= 100.0:
        return "S"
    elif completion_rate >= 90.0:
        return "A"
    elif completion_rate >= 75.0:
        return "B"
    elif completion_rate >= 60.0:
        return "C"
    else:
        return "D"
```

---

## 5. 实施计划

### 5.1 第一阶段：基础结构（1周）

- [ ] 创建 `level_structure_config.json`
- [ ] 实现 CheckpointSystem
- [ ] 实现 DeathRecovery
- [ ] 更新 GameController 集成检查点

### 5.2 第二阶段：节奏控制（1周）

- [ ] 实现 PacingController
- [ ] 实现 LevelCompletionController
- [ ] 添加强度曲线可视化
- [ ] 集成音频系统

### 5.3 第三阶段：测试调优（1周）

- [ ] 内部测试各关卡时长
- [ ] 调整检查点位置
- [ ] 优化强度曲线
- [ ] 验证完成条件

---

## 6. 预期效果

### 6.1 关卡时长分布

```
预期通关时间分布:

教学关卡: ████████░░░░░░░░░░░░ 10分钟 (目标: 8-12分钟) ✓
第1层:    █████████░░░░░░░░░░░ 12分钟 (目标: 10-15分钟) ✓
第2层:    ███████████░░░░░░░░░ 15分钟 (目标: 12-18分钟) ✓
第3层:    ███████████████░░░░░ 20分钟 (目标: 16-25分钟) ✓
第4层:    ███████████████████░ 25分钟 (目标: 20-32分钟) ✓
第5层:    ████████████████████████ 30分钟 (目标: 25-40分钟) ✓
Boss战:   ████████████████████████████████ 40分钟 (目标: 35-50分钟) ✓

总游戏时长: 约2.5小时
```

### 6.2 玩家体验目标

| 指标 | 目标值 | 验证方法 |
|------|--------|----------|
| 单次游戏时长 | 20-40分钟 | 会话时长统计 |
| 关卡完成率 | >70% | 漏斗分析 |
| 检查点使用频率 | 1-2次/关卡 | 事件追踪 |
| 死亡后流失率 | <15% | 留存分析 |
| 重玩意愿 | >40% | 问卷调查 |

---

*方案完成 - 调月莉音*