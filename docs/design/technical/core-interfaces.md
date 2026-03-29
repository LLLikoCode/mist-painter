# 迷雾绘者 - 核心模块接口设计草案

> **版本**: v1.0  
> **创建时间**: 2026-03-22  
> **文档类型**: 接口设计规范

---

## 目录

1. [Core 模块接口](#1-core-模块接口)
2. [Game 模块接口](#2-game-模块接口)
3. [UI 模块接口](#3-ui-模块接口)
4. [事件系统接口](#4-事件系统接口)

---

## 1. Core 模块接口

### 1.1 Game - 游戏主类

```typescript
// src/core/Game.ts
export interface GameConfig {
  width: number;
  height: number;
  backgroundColor: number;
  antialias?: boolean;
  resolution?: number;
  autoDensity?: boolean;
}

export class Game {
  public static getInstance(): Game;
  public static create(config: GameConfig): Game;
  
  public async init(): Promise<void>;
  public start(): void;
  public pause(): void;
  public resume(): void;
  public stop(): void;
  public destroy(): void;
  
  public getIsRunning(): boolean;
  public getIsPaused(): boolean;
}
```

### 1.2 SceneManager - 场景管理器

```typescript
// src/core/SceneManager.ts
export interface Scene {
  readonly name: string;
  enter(params?: Record<string, any>): void | Promise<void>;
  exit(): void | Promise<void>;
  update(deltaTime: number): void;
  render(): void;
  destroy(): void;
}

export class SceneManager {
  public register(name: string, scene: Scene): void;
  public async changeScene(name: string, params?: Record<string, any>): Promise<void>;
  public async pushScene(name: string, params?: Record<string, any>): Promise<void>;
  public async popScene(): Promise<Scene | undefined>;
  public getCurrentScene(): Scene | null;
  public update(deltaTime: number): void;
  public render(): void;
}
```

### 1.3 InputManager - 输入管理器

```typescript
// src/core/InputManager.ts
export type KeyCode = string;
export interface PointerPosition { x: number; y: number; }

export class InputManager {
  public init(canvas: HTMLCanvasElement): void;
  public isKeyPressed(key: KeyCode): boolean;
  public getPointerPosition(): PointerPosition;
  public isPointerDown(): boolean;
  public on(event: string, callback: Function): void;
  public off(event: string, callback: Function): void;
}
```

### 1.4 AudioManager - 音频管理器

```typescript
// src/core/AudioManager.ts
export class AudioManager {
  public init(): void;
  public playBGM(id: string, fadeDuration?: number): void;
  public stopBGM(fadeDuration?: number): void;
  public playSFX(id: string, options?: { volume?: number }): number;
  public setMasterVolume(volume: number): void;
  public mute(): void;
  public unmute(): void;
}
```

### 1.5 ResourceManager - 资源管理器

```typescript
// src/core/ResourceManager.ts
export class ResourceManager {
  public register(id: string, config: ResourceConfig): void;
  public async load<T>(id: string): Promise<T>;
  public get<T>(id: string): T | undefined;
  public release(id: string): void;
  public clear(): void;
}
```

### 1.6 EventBus - 事件总线

```typescript
// src/core/EventBus.ts
export class EventBus {
  public on<T>(event: string, callback: (data: T) => void): void;
  public once<T>(event: string, callback: (data: T) => void): void;
  public off(event: string, callback: Function): void;
  public emit<T>(event: string, data?: T): void;
  public clear(): void;
}
```

---

## 2. Game 模块接口

### 2.1 Entity - 实体基类

```typescript
// src/game/entities/Entity.ts
export class Entity {
  public readonly id: string;
  public addComponent<T extends Component>(component: T): T;
  public getComponent<T extends Component>(type: string): T | undefined;
  public hasComponent(type: string): boolean;
  public removeComponent(type: string): void;
  public update(deltaTime: number): void;
  public destroy(): void;
}
```

### 2.2 Component - 组件基类

```typescript
// src/game/components/Component.ts
export abstract class Component {
  public abstract readonly type: string;
  public entity: Entity | null = null;
  public enabled: boolean = true;
  
  public onAttach(): void;
  public onDetach(): void;
  public update(deltaTime: number): void;
}

// Transform 组件
export class Transform extends Component {
  public readonly type = 'Transform';
  public x: number = 0;
  public y: number = 0;
  public setPosition(x: number, y: number): void;
}

// Sprite 组件
export class Sprite extends Component {
  public readonly type = 'Sprite';
  public setTexture(texture: Texture): void;
}
```

### 2.3 System - 系统基类

```typescript
// src/game/systems/System.ts
export abstract class System {
  public readonly priority: number = 0;
  public addEntity(entity: Entity): void;
  public removeEntity(entity: Entity): void;
  public update(deltaTime: number): void;
  
  protected abstract processEntity(entity: Entity, deltaTime: number): void;
}
```

### 2.4 Map - 地图系统

```typescript
// src/game/map/Map.ts
export interface Tile {
  x: number; y: number;
  type: 'wall' | 'floor' | 'entrance' | 'exit';
  walkable: boolean;
}

export class Map {
  public generate(): void;
  public getTile(x: number, y: number): Tile | undefined;
  public isWalkable(x: number, y: number): boolean;
  public revealFog(x: number, y: number, radius: number): void;
  public findPath(sx: number, sy: number, ex: number, ey: number): Array<{x: number; y: number}>;
}
```

### 2.5 SaveManager - 存档管理

```typescript
// src/game/save/SaveManager.ts
export interface SaveData {
  version: string;
  timestamp: number;
  player: PlayerData;
  map: MapData;
  inventory: InventoryData;
}

export class SaveManager {
  public static readonly MAX_SLOTS: number = 3;
  
  public async save(slot: number, data: SaveData): Promise<boolean>;
  public async load(slot: number): Promise<SaveData | null>;
  public async delete(slot: number): Promise<boolean>;
  public hasSave(slot: number): boolean;
}
```

### 2.6 Inventory - 背包系统

```typescript
// src/game/inventory/Inventory.ts
export interface Item {
  id: string;
  name: string;
  type: string;
  quantity: number;
}

export class Inventory {
  public capacity: number = 20;
  
  public addItem(item: Item): boolean;
  public removeItem(itemId: string, quantity?: number): boolean;
  public getItem(itemId: string): Item | undefined;
  public getAllItems(): Item[];
  public isFull(): boolean;
  public clear(): void;
}
```

---

## 3. UI 模块接口

### 3.1 Screen - 界面基类

```typescript
// src/ui/screens/BaseScreen.ts
export abstract class BaseScreen {
  public readonly name: string;
  public container: Container;
  
  public abstract enter(): void;
  public abstract exit(): void;
  public update(deltaTime: number): void;
  public resize(width: number, height: number): void;
  public destroy(): void;
}
```

### 3.2 HUD - 游戏内界面

```typescript
// src/ui/hud/HUD.ts
export class HUD {
  public init(): void;
  public show(): void;
  public hide(): void;
  public updateHealth(current: number, max: number): void;
  public showMessage(text: string, duration?: number): void;
  public destroy(): void;
}
```

### 3.3 DialogBox - 对话框

```typescript
// src/ui/components/DialogBox.ts
export class DialogBox {
  public show(text: string, speaker?: string): void;
  public hide(): void;
  public isVisible(): boolean;
  public onComplete(callback: () => void): void;
}
```

---

## 4. 事件系统接口

### 4.1 游戏事件定义

```typescript
// src/types/events.ts
export const GameEvents = {
  // 游戏生命周期
  GAME_START: 'game:start',
  GAME_PAUSE: 'game:pause',
  GAME_RESUME: 'game:resume',
  GAME_OVER: 'game:over',
  
  // 玩家事件
  PLAYER_MOVE: 'player:move',
  PLAYER_INTERACT: 'player:interact',
  PLAYER_DAMAGE: 'player:damage',
  PLAYER_HEAL: 'player:heal',
  
  // 地图事件
  MAP_EXPLORE: 'map:explore',
  FOG_REVEAL: 'fog:reveal',
  ROOM_ENTER: 'room:enter',
  
  // 战斗事件
  COMBAT_START: 'combat:start',
  COMBAT_END: 'combat:end',
  ENEMY_DEFEAT: 'enemy:defeat',
  
  // 谜题事件
  PUZZLE_START: 'puzzle:start',
  PUZZLE_SOLVE: 'puzzle:solve',
  
  // UI事件
  UI_OPEN: 'ui:open',
  UI_CLOSE: 'ui:close',
  DIALOG_SHOW: '