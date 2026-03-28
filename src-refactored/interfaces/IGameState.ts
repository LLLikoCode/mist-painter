/**
 * 游戏状态管理器接口
 * 负责管理游戏的全局状态和流程
 */

/**
 * 游戏状态枚举
 */
export enum GameState {
  NONE = 'NONE',
  BOOT = 'BOOT',
  MAIN_MENU = 'MAIN_MENU',
  PLAYING = 'PLAYING',
  PAUSED = 'PAUSED',
  GAME_OVER = 'GAME_OVER',
  LEVEL_COMPLETE = 'LEVEL_COMPLETE',
  CREDITS = 'CREDITS'
}

/**
 * 游戏模式枚举
 */
export enum GameMode {
  STORY = 'STORY',
  FREE_PLAY = 'FREE_PLAY',
  TUTORIAL = 'TUTORIAL'
}

/**
 * 游戏统计数据接口
 */
export interface GameStats {
  totalPlayTime: number;
  levelsCompleted: number;
  puzzlesSolved: number;
  mistUsed: number;
  [key: string]: number;
}

/**
 * 游戏状态管理器接口
 */
export interface IGameStateManager {
  /** 当前游戏状态 */
  readonly currentState: GameState;
  /** 上一个游戏状态 */
  readonly previousState: GameState;
  /** 当前游戏模式 */
  readonly currentMode: GameMode;
  /** 当前关卡 */
  readonly currentLevel: number;
  /** 最大解锁关卡 */
  readonly maxUnlockedLevel: number;
  
  /**
   * 切换游戏状态
   * @param newState 新状态
   */
  changeState(newState: GameState): void;
  
  /**
   * 返回上一状态
   */
  returnToPreviousState(): void;
  
  /**
   * 检查当前状态
   * @param state 要检查的状态
   */
  isInState(state: GameState): boolean;
  
  /**
   * 设置游戏模式
   * @param mode 游戏模式
   */
  setGameMode(mode: GameMode): void;
  
  /**
   * 设置当前关卡
   * @param level 关卡编号
   */
  setCurrentLevel(level: number): void;
  
  /**
   * 更新统计数据
   * @param statName 统计项名称
   * @param value 新值
   */
  updateStat(statName: string, value: number): void;
  
  /**
   * 增加统计数据
   * @param statName 统计项名称
   * @param amount 增量
   */
  incrementStat(statName: string, amount?: number): void;
  
  /**
   * 获取统计数据
   * @param statName 统计项名称
   */
  getStat(statName: string): number;
  
  /**
   * 获取所有统计数据
   */
  getAllStats(): GameStats;
  
  /**
   * 重置统计数据
   */
  resetStats(): void;
  
  /**
   * 序列化状态（用于存档）
   */
  serialize(): Record<string, unknown>;
  
  /**
   * 反序列化状态（从存档加载）
   * @param data 存档数据
   */
  deserialize(data: Record<string, unknown>): void;
}

/**
 * 游戏状态变更事件
 */
export interface GameStateChangeEvent {
  newState: GameState;
  oldState: GameState;
  timestamp: number;
}

/**
 * 游戏模式变更事件
 */
export interface GameModeChangeEvent {
  newMode: GameMode;
  oldMode: GameMode;
  timestamp: number;
}

/**
 * 关卡变更事件
 */
export interface LevelChangeEvent {
  newLevel: number;
  previousLevel: number;
  timestamp: number;
}
