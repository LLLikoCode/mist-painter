/**
 * GameStateManager
 * 游戏状态管理器 - 负责管理游戏的全局状态和流程
 * 实现 IGameStateManager 接口
 */

import {
  IGameStateManager,
  GameState,
  GameMode,
  GameStats,
  GameStateChangeEvent,
  GameModeChangeEvent,
  LevelChangeEvent
} from '../interfaces/IGameState';
import {
  ISystem,
  SystemStatus,
  SystemPriority
} from '../interfaces/ISystem';
import { EventBus, eventBus } from '../events/EventBus';
import { EventType } from '../interfaces/IEventBus';

/**
 * 游戏状态管理器实现
 */
export class GameStateManager implements IGameStateManager, ISystem {
  // ISystem 属性
  public readonly systemName: string = 'GameStateManager';
  private _isInitialized: boolean = false;
  
  // IGameStateManager 属性
  private _currentState: GameState = GameState.BOOT;
  private _previousState: GameState = GameState.NONE;
  private _currentMode: GameMode = GameMode.STORY;
  private _currentLevel: number = 0;
  private _maxUnlockedLevel: number = 0;
  private _gameStats: GameStats = {
    totalPlayTime: 0,
    levelsCompleted: 0,
    puzzlesSolved: 0,
    mistUsed: 0
  };
  
  // 时间追踪
  private _stateStartTime: number = 0;
  private _playTimeStart: number = 0;
  
  // 事件总线
  private _eventBus: EventBus;
  
  constructor(eventBusInstance: EventBus = eventBus) {
    this._eventBus = eventBusInstance;
    this._playTimeStart = Date.now();
  }
  
  // ========== ISystem 实现 ==========
  
  get isInitialized(): boolean {
    return this._isInitialized;
  }
  
  async initialize(config?: Record<string, unknown>): Promise<boolean> {
    try {
      console.log('GameStateManager: Initializing...');
      
      // 从配置加载初始状态
      if (config) {
        if (config.initialState) {
          this._currentState = config.initialState as GameState;
        }
        if (config.initialMode) {
          this._currentMode = config.initialMode as GameMode;
        }
        if (config.initialLevel !== undefined) {
          this._currentLevel = config.initialLevel as number;
        }
      }
      
      this._stateStartTime = Date.now();
      this._isInitialized = true;
      
      console.log('GameStateManager: Initialized');
      return true;
    } catch (error) {
      console.error('GameStateManager: Initialization failed:', error);
      return false;
    }
  }
  
  update(deltaTime: number): void {
    // 更新游戏时间
    if (this._currentState === GameState.PLAYING) {
      this._gameStats.totalPlayTime += deltaTime;
    }
  }
  
  dispose(): void {
    console.log('GameStateManager: Disposing...');
    this._isInitialized = false;
  }
  
  getStatus(): SystemStatus {
    return {
      name: this.systemName,
      initialized: this._isInitialized,
      active: this._isInitialized,
      metadata: {
        currentState: this._currentState,
        currentMode: this._currentMode,
        currentLevel: this._currentLevel,
        playTime: this._gameStats.totalPlayTime
      }
    };
  }
  
  // ========== IGameStateManager 实现 ==========
  
  get currentState(): GameState {
    return this._currentState;
  }
  
  get previousState(): GameState {
    return this._previousState;
  }
  
  get currentMode(): GameMode {
    return this._currentMode;
  }
  
  get currentLevel(): number {
    return this._currentLevel;
  }
  
  get maxUnlockedLevel(): number {
    return this._maxUnlockedLevel;
  }
  
  changeState(newState: GameState): void {
    if (this._currentState === newState) {
      return;
    }
    
    const oldState = this._currentState;
    this._previousState = oldState;
    this._currentState = newState;
    this._stateStartTime = Date.now();
    
    console.log(`GameState: ${oldState} -> ${newState}`);
    
    // 发送事件
    this._eventBus.emit(EventType.GAME_STARTED, { 
      fromState: oldState,
      toState: newState 
    });
    
  }
  
  returnToPreviousState(): void {
    if (this._previousState !== GameState.NONE) {
      this.changeState(this._previousState);
    }
  }
  
  isInState(state: GameState): boolean {
    return this._currentState === state;
  }
  
  setGameMode(mode: GameMode): void {
    if (this._currentMode === mode) {
      return;
    }
    
    const oldMode = this._currentMode;
    this._currentMode = mode;
    
    console.log(`GameMode: ${oldMode} -> ${mode}`);
    
    this._eventBus.emit(EventType.GAME_STARTED, { 
      fromMode: oldMode,
      toMode: mode 
    });
  }
  
  setCurrentLevel(level: number): void {
    const previousLevel = this._currentLevel;
    this._currentLevel = level;
    
    if (level > this._maxUnlockedLevel) {
      this._maxUnlockedLevel = level;
    }
    
    this._eventBus.emit(EventType.LEVEL_STARTED, { 
      level,
      previousLevel 
    });
  }
  
  updateStat(statName: string, value: number): void {
    if (statName in this._gameStats) {
      this._gameStats[statName as keyof GameStats] = value;
    }
  }
  
  incrementStat(statName: string, amount: number = 1): void {
    if (statName in this._gameStats) {
      this._gameStats[statName as keyof GameStats] += amount;
    }
  }
  
  getStat(statName: string): number {
    return this._gameStats[statName as keyof GameStats] || 0;
  }
  
  getAllStats(): GameStats {
    return { ...this._gameStats };
  }
  
  resetStats(): void {
    this._gameStats = {
      totalPlayTime: 0,
      levelsCompleted: 0,
      puzzlesSolved: 0,
      mistUsed: 0
    };
  }
  
  serialize(): Record<string, unknown> {
    return {
      currentState: this._currentState,
      previousState: this._previousState,
      currentMode: this._currentMode,
      currentLevel: this._currentLevel,
      maxUnlockedLevel: this._maxUnlockedLevel,
      gameStats: { ...this._gameStats }
    };
  }
  
  deserialize(data: Record<string, unknown>): void {
    if (data.currentState) {
      this._currentState = data.currentState as GameState;
    }
    if (data.previousState) {
      this._previousState = data.previousState as GameState;
    }
    if (data.currentMode) {
      this._currentMode = data.currentMode as GameMode;
    }
    if (data.currentLevel !== undefined) {
      this._currentLevel = data.currentLevel as number;
    }
    if (data.maxUnlockedLevel !== undefined) {
      this._maxUnlockedLevel = data.maxUnlockedLevel as number;
    }
    if (data.gameStats) {
      this._gameStats = { ...(data.gameStats as GameStats) };
    }
  }
  
  // ========== 额外方法 ==========
  
  /**
   * 获取当前状态持续时间
   */
  getStateDuration(): number {
    return (Date.now() - this._stateStartTime) / 1000;
  }
  
  /**
   * 检查是否可以暂停
   */
  canPause(): boolean {
    return this._currentState === GameState.PLAYING;
  }
  
  /**
   * 检查是否可以恢复
   */
  canResume(): boolean {
    return this._currentState === GameState.PAUSED;
  }
  
  /**
   * 暂停游戏
   */
  pause(): void {
    if (this.canPause()) {
      this.changeState(GameState.PAUSED);
    }
  }
  
  /**
   * 恢复游戏
   */
  resume(): void {
    if (this.canResume()) {
      this.changeState(GameState.PLAYING);
    }
  }
  
  /**
   * 完成关卡
   */
  completeLevel(): void {
    this._gameStats.levelsCompleted++;
    this.changeState(GameState.LEVEL_COMPLETE);
  }
  
  /**
   * 游戏结束
   */
  gameOver(isVictory: boolean = false): void {
    if (isVictory) {
      this.changeState(GameState.CREDITS);
    } else {
      this.changeState(GameState.GAME_OVER);
    }
  }
}

// 导出单例
export const gameStateManager = new GameStateManager();
