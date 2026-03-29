# 技术实现方案

> 技术选型、架构设计和核心代码示例。

---

## 1. 技术栈选择

### 1.1 推荐方案

```yaml
Web版本 (推荐入门):
  引擎: HTML5 Canvas + TypeScript
  渲染: Pixi.js 或原生Canvas API
  状态管理: 自定义或 Redux
  存储: LocalStorage / IndexedDB
  优势: 跨平台，易于分享，开发快速

桌面版本:
  引擎: Godot (开源) 或 Unity
  语言: GDScript / C#
  优势: 更好的性能，原生体验

移动版本:
  引擎: React Native + Canvas
  或: Flutter + CustomPainter
  优势: 触屏优化，便携
```

### 1.2 本项目采用

**Web版本 (HTML5 + TypeScript)**
- 易于老师随时预览和修改
- 无需安装，浏览器即可运行
- 方便分享和测试

---

## 2. 项目结构

```
maze-game/
├── src/
│   ├── core/                    # 核心系统
│   │   ├── Maze.ts             # 迷宫数据结构和生成
│   │   ├── Player.ts           # 玩家状态和属性
│   │   ├── MapDrawing.ts       # 地图绘制系统
│   │   └── GameState.ts        # 游戏状态管理
│   │
│   ├── generation/              # 生成算法
│   │   ├── RecursiveBacktracker.ts
│   │   ├── RoomInserter.ts
│   │   ├── SpecialFeatures.ts
│   │   └── DynamicMaze.ts
│   │
│   ├── systems/                 # 游戏系统
│   │   ├── VisionSystem.ts     # 视野系统
│   │   ├── MemorySystem.ts     # 记忆衰退
│   │   ├── InventorySystem.ts  # 背包系统
│   │   ├── LightSystem.ts      # 光源系统
│   │   └── StaminaSystem.ts    # 体力系统
│   │
│   ├── rendering/               # 渲染
│   │   ├── MazeRenderer.ts     # 迷宫渲染
│   │   ├── MapRenderer.ts      # 地图界面渲染
│   │   ├── UIRenderer.ts       # UI渲染
│   │   └── Effects.ts          # 特效
│   │
│   ├── input/                   # 输入处理
│   │   ├── KeyboardInput.ts
│   │   ├── MouseInput.ts
│   │   └── TouchInput.ts
│   │
│   ├── utils/                   # 工具
│   │   ├── Random.ts           # 随机数（含种子）
│   │   ├── Pathfinding.ts      # 寻路
│   │   └── SaveLoad.ts         # 存档
│   │
│   └── main.ts                  # 入口
│
├── assets/                      # 资源
│   ├── images/
│   ├── sounds/
│   └── fonts/
│
├── docs/                        # 文档
├── index.html
├── package.json
└── tsconfig.json
```

---

## 3. 核心数据结构

### 3.1 迷宫单元格

```typescript
// src/core/Maze.ts

export enum CellType {
  WALL = 0,
  PATH = 1,
  ROOM = 2,
  ENTRANCE = 3,
  EXIT = 4,
  STAIRS_UP = 5,
  STAIRS_DOWN = 6,
  SECRET_DOOR = 7,
  TELEPORTER = 8,
  TRAP = 9,
}

export interface Cell {
  x: number;
  y: number;
  type: CellType;
  
  // 视觉
  discovered: boolean;      // 是否被发现过
  visible: boolean;         // 当前是否可见
  
  // 特殊属性
  isOneWay: boolean;
  oneWayDir: Direction | null;
  teleporterId: string | null;
  roomId: string | null;
  
  // 动态迷宫
  isShifting: boolean;      // 是否会移动
  shiftTimer: number;       // 变化计时
}

export interface Maze {
  width: number;
  height: number;
  layer: number;
  cells: Cell[][];
  rooms: Room[];
  entrance: Point;
  exit: Point;
  seed: string;
}
```

### 3.2 玩家数据

```typescript
// src/core/Player.ts

export interface Player {
  // 位置
  x: number;
  y: number;
  layer: number;
  direction: Direction;
  
  // 属性
  level: number;
  exp: number;
  
  // 资源
  stamina: number;
  maxStamina: number;
  
  // 装备
  equippedTool: DrawingTool | null;
  lightSource: LightSource | null;
  
  // 背包
  inventory: Inventory;
  
  // 地图绘制
  drawnMaps: Map<number, PlayerMap>;  // layer -> map
}

export interface PlayerMap {
  layer: number;
  cells: Map<string, DrawnCell>;  // key: "x,y"
  lastVisited: Map<string, number>; // 上次访问时间戳
  paperType: PaperType;
  marks: MapMark[];
}

export interface DrawnCell {
  x: number;
  y: number;
  drawnType: CellType;      // 玩家绘制的类型
  accuracy: number;         // 准确度 0-1
  timestamp: number;        // 绘制时间
  toolUsed: ToolType;       // 使用的工具
}
```

### 3.3 绘制工具

```typescript
// src/systems/InventorySystem.ts

export enum ToolType {
  PENCIL = 'pencil',
  QUILL = 'quill',
  SURVEYOR = 'surveyor',
  SCROLL = 'scroll',
}

export interface DrawingTool {
  type: ToolType;
  name: string;
  durability: number;
  maxDurability: number;
  accuracy: number;         // 误差率修正
  speed: number;            // 绘制速度
  erasable: boolean;        // 是否可修改
}

export const TOOL_DEFINITIONS: Record<ToolType, Omit<DrawingTool, 'durability'>> = {
  [ToolType.PENCIL]: {
    type: ToolType.PENCIL,
    name: '探险者铅笔',
    maxDurability: 100,
    accuracy: 0.85,         // 15%误差
    speed: 1.0,
    erasable: true,
  },
  [ToolType.QUILL]: {
    type: ToolType.QUILL,
    name: '学者羽毛笔',
    maxDurability: 50,
    accuracy: 0.95,         // 5%误差
    speed: 0.6,
    erasable: false,
  },
  [ToolType.SURVEYOR]: {
    type: ToolType.SURVEYOR,
    name: '精密测绘仪',
    maxDurability: Infinity,
    accuracy: 0.99,         // 1%误差
    speed: 0.2,
    erasable: false,
  },
  [ToolType.SCROLL]: {
    type: ToolType.SCROLL,
    name: '记忆卷轴',
    maxDurability: 1,
    accuracy: 1.0,          // 100%准确
    speed: 5.0,
    erasable: false,
  },
};
```

---

## 4. 核心系统实现

### 4.1 迷宫生成器

```typescript
// src/generation/RecursiveBacktracker.ts

import { Maze, Cell, CellType } from '../core/Maze';
import { SeededRandom } from '../utils/Random';

export class MazeGenerator {
  private rng: SeededRandom;
  
  constructor(seed?: string) {
    this.rng = new SeededRandom(seed);
  }
  
  generate(width: number, height: number): Maze {
    // 确保奇数尺寸
    const w = width % 2 === 0 ? width + 1 : width;
    const h = height % 2 === 0 ? height + 1 : height;
    
    // 初始化全为墙
    const cells: Cell[][] = [];
    for (let y = 0; y < h; y++) {
      cells[y] = [];
      for (let x = 0; x < w; x++) {
        cells[y][x] = this.createCell(x, y, CellType.WALL);
      }
    }
    
    // 递归回溯
    const startX = this.rng.nextInt(1, w - 2, 2);
    const startY = this.rng.nextInt(1, h - 2, 2);
    
    const stack: Point[] = [{ x: startX, y: startY }];
    cells[startY][startX].type = CellType.PATH;
    
    while (stack.length > 0) {
      const current = stack[stack.length - 1];
      const neighbors = this.getUnvisitedNeighbors(current, cells, w, h);
      
      if (neighbors.length > 0) {
        const next = neighbors[this.rng.nextInt(0, neighbors.length - 1)];
        
        // 打通墙壁
        const wallX = (current.x + next.x) / 2;
        const wallY = (current.y + next.y) / 2;
        cells[wallY][wallX].type = CellType.PATH;
        cells[next.y][next.x].type = CellType.PATH;
        
        stack.push(next);
      } else {
        stack.pop();
      }
    }
    
    // 设置入口和出口
    const entrance = this.findFarthestPoint(cells, { x: startX, y: startY });
    const exit = this.findFarthestPoint(cells, entrance);
    
    cells[entrance.y][entrance.x].type = CellType.ENTRANCE;
    cells[exit.y][exit.x].type = CellType.EXIT;
    
    return {
      width: w,
      height: h,
      layer: 1,
      cells,
      rooms: [],
      entrance,
      exit,
      seed: this.rng.seed,
    };
  }
  
  private createCell(x: number, y: number, type: CellType): Cell {
    return {
      x, y, type,
      discovered: false,
      visible: false,
      isOneWay: false,
      oneWayDir: null,
      teleporterId: null,
      roomId: null,
      isShifting: false,
      shiftTimer: 0,
    };
  }
  
  private getUnvisitedNeighbors(p: Point, cells: Cell[][], w: number, h: number): Point[] {
    const neighbors: Point[] = [];
    const dirs = [{ x: 0, y: -2 }, { x: 2, y: 0 }, { x: 0, y: 2 }, { x: -2, y: 0 }];
    
    for (const dir of dirs) {
      const nx = p.x + dir.x;
      const ny = p.y + dir.y;
      
      if (nx > 0 && nx < w - 1 && ny > 0 && ny < h - 1) {
        if (cells[ny][nx].type === CellType.WALL) {
          neighbors.push({ x: nx, y: ny });
        }
      }
    }
    
    return neighbors;
  }
  
  private findFarthestPoint(cells: Cell[][], start: Point): Point {
    // BFS找最远点
    const queue: Point[] = [start];
    const visited = new Set<string>([`${start.x},${start.y}`]);
    let farthest = start;
    
    while (queue.length > 0) {
      const current = queue.shift()!;
      farthest = current;
      
      const dirs = [{ x: 0, y: -1 }, { x: 1, y: 0 }, { x: 0, y: 1 }, { x: -1, y: 0 }];
      for (const dir of dirs) {
        const nx = current.x + dir.x;
        const ny = current.y + dir.y;
        const key = `${nx},${ny}`;
        
        if (!visited.has(key) && cells[ny]?.[nx]?.type !== CellType.WALL) {
          visited.add(key);
          queue.push({ x: nx, y: ny });
        }
      }
    }
    
    return farthest;
  }
}
```

### 4.2 视野系统

```typescript
// src/systems/VisionSystem.ts

import { Maze, Cell } from '../core/Maze';
import { Player } from '../core/Player';

export class VisionSystem {
  private lightRadius: number = 3;
  
  updateVisibility(maze: Maze, player: Player): void {
    // 重置可见性
    for (const row of maze.cells) {
      for (const cell of row) {
        cell.visible = false;
      }
    }
    
    // 计算光源加成
    const lightBonus = player.lightSource ? player.lightSource.radiusBonus : 0;
    const totalRadius = this.lightRadius + lightBonus;
    
    // 使用阴影投射算法
    this.castShadows(maze, player.x, player.y, totalRadius);
  }
  
  private castShadows(maze: Maze, px: number, py: number, radius: number): void {
    // 简单的圆形视野（可优化为阴影投射）
    for (let y = py - radius; y <= py + radius; y++) {
      for (let x = px - radius; x <= px + radius; x++) {
        if (y >= 0 && y < maze.height && x >= 0 && x < maze.width) {
          const distance = Math.sqrt((x - px) ** 2 + (y - py) ** 2);
          if (distance <= radius) {
            const cell = maze.cells[y][x];
            cell.visible = true;
            cell.discovered = true;
          }
        }
      }
    }
  }
}
```

### 4.3 记忆衰退系统

```typescript
// src/systems/MemorySystem.ts

import { PlayerMap, DrawnCell } from '../core/Player';

export class MemorySystem {
  private decayRates: Record<number, number> = {
    1: 0.05,    // 表层: 5% / 分钟
    2: 0.08,    // 中层: 8% / 分钟
    3: 0.12,    // 深层: 12% / 分钟
    4: 0.20,    // 混沌: 20% / 分钟
  };
  
  updateMemory(playerMap: PlayerMap, deltaTimeMinutes: number): void {
    const now = Date.now();
    const decayRate = this.decayRates[playerMap.layer] || 0.05;
    
    for (const [key, cell] of playerMap.cells) {
      const timeSinceVisit = (now - cell.timestamp) / 60000; // 分钟
      const lastVisitTime = playerMap.lastVisited.get(key) || 0;
      const timeSinceLastVisit = (now - lastVisitTime) / 60000;
      
      if (timeSinceLastVisit > 0) {
        // 计算衰退
        const decay = timeSinceLastVisit * decayRate;
        cell.accuracy = Math.max(0, cell.accuracy - decay);
        
        // 如果完全遗忘，可选择保留轮廓或完全删除
        if (cell.accuracy <= 0.2) {
          // 保留但不准确
          cell.accuracy = 0.2;
        }
      }
    }
  }
  
  // 访问某个格子，刷新记忆
  refreshMemory(playerMap: PlayerMap, x: number, y: number): void {
    const key = `${x},${y}`;
    playerMap.lastVisited.set(key, Date.now());
    
    const cell = playerMap.cells.get(key);
    if (cell) {
      // 重新确认，略微提升准确度
      cell.accuracy = Math.min(1, cell.accuracy + 0.1);
    }
  }
}
```

---

## 5. 渲染系统

### 5.1 迷宫渲染

```typescript
// src/rendering/MazeRenderer.ts

import { Maze, Cell, CellType } from '../core/Maze';

export class MazeRenderer {
  private ctx: CanvasRenderingContext2D;
  private cellSize: number = 32;
  
  constructor(canvas: HTMLCanvasElement) {
    this.ctx = canvas.getContext('2d')!;
  }
  
  render(maze: Maze, viewport: Viewport): void {
    this.ctx.clearRect(0, 0, this.ctx.canvas.width, this.ctx.canvas.height);
    
    const startX = Math.floor(viewport.x / this.cellSize);
    const startY = Math.floor(viewport.y / this.cellSize);
    const endX = startX + Math.ceil(viewport.width / this.cellSize) + 1;
    const endY = startY + Math.ceil(viewport.height / this.cellSize) + 1;
    
    for (let y = startY; y < endY && y < maze.height; y++) {
      for (let x = startX; x < endX && x < maze.width; x++) {
        if (y >= 0 && x >= 0) {
          this.renderCell(maze.cells[y][x], x, y);
        }
      }
    }
  }
  
  private renderCell(cell: Cell, x: number, y: number): void {
    const px = x * this.cellSize;
    const py = y * this.cellSize;
    
    // 未发现的区域
    if (!cell.discovered) {
      this.ctx.fillStyle = '#0a0a0a';
      this.ctx.fillRect(px, py, this.cellSize, this.cellSize);
      return;
    }
    
    // 根据类型绘制
    switch (cell.type) {
      case CellType.WALL:
        this.ctx.fillStyle = cell.visible ? '#444' : '#222';
        break;
      case CellType.PATH:
        this.ctx.fillStyle = cell.visible ? '#d4c4a8' : '#8b7d6b';
        break;
      case CellType.ENTRANCE:
        this.ctx.fillStyle = '#4a4';
        break;
      case CellType.EXIT:
        this.ctx.fillStyle = '#a44';
        break;
      default:
        this.ctx.fillStyle = '#888';
    }
    
    this.ctx.fillRect(px, py, this.cellSize, this.cellSize);
    
    // 绘制网格线
    this.ctx.strokeStyle = '#000';
    this.ctx.lineWidth = 0.5;
    this.ctx.strokeRect(px, py, this.cellSize, this.cellSize);
  }
}
```

### 5.2 地图绘制界面

```typescript
// src/rendering/MapRenderer.ts

import { PlayerMap, DrawnCell } from '../core/Player';

export class MapRenderer {
  private ctx: CanvasRenderingContext2D;
  private paperTexture: HTMLImageElement;
  
  constructor(canvas: HTMLCanvasElement) {
    this.ctx = canvas.getContext('2d')!;
    // 加载羊皮纸纹理
  }
  
  render(playerMap: PlayerMap): void {
    // 绘制背景（羊皮纸）
    this.drawPaperBackground();
    
    // 绘制已记录的格子
    for (const [key, cell] of playerMap.cells) {
      this.drawMapCell(cell);
    }
    
    // 绘制标记
    for (const mark of playerMap.marks) {
      this.drawMark(mark);
    }
    
    // 绘制玩家当前位置
    this.drawPlayerPosition();
  }
  
  private drawMapCell(cell: DrawnCell): void {
    const px = cell.x * 20 + 50;  // 地图缩放比例不同
    const py = cell.y * 20 + 50;
    
    // 根据准确度调整透明度
    const alpha = 0.3 + cell.accuracy * 0.7;
    this.ctx.globalAlpha = alpha;
    
    // 根据工具有不同的笔触效果
    switch (cell.toolUsed) {
      case 'pencil':
        this.drawPencilStroke(px, py, cell.drawnType);
        break;
      case 'quill':
        this.drawInkStroke(px, py, cell.drawnType);
        break;
      case 'surveyor':
        this.drawPreciseLine(px, py, cell.drawnType);
        break;
    }
    
    this.ctx.globalAlpha = 1;
  }
  
  private drawPencilStroke(x: number, y: number, type: CellType): void {
    // 铅笔效果：略带抖动，灰色
    this.ctx.strokeStyle = '#666';
    this.ctx.lineWidth = 1;
    this.ctx.lineCap = 'round';
    
    // 添加轻微随机抖动模拟手绘
    const jitter = () => (Math.random() - 0.5) * 2;
    
    this.ctx.beginPath();
    this.ctx.moveTo(x + jitter(), y + jitter());
    this.ctx.lineTo(x + 20 + jitter(), y + jitter());
    this.ctx.lineTo(x + 20 + jitter(), y + 20 + jitter());
    this.ctx.lineTo(x + jitter(), y + 20 + jitter());
    this.ctx.closePath();
    this.ctx.stroke();
  }
  
  private drawInkStroke(x: number, y: number, type: CellType): void {
    // 墨水效果：深色，流畅
    this.ctx.strokeStyle = '#1a1a1a';
    this.ctx.lineWidth = 1.5;
    this.ctx.strokeRect(x, y, 20, 20);
  }
  
  private drawPreciseLine(x: number, y: number, type: CellType): void {
    // 测绘仪效果：精确，可能有测量标记
    this.ctx.strokeStyle = '#000';
    this.ctx.lineWidth = 1;
    this.ctx.strokeRect(x, y, 20, 20);
    
    // 添加测量标记
    this.ctx.fillStyle = '#000';
    this.ctx.fillRect(x + 8, y + 8, 4, 4);
  }
}
```

---

## 6. 存档系统

```typescript
// src/utils/SaveLoad.ts

import { Player } from '../core/Player';
import { Maze } from '../core/Maze';

export interface SaveData {
  version: string;
  timestamp: number;
  player: Player;
  currentMaze: Maze;
  exploredLayers: Record<number, Maze>;
}

export class SaveManager {
  private readonly SAVE_KEY = 'maze_game_save';
  private readonly VERSION = '1.0';
  
  save(data: SaveData): void {
    const saveData: SaveData = {
      ...data,
      version: this.VERSION,
      timestamp: Date.now(),
    };
    
    const json = JSON.stringify(saveData);
    localStorage.setItem(this.SAVE_KEY, json);
  }
  
  load(): SaveData | null {
    const json = localStorage.getItem(this.SAVE_KEY);
    if (!json) return null;
    
    try {
      const data = JSON.parse(json) as SaveData;
      
      // 版本检查
      if (data.version !== this.VERSION) {
        console.warn('存档版本不匹配，尝试迁移...');
        return this.migrate(data);
      }
      
      return data;
    } catch (e) {
      console.error('存档损坏:', e);
      return null;
    }
  }
  
  private migrate(oldData: SaveData): SaveData {
    // 版本迁移逻辑
    return oldData;
  }
  
  delete(): void {
    localStorage.removeItem(this.SAVE_KEY);
  }
  
  export(): string {
    const data = localStorage.getItem(this.SAVE_KEY);
    return data ? btoa(data) : '';
  }
  
  import(base64: string): boolean {
    try {
      const json = atob(base64);
      JSON.parse(json); // 验证
      localStorage.setItem(this.SAVE_KEY, json);
      return true;
    } catch (e) {
      return false;
    }
  }
}
```

---

## 7. 开发路线图

### Phase 1: 核心原型 (1-2周)
- [ ] 基础迷宫生成
- [ ] 玩家移动
- [ ] 基础视野系统
- [ ] 简单地图绘制

### Phase 2: 核心玩法 (2-3周)
- [ ] 完整地图绘制系统
- [ ] 工具系统
- [ ] 记忆衰退
- [ ] 光源系统
- [ ] 体力系统

### Phase 3: 内容丰富 (2-3周)
- [ ] 房间生成
- [ ] 特殊地形
- [ ] 物品系统
- [ ] 存档系统

### Phase 4: 进阶功能 (2周)
- [ ] 动态迷宫
- [ ] 多层迷宫
- [ ] 音效音乐
- [ ]  polish

### Phase 5: 扩展 (可选)
- [ ] 多人模式
- [ ] 创意工坊
- [ ] 移动端适配

---

*"好的架构是游戏能持续迭代的基础。"*
