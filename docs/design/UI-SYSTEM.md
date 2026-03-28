# 迷雾绘者 (Mist Painter) - UI系统设计文档

> **版本**: v1.0  
> **创建时间**: 2026-03-22  
> **最后更新**: 2026-03-22  
> **文档类型**: 技术设计文档  
> **任务ID**: TASK-005

---

## 目录

1. [概述](#1-概述)
2. [UI系统架构](#2-ui系统架构)
3. [核心模块设计](#3-核心模块设计)
4. [屏幕管理系统](#4-屏幕管理系统)
5. [层级管理系统](#5-层级管理系统)
6. [主题与样式系统](#6-主题与样式系统)
7. [动画系统](#7-动画系统)
8. [输入与导航](#8-输入与导航)
9. [性能优化](#9-性能优化)
10. [文件结构](#10-文件结构)

---

## 1. 概述

### 1.1 设计目标

为"迷雾绘者"冒险解谜游戏设计一套基于 **PixiJS v8 + TypeScript + Zustand** 的完整UI系统：

- **沉浸感**: UI风格与游戏美术风格（手绘水彩+羊皮纸质感）高度统一
- **易用性**: 操作直观，反馈明确，学习成本低
- **响应式**: 适配多种屏幕尺寸和分辨率（桌面端+移动端）
- **模块化**: 组件可复用，易于维护和扩展
- **性能**: 优化渲染性能，确保流畅体验（目标60fps）

### 1.2 技术栈

| 技术 | 版本 | 用途 |
|------|------|------|
| PixiJS | v8.x | 2D渲染引擎 |
| TypeScript | 5.x | 类型安全 |
| Zustand | 4.x | UI状态管理 |
| GSAP | 3.x | 复杂动画（可选） |
| Vite | 5.x | 构建工具 |

### 1.3 设计原则

```
┌─────────────────────────────────────────────────────────────┐
│                    UI设计核心原则                           │
├─────────────────────────────────────────────────────────────┤
│ 1. 组件化: 每个UI元素都是独立的、可复用的组件              │
│ 2. 声明式: 通过状态驱动UI，而非命令式操作                  │
│ 3. 响应式: 自动适配不同屏幕尺寸和输入方式                  │
│ 4. 无障碍: 支持键盘导航、屏幕阅读器（基础支持）            │
│ 5. 一致性: 统一的视觉风格、交互模式、动画规范              │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. UI系统架构

### 2.1 整体架构

```
┌─────────────────────────────────────────────────────────────┐
│                    Application Layer                        │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐ │
│  │  MainMenu   │  │   GameHUD   │  │   SettingsMenu      │ │
│  │   Screen    │  │   Screen    │  │      Screen         │ │
│  └─────────────┘  └─────────────┘  └─────────────────────┘ │
├─────────────────────────────────────────────────────────────┤
│                    Screen Layer                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              ScreenManager (屏幕管理器)              │   │
│  │  - 管理屏幕生命周期                                  │   │
│  │  - 处理屏幕切换和过渡                                │   │
│  │  - 维护屏幕历史栈                                    │   │
│  └─────────────────────────────────────────────────────┘   │
├─────────────────────────────────────────────────────────────┤
│                    Component Layer                          │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────────┐   │
│  │  Button  │ │  Panel   │ │  Slider  │ │  DialogBox   │   │
│  │  Label   │ │Progress  │ │  Toast   │ │  ...         │   │
│  └──────────┘ └──────────┘ └──────────┘ └──────────────┘   │
├─────────────────────────────────────────────────────────────┤
│                    Layer Management                         │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────────┐   │
│  │  Scene   │ │   HUD    │ │  Popup   │ │   Overlay    │   │
│  │  Layer   │ │  Layer   │ │  Layer   │ │   Layer      │   │
│  │ z: 0     │ │ z: 100   │ │ z: 200   │ │   z: 300     │   │
│  └──────────┘ └──────────┘ └──────────┘ └──────────────┘   │
├─────────────────────────────────────────────────────────────┤
│                    Core Systems                             │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────────┐    │
│  │ ThemeManager │ │InputManager  │ │AnimationManager  │    │
│  │   (主题)     │ │  (输入)      │ │    (动画)        │    │
│  └──────────────┘ └──────────────┘ └──────────────────┘    │
├─────────────────────────────────────────────────────────────┤
│                    State Management (Zustand)               │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────────┐    │
│  │   UIStore    │ │  GameStore   │ │  ConfigStore     │    │
│  │  (UI状态)    │ │  (游戏状态)  │ │  (配置状态)      │    │
│  └──────────────┘ └──────────────┘ └──────────────────┘    │
├─────────────────────────────────────────────────────────────┤
│                    Rendering (PixiJS)                       │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              Pixi Application                       │   │
│  │  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌──────────┐  │   │
│  │  │ Stage   │ │Renderer │ │ Ticker  │ │  Events  │  │   │
│  │  └─────────┘ └─────────┘ └─────────┘ └──────────┘  │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 与ECS架构的集成

```typescript
// UI系统与ECS的交互方式
interface ECSUIIntegration {
  // UI订阅ECS事件
  subscribeToEvents(): void;
  
  // UI触发ECS动作
  dispatchGameAction(action: GameAction): void;
  
  // 游戏状态同步到UI
  syncGameStateToUI(state: GameState): void;
}

// 具体集成点
const integrationPoints = {
  // 玩家生命值变化 → 更新HUD血条
  'player:health_changed': (health: number, maxHealth: number) => {
    useHUDStore.getState().setHealth(health, maxHealth);
  },
  
  // 获得物品 → 显示获得提示
  'inventory:item_acquired': (item: Item) => {
    useUIStore.getState().showToast(`获得: ${item.name}`);
  },
  
  // 谜题完成 → 显示成功界面
  'puzzle:completed': (puzzleId: string) => {
    useScreenStore.getState().pushScreen('puzzle_complete', { puzzleId });
  }
};
```

---

## 3. 核心模块设计

### 3.1 UIManager - UI中央控制器

```typescript
// src/ui/core/UIManager.ts
import { Container, Application } from 'pixi.js';
import { ScreenManager } from './ScreenManager';
import { LayerManager } from './LayerManager';
import { ThemeManager } from './ThemeManager';
import { AnimationManager } from './AnimationManager';
import { InputManager } from './InputManager';

export class UIManager {
  private static instance: UIManager;
  
  public app: Application;
  public screenManager: ScreenManager;
  public layerManager: LayerManager;
  public themeManager: ThemeManager;
  public animationManager: AnimationManager;
  public inputManager: InputManager;
  
  // 根容器
  public rootContainer: Container;
  
  private constructor(app: Application) {
    this.app = app;
    this.rootContainer = new Container();
    this.app.stage.addChild(this.rootContainer);
    
    // 初始化子系统
    this.layerManager = new LayerManager(this.rootContainer);
    this.themeManager = new ThemeManager();
    this.animationManager = new AnimationManager();
    this.inputManager = new InputManager(app);
    this.screenManager = new ScreenManager(this);
  }
  
  public static getInstance(app?: Application): UIManager {
    if (!UIManager.instance) {
      if (!app) throw new Error('UIManager requires Application instance');
      UIManager.instance = new UIManager(app);
    }
    return UIManager.instance;
  }
  
  // 初始化UI系统
  public async initialize(): Promise<void> {
    await this.themeManager.loadTheme('default');
    this.inputManager.initialize();
    this.registerScreens();
  }
  
  // 注册所有屏幕
  private registerScreens(): void {
    this.screenManager.register('main_menu', () => new MainMenuScreen());
    this.screenManager.register('game_hud', () => new GameHUDScreen());
    this.screenManager.register('pause_menu', () => new PauseMenuScreen());
    this.screenManager.register('settings', () => new SettingsScreen());
    this.screenManager.register('save_load', () => new SaveLoadScreen());
    this.screenManager.register('dialog', () => new DialogScreen());
  }
  
  // 全局方法
  public showToast(message: string, duration?: number): void {
    const toast = new ToastNotification(message, duration);
    this.layerManager.addToLayer('popup', toast);
  }
  
  public showDialog(config: DialogConfig): Promise<DialogResult> {
    return this.screenManager.openDialog(config);
  }
  
  // 更新循环
  public update(deltaTime: number): void {
    this.screenManager.update(deltaTime);
    this.animationManager.update(deltaTime);
  }
  
  // 清理
  public destroy(): void {
    this.screenManager.destroy();
    this.inputManager.destroy();
    this.rootContainer.destroy({ children: true });
    UIManager.instance = null;
  }
