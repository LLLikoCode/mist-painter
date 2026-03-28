/**
 * 事件总线接口
 * 提供类型安全的事件订阅和发布机制
 */

/**
 * 事件类型枚举
 */
export enum EventType {
  // 游戏状态事件
  GAME_STARTED = 'GAME_STARTED',
  GAME_PAUSED = 'GAME_PAUSED',
  GAME_RESUMED = 'GAME_RESUMED',
  GAME_OVER = 'GAME_OVER',
  LEVEL_STARTED = 'LEVEL_STARTED',
  LEVEL_COMPLETED = 'LEVEL_COMPLETED',
  
  // 玩家事件
  PLAYER_MOVED = 'PLAYER_MOVED',
  PLAYER_INTERACTED = 'PLAYER_INTERACTED',
  PLAYER_DAMAGED = 'PLAYER_DAMAGED',
  PLAYER_HEALED = 'PLAYER_HEALED',
  
  // 解谜事件
  PUZZLE_STARTED = 'PUZZLE_STARTED',
  PUZZLE_SOLVED = 'PUZZLE_SOLVED',
  PUZZLE_FAILED = 'PUZZLE_FAILED',
  HINT_REQUESTED = 'HINT_REQUESTED',
  
  // UI事件
  UI_OPENED = 'UI_OPENED',
  UI_CLOSED = 'UI_CLOSED',
  DIALOG_STARTED = 'DIALOG_STARTED',
  DIALOG_ENDED = 'DIALOG_ENDED',
  
  // 音频事件
  MUSIC_CHANGED = 'MUSIC_CHANGED',
  SFX_PLAYED = 'SFX_PLAYED',
  AUDIO_MUTED = 'AUDIO_MUTED',
  
  // 系统事件
  SETTINGS_CHANGED = 'SETTINGS_CHANGED',
  SAVE_COMPLETED = 'SAVE_COMPLETED',
  LOAD_COMPLETED = 'LOAD_COMPLETED',
  ACHIEVEMENT_UNLOCKED = 'ACHIEVEMENT_UNLOCKED',
  
  // 迷雾系统事件
  MIST_PAINTED = 'MIST_PAINTED',
  MIST_CLEARED = 'MIST_CLEARED',
  MIST_COVERAGE_CHANGED = 'MIST_COVERAGE_CHANGED',
  
  // 存档事件
  SAVE_DATA_CHANGED = 'SAVE_DATA_CHANGED'
}

/**
 * 基础事件接口
 */
export interface IEvent {
  /** 事件类型 */
  type: EventType;
  /** 事件数据 */
  data: Record<string, unknown>;
  /** 事件时间戳 */
  timestamp: number;
  /** 事件来源 */
  source?: string;
}

/**
 * 事件处理器类型
 */
export type EventHandler<T extends IEvent = IEvent> = (event: T) => void;

/**
 * 事件订阅令牌
 * 用于取消订阅
 */
export interface IEventSubscription {
  /** 事件类型 */
  eventType: EventType;
  /** 订阅ID */
  subscriptionId: string;
  /**
   * 取消订阅
   */
  unsubscribe(): void;
}

/**
 * 事件总线接口
 */
export interface IEventBus {
  /**
   * 订阅事件
   * @param eventType 事件类型
   * @param handler 事件处理器
   * @returns 订阅令牌
   */
  subscribe<T extends IEvent>(
    eventType: EventType,
    handler: EventHandler<T>
  ): IEventSubscription;
  
  /**
   * 订阅事件（一次性）
   * @param eventType 事件类型
   * @param handler 事件处理器
   * @returns 订阅令牌
   */
  subscribeOnce<T extends IEvent>(
    eventType: EventType,
    handler: EventHandler<T>
  ): IEventSubscription;
  
  /**
   * 取消订阅
   * @param subscription 订阅令牌
   */
  unsubscribe(subscription: IEventSubscription): void;
  
  /**
   * 发布事件（立即执行）
   * @param eventType 事件类型
   * @param data 事件数据
   * @param source 事件来源
   */
  emit<T extends Record<string, unknown> = Record<string, unknown>>(
    eventType: EventType,
    data?: T,
    source?: string
  ): void;
  
  /**
   * 发布事件（延迟执行）
   * @param eventType 事件类型
   * @param data 事件数据
   * @param source 事件来源
   */
  emitDeferred<T extends Record<string, unknown> = Record<string, unknown>>(
    eventType: EventType,
    data?: T,
    source?: string
  ): void;
  
  /**
   * 清空特定事件的所有监听器
   * @param eventType 事件类型
   */
  clearEventListeners(eventType: EventType): void;
  
  /**
   * 清空所有监听器
   */
  clearAllListeners(): void;
  
  /**
   * 获取事件的监听器数量
   * @param eventType 事件类型
   */
  getListenerCount(eventType: EventType): number;
  
  /**
   * 检查是否有监听器
   * @param eventType 事件类型
   */
  hasListeners(eventType: EventType): boolean;
  
  /**
   * 设置调试模式
   * @param enabled 是否启用
   */
  setDebugMode(enabled: boolean): void;
}

/**
 * 具体事件类型定义
 */

export interface GameStartedEvent extends IEvent {
  type: EventType.GAME_STARTED;
  data: {
    mode: string;
    level?: number;
  };
}

export interface LevelCompletedEvent extends IEvent {
  type: EventType.LEVEL_COMPLETED;
  data: {
    level: number;
    score?: number;
    time?: number;
  };
}

export interface PuzzleSolvedEvent extends IEvent {
  type: EventType.PUZZLE_SOLVED;
  data: {
    puzzleId: string;
    level: number;
    time?: number;
  };
}

export interface MistClearedEvent extends IEvent {
  type: EventType.MIST_CLEARED;
  data: {
    position: { x: number; y: number };
    radius: number;
    coveragePercent: number;
  };
}

export interface PlayerMovedEvent extends IEvent {
  type: EventType.PLAYER_MOVED;
  data: {
    position: { x: number; y: number };
    velocity: { x: number; y: number };
  };
}
