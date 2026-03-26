# 迷雾绘者 - 存档系统设计文档

> **文档版本**: 1.0  
> **最后更新**: 2026-03-20  
> **技术栈**: TypeScript / HTML5 / LocalStorage / IndexedDB

---

## 1. 设计目标

### 1.1 核心目标
- **可靠性**: 存档数据不丢失、不损坏
- **安全性**: 防止玩家作弊篡改存档
- **兼容性**: 支持跨平台、跨版本存档迁移
- **用户体验**: 快速存档/读档，自动备份

### 1.2 功能目标
- 自动存档（检查点机制）
- 手动存档（多槽位支持）
- 存档导入/导出
- 存档云同步预留接口

---

## 2. 数据结构设计

### 2.1 存档数据模型

```typescript
// 主存档数据结构
interface SaveData {
  // === 元数据 ===
  version: string;           // 存档格式版本 (如 "1.0.0")
  gameVersion: string;       // 游戏版本号
  timestamp: number;         // 存档创建时间戳
  playTime: number;          // 累计游戏时长（秒）
  saveType: SaveType;        // 存档类型
  
  // === 玩家数据 ===
  player: PlayerData;
  
  // === 游戏世界 ===
  world: WorldData;
  
  // === 系统状态 ===
  settings: GameSettings;
  statistics: GameStatistics;
}

// 存档类型枚举
enum SaveType {
  AUTO = 'auto',         // 自动存档
  MANUAL = 'manual',     // 手动存档
  CHECKPOINT = 'checkpoint', // 检查点
  QUIT = 'quit',         // 退出存档
}

// 玩家数据
interface PlayerData {
  id: string;
  name: string;
  level: number;
  exp: number;
  position: Position;
  layer: number;
  direction: Direction;
  stamina: number;
  maxStamina: number;
  equippedTool: ToolData | null;
  lightSource: LightSourceData | null;
  inventory: InventoryData;
  drawnMaps: Record<number, PlayerMapData>;
  unlockedTools: string[];
  discoveredSecrets: string[];
}

// 位置
interface Position { x: number; y: number; }

// 玩家地图数据
interface PlayerMapData {
  layer: number;
  cells: Record<string, DrawnCellData>;
  lastVisited: Record<string, number>;
  paperType: PaperType;
  marks: MapMarkData[];
}

// 绘制格子数据
interface DrawnCellData {
  x: number; y: number; drawnType: CellType;
  accuracy: number; timestamp: number; toolUsed: ToolType;
}

// 地图标记
interface MapMarkData {
  x: number; y: number; type: MarkType;
  note: string; timestamp: number;
}

// 世界数据
interface WorldData {
  seed: string;
  currentLayer: number;
  layers: Record<number, LayerData>;
  globalState: GlobalState;
}

// 层数据
interface LayerData {
  layer: number;
  maze: MazeData;
  visitedCells: string[];
  activatedTriggers: string[];
  collectedItems: string[];
  defeatedEnemies: string[];
  modifiedCells: Record<string, CellModification>;
}

// 迷宫数据
interface MazeData {
  width: number; height: number;
  cells: CellData[][];
  rooms: RoomData[];
  entrance: Position; exit: Position;
}

// 格子数据
interface CellData {
  x: number; y: number; type: CellType;
  discovered: boolean; isOneWay: boolean;
  oneWayDir: Direction | null;
  teleporterId: string | null;
  roomId: string | null;
  isShifting: boolean;
}

// 格子修改（动态迷宫）
interface CellModification {
  x: number; y: number;
  originalType: CellType; currentType: CellType;
  shiftTimer: number;
}

// 游戏设置
interface GameSettings {
  masterVolume: number;
  musicVolume: number;
  sfxVolume: number;
  fullscreen: boolean;
  showFPS: boolean;
  minimapEnabled: boolean;
  autoSave: boolean;
  autoSaveInterval: number;
  tutorialEnabled: boolean;
  colorblindMode: boolean;
  highContrast: boolean;
  screenShake: boolean;
}

// 游戏统计
interface GameStatistics {
  totalPlayTime: number;
  totalDeaths: number;
  totalSteps: number;
  mapsDrawn: number;
  puzzlesSolved: number;
  secretsFound: number;
  itemsCollected: number;
  layersExplored: number;
  achievements: string[];
  achievementProgress: Record<string, number>;
}

// 存档槽位信息
interface SaveSlotInfo {
  slotId: number;
  exists: boolean;
  timestamp: number | null;
  playTime: number | null;
  playerLevel: number | null;
  currentLayer: number | null;
  thumbnail: string | null;
}
```

### 2.2 数据序列化格式

**选择: JSON + Base64 + 轻度加密**

```
原始数据 (SaveData Object) → JSON 序列化 → 轻度加密 (XOR) → Base64 编码 → 存储
```

**理由:**
1. **JSON**: 人类可读，便于调试和版本迁移
2. **轻度加密**: XOR + 混淆，防止直接文本编辑作弊
3. **Base64**: 确保二进制数据安全传输和存储
4. **校验和**: MD5 检测数据损坏

---

## 3. 存档管理功能

### 3.1 自动存档系统

**触发条件:**
- 时间间隔（默认5分钟）
- 到达检查点
- 切换层数
- 进入安全区
- 解谜完成

**策略:**
- 最多保留 3 个自动存档，循环覆盖
- 自动存档单独存储，不影响手动存档槽位

### 3.2 手动存档系统

- 支持 5 个存档槽位
- 显示存档元信息（时间、时长、层数等）
- 支持覆盖确认

### 3.3 存档备份机制

- 本地备份保留最近 3 个版本
- 支持导出为文件
- 支持从文件导入

---

## 4. 技术实现

### 4.1 存储适配器层

支持 LocalStorage 和 IndexedDB 两种存储方式。

### 4.2 加密策略

- XOR 加密 + 混淆
- MD5 校验和
- 版本签名验证

### 4.3 错误处理

- 存储空间不足检测
- 存档损坏恢复
- 版本不匹配迁移

---

## 5. API 概览

| 方法 | 说明 |
|------|------|
| `save(slotId, data)` | 保存到指定槽位 |
| `load(slotId)` | 从槽位加载 |
| `delete(slotId)` | 删除存档 |
| `autoSave(data)` | 自动存档 |
| `export(slotId)` | 导出存档为字符串 |
| `import(data)` | 导入存档 |
| `getSlotInfos()` | 获取所有槽位信息 |

---

## 6. 版本历史

| 版本 | 日期 | 说明 |
|------|------|------|
| 1.0 | 2026-03-20 | 初始版本 |
