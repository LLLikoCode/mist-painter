# 迷雾绘者 (Mist Painter) - 进度系统设计文档

**文档版本**: 1.0  
**创建日期**: 2026-03-22  
**最后更新**: 2026-03-22  
**作者**: AI Assistant  
**状态**: 设计完成

---

## 目录

1. [进度系统概述](#1-进度系统概述)
2. [进度保存机制](#2-进度保存机制)
3. [进度恢复机制](#3-进度恢复机制)
4. [多周目与永久进度](#4-多周目与永久进度)
5. [进度追踪与展示](#5-进度追踪与展示)
6. [技术实现方案](#6-技术实现方案)

---

## 1. 进度系统概述

### 1.1 设计目标

| 目标 | 说明 | 实现方式 |
|------|------|----------|
| **随时保存** | 玩家可随时中断游戏 | 自动保存+手动保存 |
| **进度安全** | 防止数据丢失 | 多备份+云同步 |
| **灵活恢复** | 支持多种恢复场景 | 检查点+章节选择 |
| **跨会话连续** | 多设备/多时段连续体验 | 云存档+本地缓存 |

### 1.2 进度类型定义

```
┌─────────────────────────────────────────────────────────────────┐
│                      进度类型层级                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  永久进度 (Meta Progress)                                │   │
│  │  - 解锁内容、成就、统计数据                               │   │
│  │  - 跨周目保留                                            │   │
│  └─────────────────────────────────────────────────────────┘   │
│                           │                                     │
│  ┌────────────────────────┴────────────────────────┐           │
│  │              周目进度 (Run Progress)             │           │
│  │  - 当前游戏会话的完整状态                         │           │
│  │  - 死亡或通关后重置                              │           │
│  └──────────────────────────────────────────────────┘           │
│                           │                                     │
│        ┌──────────────────┼──────────────────┐                 │
│        ▼                  ▼                  ▼                 │
│  ┌──────────┐      ┌──────────┐      ┌──────────┐             │
│  │ 关卡进度 │      │ 临时进度 │      │ 检查点   │             │
│  │(章节保存)│      │(自动保存)│      │(死亡恢复)│             │
│  └──────────┘      └──────────┘      └──────────┘             │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 1.3 进度数据结构

```typescript
// 完整进度数据结构
interface GameProgress {
  // 元数据
  version: string;           // 存档版本
  createdAt: number;         // 创建时间
  updatedAt: number;         // 最后更新
  playTime: number;          // 总游戏时长(秒)
  
  // 永久进度
  meta: MetaProgress;
  
  // 当前周目进度
  currentRun: RunProgress | null;
  
  // 设置选项
  settings: GameSettings;
}

interface MetaProgress {
  unlockedLevels: string[];      // 已解锁关卡
  achievements: Achievement[];   // 已获得成就
  totalPlayTime: number;         // 累计游戏时间
  totalRuns: number;             // 总游戏次数
  bestScores: Record<string, number>;  // 各关卡最佳分数
  unlockedSkins: string[];       // 解锁的皮肤
  unlockedBrushTypes: string[];  // 解锁的画笔类型
  statistics: GameStatistics;    // 游戏统计
}

interface RunProgress {
  runId: string;                 // 周目唯一ID
  startedAt: number;             // 开始时间
  currentLevel: string;          // 当前关卡
  currentRoom: string;           // 当前房间
  
  // 玩家状态
  player: PlayerState;
  
  // 关卡状态
  levelStates: Record<string, LevelState>;
  
  // 全局状态
  globalState: GlobalState;
}
```

---

## 2. 进度保存机制

### 2.1 自动保存策略

| 触发条件 | 保存类型 | 保存内容 | 频率限制 |
|----------|----------|----------|----------|
| 进入新房间 | 临时保存 | 当前房间状态 | 无限制 |
| 完成谜题 | 检查点 | 谜题完成状态 | 无限制 |
| 切换层级 | 完整保存 | 整个层级状态 | 无限制 |
| 获得重要道具 | 临时保存 | 道具+状态 | 无限制 |
| 游戏暂停 | 快速保存 | 当前帧状态 | 30秒冷却 |
| 应用切换 | 紧急保存 | 完整状态 | 立即执行 |

### 2.2 手动保存

**保存槽位设计**：
```
┌─────────────────────────────────────────┐
│ 保存游戏                                │
├─────────────────────────────────────────┤
│                                         │
│ [快速保存]  自动 - 最后: 2分钟前       │
│                                         │
│ 存档槽位:                               │
│ ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐   │
│ │槽1 │ │槽2 │ │槽3 │ │槽4 │ │槽5 │   │
│ │空  │ │Lv3 │ │空  │ │Lv2 │ │空  │   │
│ └────┘ └────┘ └────┘ └────┘ └────┘   │
│                                         │
│ [新存档] [覆盖] [删除] [返回]          │
└─────────────────────────────────────────┘
```

**存档信息**：
- 存档缩略图（当前画面截图）
- 关卡名称和进度百分比
- 游戏时长
- 保存日期时间
- 难度等级

### 2.3 保存数据内容

**完整保存包含**：
```typescript
interface FullSaveData {
  // 基础信息
  saveId: string;
  saveName: string;
  timestamp: number;
  
  // 游戏状态
  currentLevel: string;
  playerPosition: { x: number; y: number };
  playerState: PlayerState;
  
  // 关卡状态
  revealedFog: boolean[][];      // 已揭示迷雾
  completedPuzzles: string[];    // 已完成谜题
  collectedItems: string[];      // 已收集物品
  defeatedEnemies: string[];     // 已击败敌人
  triggeredEvents: string[];     // 已触发事件
  
  // 世界状态
  unlockedDoors: string[];       // 已解锁门
  activatedMechanisms: string[]; // 已激活机关
  
  // 临时数据
  currentInk: number;
  activeEffects: Buff[];
  
  // 截图（Base64）
  screenshot?: string;
}
```

### 2.4 保存优化策略

**增量保存**：
```
首次保存: 完整数据 (100%)
后续保存: 差异数据 (~20%)

差异检测:
- 对比上次保存的哈希值
- 仅保存变化的字段
- 合并连续的小变更
```

**压缩策略**：
```
1. JSON序列化
2. 字段名压缩 (使用短键名映射)
3. 数组游程编码 (迷雾数据)
4. Gzip压缩
5. Base64编码存储

预期压缩率: 60-70%
```

---

## 3. 进度恢复机制

### 3.1 恢复场景

| 场景 | 恢复方式 | 恢复点 |
|------|----------|--------|
| 应用崩溃 | 自动恢复 | 最后自动保存 |
| 玩家死亡 | 检查点恢复 | 最近检查点 |
| 手动继续 | 选择存档 | 任意保存槽 |
| 跨设备 | 云同步 | 最新云端存档 |
| 重新开始 | 新建周目 | 游戏开始 |

### 3.2 检查点系统

**检查点分布**：
```
第1层: 起始点 ──[检查点]── 中间 ──[检查点]── Boss前
       0%          40%          75%          100%

第2层: 起始点 ──[检查点]──[检查点]──[检查点]── Boss前
       0%         25%        50%        75%       100%

Boss战: 起始点 ──[检查点]── 阶段2 ──[检查点]── 完成
        0%          30%          70%          100%
```

**检查点触发条件**：
1. 到达指定位置
2. 完成关键谜题
3. 击败精英敌人
4. 获得重要道具
5. 手动激活（消耗资源）

### 3.3 死亡恢复流程

```
┌──────────┐     ┌──────────┐     ┌──────────┐
│ 玩家死亡 │────▶│ 结算画面 │────▶│ 恢复选项 │
└──────────┘     └──────────┘     └────┬─────┘
                                       │
                    ┌──────────────────┼──────────────────┐
                    ▼                  ▼                  ▼
              ┌──────────┐      ┌──────────┐      ┌──────────┐
              │ 检查点   │      │ 重新开始 │      │ 退出到   │
              │ 恢复     │      │ 本层     │      │ 主菜单   │
              └──────────┘      └──────────┘      └──────────┘
```

**恢复惩罚**（可选）：
- 简单难度：无惩罚
- 普通难度：失去10%墨水
- 困难难度：失去25%墨水，重置当前房间
- 极难难度：失去50%墨水，重置当前层级

### 3.4 章节选择系统

**解锁条件**：
- 完成某章节后解锁该章节选择
- 多周目可解锁全部章节

**章节选择界面**：
```
┌─────────────────────────────────────────┐
│ 章节选择                                │
├─────────────────────────────────────────┤
│                                         │
│  [教学关卡]    [第1层]      [第2层]    │
│   已完成       已完成       已完成      │
│                                         │
│  [第3层]       [第4层]      [第5层]    │
│   当前进度     已解锁       已解锁      │
│   65%                                    │
│                                         │
│  [Boss战]                               │
│   已解锁                                │
│                                         │
│  [从选中章节开始]  [返回]              │
└─────────────────────────────────────────┘
```

---

## 4. 多周目与永久进度

### 4.1 周目系统

**周目继承规则**：

| 继承内容 | 第2周目 | 第3周目+ | 说明 |
|----------|---------|----------|------|
| 解锁的关卡 | ✓ | ✓ | 可自由选择 |
| 解锁的画笔 | ✓ | ✓ | 全部可用 |
| 成就记录 | ✓ | ✓ | 累积统计 |
| 最佳分数 | ✓ | ✓ | 挑战记录 |
| 皮肤/外观 | ✓ | ✓ | 全部可用 |
| 章节选择 | ✓ | ✓ | 任意跳转 |
| 难度选项 | ✓ | ✓ | 解锁极难 |
| 隐藏内容 | - | ✓ | 第3周目解锁 |

**多周目新增内容**：
```
第2周目:
- 新敌人类型 (20%替换)
- 新谜题变体
- 精英敌人增加
- 新对话/剧情

第3周目:
- 隐藏Boss解锁
- 真结局路线
- 极限挑战模式
- 开发者评论

第4周目+:
- 无尽模式
- 排行榜挑战
- 自定义规则
```

### 4.2 成就系统

**成就分类**：

| 类别 | 数量 | 示例 |
|------|------|------|
| 探索类 | 15 | "迷雾驱散者"(驱散1000格迷雾) |
| 战斗类 | 12 | "无伤大师"(无伤击败Boss) |
| 解谜类 | 18 | "速解专家"(30秒内完成谜题) |
| 收集类 | 10 | "全图鉴"(收集所有道具) |
| 挑战类 | 15 | "速通王者"(20分钟内通关) |
| 隐藏类 | 8 | "???"(秘密成就) |

**成就奖励**：
```
成就点数 ──▶ 解锁内容
   10点  ──▶ 新皮肤: 青铜绘者
   25点  ──▶ 新画笔: 流光笔
   50点  ──▶ 新皮肤: 白银绘者
  100点  ──▶ 无尽模式解锁
  150点  ──▶ 新皮肤: 黄金绘者
  200点  ──▶ 开发者模式
```

### 4.3 统计数据

**记录指标**：
```typescript
interface GameStatistics {
  // 基础统计
  totalRuns: number;           // 总游戏次数
  totalPlayTime: number;       // 总游戏时长
  totalDeaths: number;         // 总死亡次数
  
  // 探索统计
  totalFogDispelled: number;   // 驱散迷雾总数
  totalRoomsExplored: number;  // 探索房间数
  totalPuzzlesSolved: number;  // 解谜总数
  
  // 战斗统计
  totalEnemiesDefeated: number;  // 击败敌人数
  totalDamageDealt: number;      // 造成伤害
  totalDamageTaken: number;      // 受到伤害
  perfectCombats: number;        // 无伤战斗
  
  // 资源统计
  totalInkCollected: number;     // 收集墨水
  totalInkConsumed: number;      // 消耗墨水
  totalItemsCollected: number;   // 收集道具
  
  // 最佳记录
  fastestClear: number;          // 最快通关
  lowestInkClear: number;        // 最少墨水通关
  highestScore: number;          // 最高分数
}
```

---

## 5. 进度追踪与展示

### 5.1 进度可视化

**关卡进度条**：
```
第3层 - 迷雾深渊
[████████████████████░░░░░░░░] 75%

已探索: 12/16 房间
已解谜: 8/10 谜题
已收集: 3/5 隐藏物品
```

**整体进度概览**：
```
┌─────────────────────────────────────────┐
│ 游戏进度                                │
├─────────────────────────────────────────┤
│                                         │
│ 主线进度: [████████████░░░░] 80%       │
│ 收集进度: [████████░░░░░░░░] 60%       │
│ 成就进度: [██████████████░░] 75%       │
│                                         │
│ 游戏时长: 12小时30分                   │
│ 通关次数: 3                            │
│ 死亡次数: 47                           │
│                                         │
│ [查看详情] [分享进度]                  │
└─────────────────────────────────────────┘
```

### 5.2 地图迷雾显示

**已探索区域标记**：
```
┌─────────────────────┐
│  迷雾地图           │
├─────────────────────┤
│ ░░██░░░░░░░░░░░░░░ │
│ ░░██░░░░░░░░░░░░░░ │
│ ░░██████░░░░░░░░░░ │
│ ░░░░████░░░░░░░░░░ │
│ ░░░░██░░░░░░░░░░░░ │
│ ░░░░░░░░░░░░░░░░░░ │
│ ░░░░░░░░░░░░░░░░░░ │
│ ░░░░░░░░░░░░░░░░░░ │
│                     │
│ ██ = 已探索        │
│ ░░ = 未探索        │
└─────────────────────┘
```

### 5.3 进度分享

**分享卡片内容**：
```
┌─────────────────────────┐
│  迷雾绘者               │
│  ─────────────          │
│  我在第3层 - 迷雾深渊   │
│  探索进度: 75%          │
│  已游戏: 5小时          │
│                         │
│  [二维码]               │
│  扫码查看我的进度       │
└─────────────────────────┘
```

---

## 6. 技术实现方案

### 6.1 存储方案

**本地存储**：
```typescript
// IndexedDB 结构
const dbSchema = {
  saves: {
    keyPath: 'saveId',
    indexes: ['timestamp', 'level']
  },
  checkpoints: {
    keyPath: 'checkpointId',
    indexes: ['level', 'timestamp']
  },
  meta: {
    keyPath: 'key'
  }
};

// LocalStorage 存储
localStorage.setItem('mist-painter-meta', JSON.stringify(metaProgress));
```

**云同步**（可选）：
```typescript
interface CloudSyncConfig {
  provider: 'firebase' | 'supabase' | 'custom';
  autoSync: boolean;
  syncInterval: number;  // 分钟
  conflictResolution: 'local' | 'cloud' | 'newest';
}
```

### 6.2 存档管理器

```typescript
class SaveManager {
  // 创建存档
  async createSave(slot: number, name?: string): Promise<SaveData>;
  
  // 加载存档
  async loadSave(saveId: string): Promise<GameState>;
  
  // 删除存档
  async deleteSave(saveId: string): Promise<void>;
  
  // 自动保存
  async autoSave(): Promise<void>;
  
  // 创建检查点
  async createCheckpoint(type: CheckpointType): Promise<Checkpoint>;
  
  // 恢复到检查点
  async restoreCheckpoint(checkpointId: string): Promise<GameState>;
  
  // 导出/导入
  async exportSave(saveId: string): Promise<string>;  // Base64
  async importSave(data: string): Promise<SaveData>;
}
```

### 6.3 序列化方案

```typescript
class GameStateSerializer {
  // 序列化
  serialize(state: GameState): string {
    const compressed = {
      v: 1,  // 版本
      lvl: state.currentLevel,
      pos: [state.player.x, state.player.y],
      ink: state.player.ink,
      // ... 其他字段使用短键名
    };
    
    const json = JSON.stringify(compressed);
    const gzipped = gzip(json);
    return base64Encode(gzipped);
  }
  
  // 反序列化
  deserialize(data: string): GameState {
    const gzipped = base64Decode(data);
    const json = ungzip(gzipped);
    const compressed = JSON.parse(json);
    
    return {
      currentLevel: compressed.lvl,
      player: {
        x: compressed.pos[0],
        y: compressed.pos[1],
        ink: compressed.ink,
      },
      // ... 还原其他字段
    };
  }
}
```

### 6.4 性能优化

| 优化策略 | 实现方式 | 效果 |
|----------|----------|------|
| 延迟保存 | 防抖处理，合并短时间内的多次保存请求 | 减少IO次数 |
| 后台保存 | Web Worker中执行序列化和压缩 | 不阻塞主线程 |
| 增量更新 | 只保存变化的数据 | 减少数据量 |
| 本地缓存 | 内存中保持当前状态 | 快速读取 |
| 存档清理 | 自动删除过旧的自动存档 | 节省空间 |

### 6.5 数据迁移

**版本兼容性**：
```typescript
const migrations = {
  '1.0': (data: any) => data,  // 初始版本
  '1.1': (data: any) => {
    // 添加新字段
    data.newField = defaultValue;
    return data;
  },
  '1.2': (data: any) => {
    // 重命名字段
    data.renamedField = data.oldField;
    delete data.oldField;
    return data;
  }
};

function migrateSave(data: any, fromVersion: string): any {
  const versions = Object.keys(migrations).sort();
  const startIndex = versions.indexOf(fromVersion);
  
  for (let i = startIndex; i < versions.length; i++) {
    data = migrations[versions[i]](data);
  }
  
  return data;
}
```

---

## 附录

### A. 存档文件格式

```json
{
  "version": "1.0",
  "format": "mist-painter-save",
  "metadata": {
    "saveId": "save-001",
    "saveName": "第3层进度",
    "createdAt": 1711094400000,
    "updatedAt": 1711101600000,
    "playTime": 7200
  },
  "metaProgress": {
    "unlockedLevels": ["tutorial", "level1", "level2", "level3"],
    "achievements": ["first_blood", "puzzle_master"],
    "totalRuns": 5,
    "bestScores": {
      "level1": 15000,
      "level2": 23000
    }
  },
  "currentRun": {
    "runId": "run-005",
    "currentLevel": "level3",
    "currentRoom": "room-12",
    "player": {
      "position": { "x": 120, "y": 240 },
      "ink": 85,
      "maxInk": 130,
      "unlockedBrushes": ["basic", "line", "fill", "red", "blue"]
    },
    "levelStates": {
      "level3": {
        "revealedFog": [[0,0,1,1,0], [0,0,1,1,0]],
        "completedPuzzles": ["p3-1", "p3-2", "p3-4"],
        "collectedItems": ["item-3-1", "item-3-5"],
        "unlockedDoors": ["door-3-a", "door-3-b"]
      }
    }
  },
  "settings": {
    "difficulty": "normal",
    "autoSave": true,
    "autoSaveInterval": 300
  }
}
```

### B. 版本历史

| 版本 | 日期 | 修改内容 |
|------|------|----------|
| 1.0 | 2026-03-22 | 初始版本，完成进度系统设计 |

---

*文档结束*
