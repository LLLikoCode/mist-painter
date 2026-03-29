# 迷雾绘者 (Mist Painter) - 谜题难度调整方案

**文档版本**: 1.0  
**创建日期**: 2026-03-29  
**任务ID**: TASK-022  
**状态**: 设计完成

---

## 1. 谜题难度配置方案

### 1.1 谜题难度数据表

创建文件: `assets/data/puzzle_difficulty_config.json`

```json
{
  "version": "1.0.0",
  "description": "谜题难度配置 - 定义各关卡谜题分布",
  "puzzle_complexity_levels": {
    "L1": { "id": "L1", "name": "基础揭示", "base_score": 10, "description": "单步操作，直接结果" },
    "L2": { "id": "L2", "name": "顺序操作", "base_score": 20, "description": "多步顺序执行" },
    "L3": { "id": "L3", "name": "条件判断", "base_score": 35, "description": "根据状态选择操作" },
    "L4": { "id": "L4", "name": "空间推理", "base_score": 55, "description": "理解空间关系" },
    "L5": { "id": "L5", "name": "时序控制", "base_score": 80, "description": "把握时机" },
    "L6": { "id": "L6", "name": "资源优化", "base_score": 110, "description": "有限资源下的最优解" },
    "L7": { "id": "L7", "name": "复合谜题", "base_score": 150, "description": "多种机制组合" }
  },
  "level_puzzle_distribution": {
    "tutorial": {
      "level_id": "tutorial",
      "level_name": "教学关卡",
      "target_completion_time": 600,
      "puzzle_count": 3,
      "distribution": { "L1": 80, "L2": 20, "L3": 0, "L4": 0, "L5": 0, "L6": 0, "L7": 0 },
      "difficulty_multiplier": 0.5,
      "fog_coverage": 0.3
    },
    "level_1": {
      "level_id": "level_1",
      "level_name": "第1层 - 初探迷雾",
      "target_completion_time": 720,
      "puzzle_count": 5,
      "distribution": { "L1": 50, "L2": 40, "L3": 10, "L4": 0, "L5": 0, "L6": 0, "L7": 0 },
      "difficulty_multiplier": 0.7,
      "fog_coverage": 0.45
    },
    "level_2": {
      "level_id": "level_2",
      "level_name": "第2层 - 符文觉醒",
      "target_completion_time": 900,
      "puzzle_count": 6,
      "distribution": { "L1": 30, "L2": 40, "L3": 25, "L4": 5, "L5": 0, "L6": 0, "L7": 0 },
      "difficulty_multiplier": 1.0,
      "fog_coverage": 0.6
    },
    "level_3": {
      "level_id": "level_3",
      "level_name": "第3层 - 迷雾深渊",
      "target_completion_time": 1200,
      "puzzle_count": 7,
      "distribution": { "L1": 0, "L2": 20, "L3": 40, "L4": 30, "L5": 10, "L6": 0, "L7": 0 },
      "difficulty_multiplier": 1.3,
      "fog_coverage": 0.7
    },
    "level_4": {
      "level_id": "level_4",
      "level_name": "第4层 - 镜像迷宫",
      "target_completion_time": 1500,
      "puzzle_count": 8,
      "distribution": { "L1": 0, "L2": 0, "L3": 25, "L4": 35, "L5": 25, "L6": 15, "L7": 0 },
      "difficulty_multiplier": 1.6,
      "fog_coverage": 0.8
    },
    "level_5": {
      "level_id": "level_5",
      "level_name": "第5层 - 时空绘卷",
      "target_completion_time": 1800,
      "puzzle_count": 8,
      "distribution": { "L1": 0, "L2": 0, "L3": 0, "L4": 20, "L5": 35, "L6": 30, "L7": 15 },
      "difficulty_multiplier": 2.0,
      "fog_coverage": 0.85
    },
    "boss": {
      "level_id": "boss",
      "level_name": "Boss战 - 迷雾之主",
      "target_completion_time": 2400,
      "puzzle_count": 5,
      "distribution": { "L1": 0, "L2": 0, "L3": 0, "L4": 0, "L5": 20, "L6": 40, "L7": 40 },
      "difficulty_multiplier": 2.2,
      "fog_coverage": 0.9
    }
  },
  "puzzle_type_mapping": {
    "SWITCH": { "complexity_range": ["L1", "L3"], "base_time": 30, "ink_cost": 10 },
    "SEQUENCE": { "complexity_range": ["L2", "L4"], "base_time": 60, "ink_cost": 15 },
    "PATH_DRAWING": { "complexity_range": ["L1", "L6"], "base_time": 45, "ink_cost": 20 },
    "SYMBOL_MATCH": { "complexity_range": ["L2", "L5"], "base_time": 90, "ink_cost": 25 },
    "LIGHT_MIRROR": { "complexity_range": ["L3", "L6"], "base_time": 120, "ink_cost": 30 },
    "PRESSURE_PLATE": { "complexity_range": ["L2", "L5"], "base_time": 75, "ink_cost": 15 },
    "COMBINATION": { "complexity_range": ["L4", "L7"], "base_time": 180, "ink_cost": 40 }
  }
}
```

### 1.2 难度评分公式实现

```gdscript
# src/utils/PuzzleDifficultyCalculator.gd
class_name PuzzleDifficultyCalculator

const COMPLEXITY_SCORES = {
    "L1": 10, "L2": 20, "L3": 35, "L4": 55,
    "L5": 80, "L6": 110, "L7": 150
}

const TIME_MULTIPLIERS = {
    "none": 1.0, "loose": 1.2, "standard": 1.5, "strict": 2.0
}

static func calculate_difficulty_score(
    complexity_level: String,
    mechanism_count: int = 1,
    constraint_count: int = 0,
    time_pressure: String = "none"
) -> float:
    var base_score = COMPLEXITY_SCORES.get(complexity_level, 10)
    var mechanism_multiplier = 1.0 + (mechanism_count - 1) * 0.3
    var constraint_multiplier = 1.0 + constraint_count * 0.25
    var time_multiplier = TIME_MULTIPLIERS.get(time_pressure, 1.0)
    
    return base_score * mechanism_multiplier * constraint_multiplier * time_multiplier

static func get_level_target_time(level_id: String) -> int:
    var config = load("res://assets/data/puzzle_difficulty_config.json")
    var level_data = config.level_puzzle_distribution.get(level_id, {})
    return level_data.get("target_completion_time", 600)
```

### 1.3 谜题配置示例

```json
{
  "level_id": "level_1",
  "puzzles": [
    {
      "puzzle_id": "L1_P1",
      "name": "初识迷雾",
      "type": "PATH_DRAWING",
      "complexity": "L1",
      "difficulty_score": 7,
      "position": { "x": 200, "y": 300 },
      "time_limit": 0,
      "max_attempts": 0,
      "config": {
        "start_point": { "x": 200, "y": 300 },
        "end_point": { "x": 400, "y": 300 },
        "waypoints": [],
        "tolerance": 50.0,
        "mist_required": false
      },
      "rewards": { "ink": 20, "unlock_brush": "line" },
      "hint": "按住鼠标绘制路径驱散迷雾"
    },
    {
      "puzzle_id": "L1_P2",
      "name": "简单开关",
      "type": "SWITCH",
      "complexity": "L1",
      "difficulty_score": 10,
      "time_limit": 0,
      "max_attempts": 0,
      "config": {
        "switches": [false],
        "target_states": [true],
        "mist_required": true,
        "mist_radius": 100
      },
      "rewards": { "ink": 15 },
      "hint": "先驱散迷雾，然后激活开关"
    },
    {
      "puzzle_id": "L1_P3",
      "name": "顺序点亮",
      "type": "SEQUENCE",
      "complexity": "L2",
      "difficulty_score": 20,
      "time_limit": 120,
      "max_attempts": 3,
      "config": {
        "sequence": [1, 2, 3],
        "max_length": 3,
        "mist_required": false
      },
      "rewards": { "ink": 25, "unlock_brush": "fill" },
      "hint": "按照符文闪烁的顺序激活"
    }
  ]
}
```

---

## 2. 难度参数调整

### 2.1 时间限制调整

| 关卡 | 谜题类型 | 当前时间 | 建议时间 | 调整理由 |
|------|----------|----------|----------|----------|
| 教学 | 全部 | 无限制 | 无限制 | 保持学习友好 |
| 第1层 | L1 | 无限制 | 无限制 | 建立信心 |
| 第1层 | L2 | 无限制 | 120秒 | 引入时间概念 |
| 第2层 | L2 | 无限制 | 90秒 | 适度压力 |
| 第2层 | L3 | 无限制 | 150秒 | 条件判断需要思考 |
| 第3层 | L3 | 无限制 | 120秒 | 标准时间压力 |
| 第3层 | L4 | 无限制 | 180秒 | 空间推理较复杂 |
| 第4层 | L5 | 无限制 | 120秒 | 时序控制严格 |
| 第5层 | L6 | 无限制 | 90秒 | 资源优化需快速决策 |
| Boss | L7 | 无限制 | 60秒 | 极限挑战 |

### 2.2 尝试次数调整

| 复杂度 | 当前尝试 | 建议尝试 | 失败惩罚 |
|--------|----------|----------|----------|
| L1 | 无限 | 无限 | 无 |
| L2 | 无限 | 5次 | 重置谜题 |
| L3 | 无限 | 4次 | 重置谜题+扣除5墨水 |
| L4 | 无限 | 3次 | 重置谜题+扣除10墨水 |
| L5 | 无限 | 3次 | 重置谜题+扣除15墨水 |
| L6 | 无限 | 2次 | 重置谜题+扣除20墨水 |
| L7 | 无限 | 2次 | 重置谜题+扣除25墨水 |

### 2.3 墨水消耗调整

```gdscript
# 谜题类型基础消耗
const PUZZLE_INK_COST = {
    "SWITCH": 10,
    "SEQUENCE": 15,
    "PATH_DRAWING": 20,
    "SYMBOL_MATCH": 25,
    "LIGHT_MIRROR": 30,
    "PRESSURE_PLATE": 15,
    "COMBINATION": 40
}

# 复杂度消耗倍率
const COMPLEXITY_MULTIPLIER = {
    "L1": 0.8, "L2": 1.0, "L3": 1.2, "L4": 1.4,
    "L5": 1.6, "L6": 1.8, "L7": 2.0
}

static func calculate_ink_cost(puzzle_type: String, complexity: String) -> int:
    var base_cost = PUZZLE_INK_COST.get(puzzle_type, 20)
    var multiplier = COMPLEXITY_MULTIPLIER.get(complexity, 1.0)
    return int(base_cost * multiplier)
```

---

## 3. 实现代码示例

### 3.1 更新 PuzzleController

```gdscript
# 添加到 PuzzleController.gd

@export var complexity_level: String = "L1"
@export var ink_cost: int = 20

func calculate_difficulty_score() -> float:
    var mechanism_count = puzzle_data.get("mechanisms", []).size()
    var constraint_count = puzzle_data.get("constraints", []).size()
    var time_pressure = "strict" if time_limit > 0 and time_limit < 60 else "standard" if time_limit > 0 else "none"
    
    return PuzzleDifficultyCalculator.calculate_difficulty_score(
        complexity_level, mechanism_count, constraint_count, time_pressure
    )

func consume_ink(player: Node) -> bool:
    if player.has_method("consume_ink"):
        return player.consume_ink(ink_cost)
    return true
```

### 3.2 难度验证工具

```gdscript
# src/utils/DifficultyValidator.gd
class_name DifficultyValidator

static func validate_level_difficulty(level_id: String) -> Dictionary:
    var config = load("res://assets/data/puzzle_difficulty_config.json")
    var level_data = config.level_puzzle_distribution[level_id]
    var puzzles = load("res://assets/data/level_puzzles/%s_puzzles.json" % level_id)
    
    var results = {
        "level_id": level_id,
        "target_time": level_data.target_completion_time,
        "puzzle_count": level_data.puzzle_count,
        "actual_puzzles": puzzles.puzzles.size(),
        "difficulty_distribution": {},
        "average_difficulty": 0.0,
        "issues": []
    }
    
    # 验证谜题数量
    if puzzles.puzzles.size() != level_data.puzzle_count:
        results.issues.append("谜题数量不匹配: 期望 %d, 实际 %d" % [level_data.puzzle_count, puzzles.puzzles.size()])
    
    # 验证难度分布
    var complexity_count = {"L1": 0, "L2": 0, "L3": 0, "L4": 0, "L5": 0, "L6": 0, "L7": 0}
    var total_score = 0.0
    
    for puzzle in puzzles.puzzles:
        var complexity = puzzle.complexity
        complexity_count[complexity] += 1
        total_score += puzzle.difficulty_score
    
    results.average_difficulty = total_score / puzzles.puzzles.size()
    results.difficulty_distribution = complexity_count
    
    # 验证分布是否符合设计
    for level in complexity_count.keys():
        var expected = level_data.puzzle_count * level_data.distribution[level] / 100.0
        var actual = complexity_count[level]
        if abs(actual - expected) > 1:
            results.issues.append("%s 数量偏差: 期望 %.1f, 实际 %d" % [level, expected, actual])
    
    return results
```

---

## 4. 调整实施计划

### 4.1 第一阶段：基础配置（1周）

- [ ] 创建 `puzzle_difficulty_config.json`
- [ ] 创建各关卡谜题配置文件
- [ ] 更新 PuzzleController 支持难度字段
- [ ] 实现 PuzzleDifficultyCalculator

### 4.2 第二阶段：数值调优（1周）

- [ ] 实现难度验证工具
- [ ] 运行自动化验证
- [ ] 调整偏差较大的谜题
- [ ] 内部测试收集反馈

### 4.3 第三阶段：动态调整（1周）

- [ ] 实现运行时难度追踪
- [ ] 添加数据收集埋点
- [ ] 分析玩家行为数据
- [ ] 根据数据微调数值

---

## 5. 预期效果

### 5.1 难度曲线目标

```
预期难度分布:

教学关卡: ████░░░░░░░░░░░░░░░░ 平均难度: 12分
第1层:    ██████░░░░░░░░░░░░░░ 平均难度: 18分 (+50%)
第2层:    █████████░░░░░░░░░░░ 平均难度: 28分 (+56%)
第3层:    ███████████░░░░░░░░░ 平均难度: 42分 (+50%)
第4层:    ██████████████░░░░░░ 平均难度: 60分 (+43%)
第5层:    █████████████████░░░ 平均难度: 85分 (+42%)
Boss战:   ███████████████████░ 平均难度: 120分 (+41%)

递进率控制在 40-60% 之间，保持平滑增长
```

### 5.2 通关时间目标

| 关卡 | 目标时间 | 容差范围 | 验证标准 |
|------|----------|----------|----------|
| 教学 | 10分钟 | 8-12分钟 | 90%玩家达标 |
| 第1层 | 12分钟 | 10-15分钟 | 85%玩家达标 |
| 第2层 | 15分钟 | 12-18分钟 | 80%玩家达标 |
| 第3层 | 20分钟 | 16-25分钟 | 70%玩家达标 |
| 第4层 | 25分钟 | 20-32分钟 | 60%玩家达标 |
| 第5层 | 30分钟 | 25-40分钟 | 50%玩家达标 |
| Boss | 40分钟 | 35-50分钟 | 40%玩家达标 |

---

*方案完成 - 调月莉音*