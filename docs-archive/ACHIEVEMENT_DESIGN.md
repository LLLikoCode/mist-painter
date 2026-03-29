# 迷雾绘者 - 成就系统设计文档

## 概述

本文档定义迷雾绘者游戏的成就系统架构，包括数据结构、触发条件和存储方案。

## 核心数据结构

### Achievement 类

```python
from dataclasses import dataclass
from typing import Dict, List, Optional, Callable
from enum import Enum

class AchievementType(Enum):
    PROGRESS = "progress"      # 进度类（如：完成X个关卡）
    COLLECTION = "collection"  # 收集类（如：收集所有画作）
    SKILL = "skill"           # 技巧类（如：无伤通关）
    STORY = "story"           # 剧情类（如：触发特定剧情）
    SECRET = "secret"         # 隐藏类（如：发现彩蛋）

class AchievementRarity(Enum):
    COMMON = 1      # 普通
    UNCOMMON = 2    # 稀有
    RARE = 3        # 史诗
    LEGENDARY = 4   # 传说

@dataclass
class Achievement:
    id: str                     # 唯一标识
    name: str                   # 显示名称
    description: str            # 描述
    type: AchievementType       # 类型
    rarity: AchievementRarity   # 稀有度
    icon: str                   # 图标路径
    secret: bool                # 是否隐藏
    
    # 触发条件
    trigger_type: str           # 触发器类型
    trigger_params: Dict        # 触发参数
    
    # 奖励
    reward_type: Optional[str]  # 奖励类型
    reward_value: Optional[int] # 奖励数值
    
    # 统计
    unlocked_at: Optional[float] # 解锁时间戳
    progress: float             # 当前进度 (0.0 - 1.0)
```

## 成就类型定义

### achievement_types.json

```json
{
  "achievements": [
    {
      "id": "first_steps",
      "name": "第一步",
      "description": "完成第一个关卡",
      "type": "progress",
      "rarity": 1,
      "trigger": {
        "type": "level_complete",
        "params": {"level_id": "level_01"}
      }
    },
    {
      "id": "master_painter",
      "name": "绘画大师",
      "description": "完成所有关卡",
      "type": "progress",
      "rarity": 3,
      "trigger": {
        "type": "levels_complete",
        "params": {"count": "all"}
      }
    },
    {
      "id": "art_collector",
      "name": "艺术收藏家",
      "description": "收集所有隐藏画作",
      "type": "collection",
      "rarity": 3,
      "trigger": {
        "type": "collectible",
        "params": {"type": "painting", "count": "all"}
      }
    },
    {
      "id": "perfectionist",
      "name": "完美主义者",
      "description": "无伤通关任意关卡",
      "type": "skill",
      "rarity": 2,
      "trigger": {
        "type": "level_complete",
        "params": {"damage_taken": 0}
      }
    },
    {
      "id": "speed_runner",
      "name": "速通大师",
      "description": "在5分钟内完成任意关卡",
      "type": "skill",
      "rarity": 2,
      "trigger": {
        "type": "level_complete",
        "params": {"time_limit": 300}
      }
    },
    {
      "id": "story_seeker",
      "name": "故事探索者",
      "description": "触发所有剧情事件",
      "type": "story",
      "rarity": 2,
      "trigger": {
        "type": "event_trigger",
        "params": {"count": "all"}
      }
    },
    {
      "id": "secret_keeper",
      "name": "秘密守护者",
      "description": "发现所有隐藏彩蛋",
      "type": "secret",
      "rarity": 4,
      "secret": true,
      "trigger": {
        "type": "easter_egg",
        "params": {"count": "all"}
      }
    }
  ]
}
```

## 触发器类型

### 1. LevelCompleteTrigger
```python
class LevelCompleteTrigger:
    """关卡完成触发器"""
    def check(self, event: LevelCompleteEvent) -> bool:
        if event.level_id != self.params.get("level_id"):
            return False
        if "damage_taken" in self.params:
            return event.damage_taken <= self.params["damage_taken"]
        if "time_limit" in self.params:
            return event.time <= self.params["time_limit"]
        return True
```

### 2. CollectionTrigger
```python
class CollectionTrigger:
    """收集类触发器"""
    def check(self, event: CollectEvent) -> bool:
        if event.item_type != self.params.get("type"):
            return False
        collected = self.get_collected_count(event.item_type)
        target = self.params.get("count", 1)
        return collected >= target
```

### 3. EventTrigger
```python
class EventTrigger:
    """事件触发器"""
    def check(self, event: GameEvent) -> bool:
        return event.event_id in self.params.get("events", [])
```

## 存储方案

### 与存档系统集成

```python
class AchievementManager:
    def __init__(self, save_manager):
        self.save_manager = save_manager
        self.achievements: Dict[str, Achievement] = {}
        self.load_achievements()
    
    def load_achievements(self):
        """从存档加载成就数据"""
        data = self.save_manager.load("achievements")
        for ach_data in data.get("unlocked", []):
            self.mark_unlocked(ach_data["id"], ach_data["timestamp"])
        for prog_data in data.get("progress", []):
            self.update_progress(prog_data["id"], prog_data["value"])
    
    def save_achievements(self):
        """保存成就数据到存档"""
        data = {
            "unlocked": [
                {"id": a.id, "timestamp": a.unlocked_at}
                for a in self.achievements.values()
                if a.unlocked_at
            ],
            "progress": [
                {"id": a.id, "value": a.progress}
                for a in self.achievements.values()
                if a.progress > 0
            ]
        }
        self.save_manager.save("achievements", data)
```

## 接口定义

### achievement_interface.py

```python
from abc import ABC, abstractmethod
from typing import Dict, List, Optional, Callable
from dataclasses import dataclass

class IAchievementTrigger(ABC):
    """成就触发器接口"""
    
    @abstractmethod
    def check(self, event) -> bool:
        """检查事件是否触发成就"""
        pass
    
    @abstractmethod
    def get_progress(self) -> float:
        """获取当前进度 (0.0 - 1.0)"""
        pass

class IAchievementManager(ABC):
    """成就管理器接口"""
    
    @abstractmethod
    def register_achievement(self, achievement: Achievement) -> None:
        """注册成就"""
        pass
    
    @abstractmethod
    def check_achievement(self, event) -> List[Achievement]:
        """检查事件触发的成就，返回新解锁的成就列表"""
        pass
    
    @abstractmethod
    def get_unlocked(self) -> List[Achievement]:
        """获取已解锁的成就列表"""
        pass
    
    @abstractmethod
    def get_locked(self) -> List[Achievement]:
        """获取未解锁的成就列表"""
        pass
    
    @abstractmethod
    def get_progress(self, achievement_id: str) -> float:
        """获取指定成就的进度"""
        pass

class IAchievementNotifier(ABC):
    """成就通知接口"""
    
    @abstractmethod
    def on_achievement_unlocked(self, achievement: Achievement) -> None:
        """成就解锁回调"""
        pass
    
    @abstractmethod
    def on_progress_update(self, achievement_id: str, progress: float) -> None:
        """进度更新回调"""
        pass
```

## 异步触发支持

```python
import asyncio
from typing import Callable

class AsyncAchievementManager:
    def __init__(self):
        self.listeners: List[Callable] = []
        self.event_queue = asyncio.Queue()
    
    async def process_events(self):
        """异步处理事件队列"""
        while True:
            event = await self.event_queue.get()
            await self._handle_event(event)
    
    async def _handle_event(self, event):
        """处理单个事件"""
        for listener in self.listeners:
            await listener(event)
    
    def emit(self, event):
        """发射事件到队列"""
        asyncio.create_task(self.event_queue.put(event))
```

## 使用示例

```python
# 初始化
achievement_manager = AchievementManager(save_manager)

# 注册成就
achievement_manager.register_achievement(Achievement(
    id="first_steps",
    name="第一步",
    description="完成第一个关卡",
    type=AchievementType.PROGRESS,
    rarity=AchievementRarity.COMMON,
    icon="achievements/first_steps.png",
    trigger_type="level_complete",
    trigger_params={"level_id": "level_01"}
))

# 监听事件
event_bus.subscribe("level_complete", 
    lambda e: achievement_manager.check_achievement(e))

# 获取成就状态
unlocked = achievement_manager.get_unlocked()
print(f"已解锁成就: {len(unlocked)}")
```

## 文件位置

- 设计文档: `docs/ACHIEVEMENT_DESIGN.md`
- 类型定义: `data/achievement_types.json`
- 接口实现: `src/systems/achievement_interface.py`
- 管理器实现: `src/systems/achievement_manager.py`
