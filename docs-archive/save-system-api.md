# 迷雾绘者 - 存档系统 API 文档

> **版本**: 1.0  
> **最后更新**: 2026-03-20

---

## 快速开始

### 1. 基础使用

```typescript
import { createSaveManager } from './save-system';

// 创建存档管理器
const saveManager = createSaveManager({
  maxManualSlots: 5,      // 手动存档槽位数
  maxAutoSaves: 3,        // 自动存档数量
  enableEncryption: true, // 启用加密
  autoSaveInterval: 5,    // 自动存档间隔（分钟）
});

// 保存游戏
await saveManager.save(1, gameState);

// 加载游戏
const loadedData = await saveManager.load(1);

// 获取所有槽位信息
const slots = await saveManager.getSlotInfos();
```

### 2. 使用 IndexedDB（大容量存储）

```typescript
import { createIndexedDBSaveManager } from './save-system';

const saveManager = createIndexedDBSaveManager({
  maxManualSlots: 5,
  maxAutoSaves: 3,
});
```

---

## API 参考

### SaveManager

主存档管理类，提供完整的存档管理功能。

#### 构造函数

```typescript
constructor(options: SaveManagerOptions)

interface SaveManagerOptions {
  storage: StorageAdapter;      // 存储适配器
  config: SaveSystemConfig;     // 系统配置
}
```

#### 核心方法

##### `save(slotId: number, data: SaveData): Promise<void>`

保存游戏到指定槽位。

**参数:**
- `slotId`: 槽位ID (1-5)
- `data`: 游戏存档数据

**示例:**
```typescript
await saveManager.save(1, {
  player: playerData,
  world: worldData,
  settings: gameSettings,
  statistics: gameStats,
  // ... 其他字段会自动填充
});
```

##### `load(slotId: number): Promise<SaveData>`

从指定槽位加载游戏。

**参数:**
- `slotId`: 槽位ID

**返回值:** 存档数据

**异常:**
- `SaveErrorType.NOT_FOUND`: 槽位不存在存档
- `SaveErrorType.CORRUPTED`: 存档数据损坏

**示例:**
```typescript
try {
  const data = await saveManager.load(1);
  // 恢复游戏状态
} catch (e) {
  if (e.type === SaveErrorType.NOT_FOUND) {
    console.log('存档不存在');
  }
}
```

##### `delete(slotId: number): Promise<void>`

删除指定槽位的存档。

##### `exists(slotId: number): Promise<boolean>`

检查槽位是否存在存档。

---

#### 自动存档

##### `autoSave(data: SaveData): Promise<void>`

创建自动存档。

**说明:**
- 自动存档使用循环覆盖策略
- 最多保留 `maxAutoSaves` 个自动存档
- 自动存档单独存储，不影响手动存档槽位

**示例:**
```typescript
// 在关键节点触发自动存档
await saveManager.autoSave(gameState);
```

##### `getLatestAutoSave(): Promise<SaveData | null>`

获取最新的自动存档。

**返回值:** 最新的自动存档数据，如果不存在则返回 `null`

##### `clearAutoSaves(): Promise<void>`

清除所有自动存档。

---

#### 导入/导出

##### `exportSave(slotId: number): Promise<string>`

导出存档为 Base64 字符串。

**用途:**
- 备份存档
- 分享存档
- 云同步

**示例:**
```typescript
const saveString = await saveManager.exportSave(1);
// 保存到文件或发送到服务器
localStorage.setItem('backup_save', saveString);
```

##### `importSave(data: string, targetSlotId?: number): Promise<number>`

从字符串导入存档。

**参数:**
- `data`: Base64 编码的存档字符串
- `targetSlotId`: 目标槽位（可选，自动选择空槽或最旧槽位）

**返回值:** 导入的槽位ID

**示例:**
```typescript
const saveString = localStorage.getItem('backup_save');
if (saveString) {
  const slotId = await saveManager.importSave(saveString);
  console.log(`存档已导入到槽位 ${slotId}`);
}
```

##### `exportToJson(slotId: number): Promise<string>`

导出为格式化的 JSON 字符串（便于调试）。

---

#### 槽位管理

##### `getSlotInfos(): Promise<SaveSlotInfo[]>`

获取所有槽位信息。

**返回值:**
```typescript
interface SaveSlotInfo {
  slotId: number;           // 槽位ID
  exists: boolean;          // 是否存在存档
  timestamp: number | null; // 存档时间戳
  playTime: number | null;  // 游戏时长
  playerLevel: number | null; // 玩家等级
  currentLayer: number | null; // 当前层数
  thumbnail: string | null; // 缩略图
}
```

**示例:**
```typescript
const slots = await saveManager.getSlotInfos();
slots.forEach(slot => {
  if (slot.exists) {
    console.log(`槽位 ${slot.slotId}: 等级 ${slot.playerLevel}, 第 ${slot.currentLayer} 层`);
  }
});
```

##### `getSlotInfo(slotId: number): Promise<SaveSlotInfo>`

获取单个槽位信息。

##### `findEmptySlot(): Promise<number | null>`

查找第一个空槽位。

##### `findOldestSlot(): Promise<number>`

查找最旧的存档槽位。

---

#### 自动存档定时器

##### `startAutoSaveTimer(callback: () => Promise<SaveData>): void`

启动自动存档定时器。

**参数:**
- `callback`: 返回当前游戏状态的回调函数

**示例:**
```typescript
saveManager.startAutoSaveTimer(async () => {
  // 返回当前游戏状态
  return {
    player: getPlayerData(),
    world: getWorldData(),
    settings: getSettings(),
    statistics: getStatistics(),
  };
});
```

##### `stopAutoSaveTimer(): void`

停止自动存档定时器。

##### `triggerCheckpoint(data: SaveData): Promise<void>`

触发检查点存档。

---

#### 工具方法

##### `getStorageUsage(): Promise<{ used: number; quota: number | null }>`

获取存储使用情况。

**返回值:**
- `used`: 已使用字节数
- `quota`: 总配额（可能为 null）

##### `deleteAll(): Promise<void>`

删除所有存档（慎用）。

---

## 类型定义

### SaveData

存档数据结构。

```typescript
interface SaveData {
  version: string;        // 存档格式版本
  gameVersion: string;    // 游戏版本
  timestamp: number;      // 存档时间戳
  playTime: number;       // 游戏时长（秒）
  saveType: SaveType;     // 存档类型
  player: PlayerData;     // 玩家数据
  world: WorldData;       // 世界数据
  settings: GameSettings; // 游戏设置
  statistics: GameStatistics; // 游戏统计
}
```

### SaveType

存档类型枚举。

```typescript
enum SaveType {
  AUTO = 'auto',           // 自动存档
  MANUAL = 'manual',       // 手动存档
  CHECKPOINT = 'checkpoint', // 检查点
  QUIT = 'quit',           // 退出存档
}
```

### SaveError

存档错误类。

```typescript
class SaveError extends Error {
  type: SaveErrorType;
  originalError?: Error;
}

enum SaveErrorType {
  STORAGE_FULL = 'storage_full',
  CORRUPTED = 'corrupted',
  VERSION_MISMATCH = 'version_mismatch',
  PERMISSION_DENIED = 'permission_denied',
  NOT_FOUND = 'not_found',
  INVALID_DATA = 'invalid_data',
  UNKNOWN = 'unknown',
}
```

---

## 配置选项

### CreateSaveManagerOptions

```typescript
interface CreateSaveManagerOptions {
  storage?: StorageAdapter;      // 自定义存储适配器
  maxManualSlots?: number;       // 手动存档槽位数（默认5）
  maxAutoSaves?: number;         // 自动存档数量（默认3）
  enableEncryption?: boolean;    // 启用加密（默认true）
  encryptionKey?: string;        // 自定义加密密钥
  autoSaveInterval?: number;     // 自动存档间隔（分钟，默认5）
  version?: string;              // 存档格式版本
  gameVersion?: string;          // 游戏版本
}
```

---

## 存储适配器

### LocalStorageAdapter

使用浏览器 LocalStorage 存储。

**限制:**
- 容量约 5-10MB
- 同步 API
- 适合小型存档

### IndexedDBAdapter

使用浏览器 IndexedDB 存储。

**优势:**
- 容量更大（取决于浏览器）
- 异步 API
- 适合大型存档

### 自定义存储适配器

```typescript
import { StorageAdapter } from './save-system';

class CustomStorageAdapter implements StorageAdapter {
  async get(key: string): Promise<string | null> {
    // 实现读取
  }
  
  async set(key: string, value: string): Promise<void> {
    // 实现写入
  }
  
  async remove(key: string): Promise<void> {
    // 实现删除
  }
  
  async keys(): Promise<string[]> {
    // 实现列出所有键
  }
  
  async clear(): Promise<void> {
    // 实现清空
  }
  
  async getSize(): Promise<number> {
    // 实现获取已用空间
  }
  
  async getQuota(): Promise<number | null> {
    // 实现获取总配额
  }
}
```

---

## 完整示例

```typescript
import { 
  createSaveManager, 
  SaveManager, 
  SaveData, 
  SaveError, 
  SaveErrorType 
} from './save-system';

class Game {
  private saveManager: SaveManager;
  private currentState: SaveData;
  
  constructor() {
    this.saveManager = createSaveManager({
      maxManualSlots: 5,
      maxAutoSaves: 3,
      enableEncryption: true,
      autoSaveInterval: 5,
    });
    
    // 启动自动存档
    this.saveManager.startAutoSaveTimer(async () => this.currentState);
  }
  
  // 保存游戏
  async saveGame(slotId: number): Promise<boolean> {
    try {
      await this.saveManager.save(slotId, this.currentState);
      console.log(`游戏已保存到槽位 ${slotId}`);
      return true;
    } catch (e) {
      console.error('保存失败:', e);
      return false;
    }
  }
  
  // 加载游戏
  async loadGame(slotId: number): Promise<boolean> {
    try {
      this.currentState = await this.saveManager.load(slotId);
      console.log(`已从槽位 ${slotId} 加载游戏`);
      return true;
    } catch (e) {
      if (e instanceof SaveError) {
        if (e.type === SaveErrorType.NOT_FOUND) {
          console.log('存档不存在');
        } else if (e.type === SaveErrorType.CORRUPTED) {
          console.log('存档已损坏');
        }
      }
      return false;
    }
  }
  
  // 导出存档
  async exportSave(slotId: number): Promise<string | null> {
    try {
      return await this.saveManager.exportSave(slotId);
    } catch (e) {
      console.error('导出失败:', e);
      return null;
    }
  }
  
  // 导入存档
  async importSave(data: string): Promise<number | null> {
    try {
      const slotId = await this.saveManager.importSave(data);
      console.log(`存档已导入到槽位 ${slotId}`);
      return slotId;
    } catch (e) {
      console.error('导入失败:', e);
      return null;
    }
  }
  
  // 获取存档列表
  async getSaveList(): Promise<void> {
    const slots = await this.saveManager.getSlotInfos();
    slots.forEach(slot => {
      if (slot.exists) {
        const date = new Date(slot.timestamp!);
        console.log(`槽位 ${slot.slotId}: 等级 ${slot.playerLevel}, 第 ${slot.currentLayer} 层 (${date.toLocaleString()})`);
      } else {
        console.log(`槽位 ${slot.slotId}: 空`);
      }
    });
  }
}
```

---

## 注意事项

1. **存储空间**: LocalStorage 通常限制 5-10MB，大型存档请使用 IndexedDB
2. **加密**: 默认使用 XOR 加密，可防止简单篡改但不是绝对安全
3. **版本迁移**: 存档系统会自动处理版本不匹配，但建议在新版本发布时测试存档兼容性
4. **错误处理**: 所有异步方法都可能抛出 `SaveError`，请做好错误处理

---

## 更新日志

| 版本 | 日期 | 说明 |
|------|------|------|
| 1.0 | 2026-03-20 | 初始版本 |