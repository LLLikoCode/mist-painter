# 迷雾绘者 (Mist Painter) 架构分析报告

## 分析日期
2026-03-27

## 1. 当前架构概述

### 1.1 系统结构
```
src/
├── core/           # 核心数据模型
│   ├── Maze.ts     # 迷宫数据结构
│   ├── Player.ts   # 玩家实体
│   └── GameState.ts # 游戏状态管理
├── systems/        # 游戏系统
│   ├── VisionSystem.ts      # 视野系统
│   ├── LightSystem.ts       # 光源系统
│   ├── MemorySystem.ts      # 记忆衰退系统
│   ├── MarkSystem.ts        # 地图标记系统
│   ├── SaveSystem.ts        # 存档系统
│   ├── AchievementSystem.ts # 成就系统
│   ├── ClassSystem.ts       # 职业系统
│   ├── EventSystem.ts       # 事件系统
│   ├── InventorySystem.ts   # 背包系统
│   └── CollisionSystem.ts   # 碰撞检测
├── rendering/      # 渲染系统
│   ├── MazeRenderer.ts      # 迷宫渲染器
│   └── MapRenderer.ts       # 地图渲染器
├── input/          # 输入系统
│   └── InputHandler.ts      # 输入处理器
├── generation/     # 生成系统
│   └── MazeGenerator.ts     # 迷宫生成器
└── main.ts         # 游戏主类
```

## 2. 耦合度分析

### 2.1 高耦合区域识别

#### 🔴 严重耦合 - main.ts Game类
**问题描述：**
- Game类直接实例化并管理所有系统（12个系统）
- 直接调用各系统的具体方法，而非通过接口
- 包含游戏逻辑、状态管理、UI更新混合在一起
- 系统间的依赖关系隐藏在Game类内部

**耦合表现：**
```typescript
// Game类直接依赖具体实现
private visionSystem: VisionSystem;
private lightSystem: LightSystem;
private memorySystem: MemorySystem;
// ... 等等

// 在方法中直接调用各系统
this.visionSystem.updateVisibility(this.maze, this.player);
this.lightSystem.update(deltaTime);
this.memorySystem.update(this.player, this.player.layer);
```

#### 🔴 严重耦合 - Player与InventorySystem
**问题描述：**
- Player接口直接包含InventorySystem实例
- 创建Player时必须实例化InventorySystem
- 违反依赖倒置原则

**耦合表现：**
```typescript
export interface Player {
    // ...
    inventory: InventorySystem;  // 直接依赖具体类
}

export function createPlayer(startX: number, startY: number): Player {
    const inventory = new InventorySystem();  // 直接实例化
    // ...
}
```

#### 🟡 中度耦合 - 系统间的直接依赖

**VisionSystem → Maze, Player**
- 直接操作Maze.cells修改visible/discovered状态
- 应该通过事件或接口通知，而非直接修改

**LightSystem → Player**
- 直接修改player.visionRadius
- 应该返回计算结果，由调用方决定是否应用

**MemorySystem → Player**
- 直接操作player.drawnCells
- 应该通过接口方法操作

**SaveSystem → GameState, Player, Maze**
- 直接访问各对象的内部数据结构
- 应该通过序列化接口获取数据

#### 🟡 中度耦合 - 渲染器与核心模型

**MazeRenderer → Maze, Player**
- 直接访问maze.cells[y][x]的详细结构
- 直接读取player.x, player.y等属性

**MapRenderer → Player, Maze**
- 直接遍历player.drawnCells
- 直接访问Maze的CellType

### 2.2 依赖关系图

```
┌─────────────────────────────────────────────────────────────┐
│                          Game (main.ts)                      │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐            │
│  │ Vision  │ │ Light   │ │ Memory  │ │  Save   │ ...        │
│  │ System  │ │ System  │ │ System  │ │ System  │            │
│  └────┬────┘ └────┬────┘ └────┬────┘ └────┬────┘            │
│       │           │           │           │                  │
│       ▼           ▼           ▼           ▼                  │
│  ┌──────────────────────────────────────────────────┐       │
│  │              Maze, Player, GameState              │       │
│  └──────────────────────────────────────────────────┘       │
└─────────────────────────────────────────────────────────────┘

问题：Game类成为"上帝类"，所有系统都通过它协调
```

### 2.3 循环依赖风险

**当前未发现明显循环依赖，但存在潜在风险：**
- Player ↔ InventorySystem（Player创建InventorySystem）
- 如果未来添加物品影响玩家属性，可能形成循环

## 3. 耦合问题影响

### 3.1 可维护性问题
- 修改一个系统可能影响多个其他系统
- 难以进行单元测试（需要模拟大量依赖）
- 代码重复风险高

### 3.2 可扩展性问题
- 添加新系统需要修改Game类
- 无法独立替换某个系统的实现
- 难以实现插件化架构

### 3.3 性能问题
- Game类承担过多职责，可能成为性能瓶颈
- 不必要的依赖导致打包体积增大

## 4. 解耦策略

### 4.1 引入事件总线 (Event Bus)
- 系统间通过事件通信，而非直接调用
- 降低系统间的直接依赖

### 4.2 依赖注入 (Dependency Injection)
- 通过构造函数注入依赖
- 支持接口/抽象类注入，而非具体实现

### 4.3 服务定位器 (Service Locator)
- 集中管理系统实例
- 按需获取系统引用

### 4.4 组件化架构
- 将Player、Maze等改为组件化设计
- 通过组件系统动态组合功能

## 5. 重构优先级

| 优先级 | 模块 | 问题 | 影响范围 |
|--------|------|------|----------|
| P0 | main.ts Game类 | 上帝类，管理所有系统 | 全局 |
| P0 | Player-Inventory | 直接实例化依赖 | Player, Inventory |
| P1 | VisionSystem | 直接修改Maze状态 | Vision, Maze |
| P1 | SaveSystem | 直接访问内部数据 | Save, 所有数据类 |
| P2 | Renderers | 直接访问模型细节 | Rendering |
| P2 | LightSystem | 直接修改Player属性 | Light, Player |

## 6. 推荐架构模式

### 6.1 ECS (Entity-Component-System)
适合游戏开发，但改动较大

### 6.2 事件驱动架构
- 保持现有类结构
- 添加事件总线解耦系统间通信
- **推荐方案**

### 6.3 依赖注入容器
- 使用IoC容器管理依赖
- 支持更好的测试性

## 7. 向后兼容策略

- 保持现有API不变
- 新接口与旧接口并存
- 逐步迁移，而非一次性重写
- 添加适配器层
