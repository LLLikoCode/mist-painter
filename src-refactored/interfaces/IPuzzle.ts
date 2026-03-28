/**
 * 谜题系统接口
 * 负责管理谜题的状态、逻辑、验证和与玩家的交互
 */

/**
 * 谜题类型枚举
 */
export enum PuzzleType {
  SWITCH = 'SWITCH',
  SEQUENCE = 'SEQUENCE',
  PATH_DRAWING = 'PATH_DRAWING',
  SYMBOL_MATCH = 'SYMBOL_MATCH',
  LIGHT_MIRROR = 'LIGHT_MIRROR',
  PRESSURE_PLATE = 'PRESSURE_PLATE',
  COMBINATION = 'COMBINATION'
}

/**
 * 谜题状态枚举
 */
export enum PuzzleState {
  LOCKED = 'LOCKED',
  ACTIVE = 'ACTIVE',
  SOLVED = 'SOLVED',
  FAILED = 'FAILED',
  UNLOCKED = 'UNLOCKED'
}

/**
 * 谜题定义接口
 */
export interface PuzzleDefinition {
  /** 谜题ID */
  id: string;
  /** 谜题名称 */
  name: string;
  /** 谜题类型 */
  type: PuzzleType;
  /** 难度（1-5） */
  difficulty: number;
  /** 是否需要迷雾清除 */
  requiresMistClearance: boolean;
  /** 迷雾清除半径 */
  mistClearanceRadius: number;
  /** 时间限制（秒，0表示无限制） */
  timeLimit: number;
  /** 最大尝试次数（0表示无限制） */
  maxAttempts: number;
  /** 提示文本 */
  hintText: string;
  /** 失败时是否显示提示 */
  showHintOnFail: boolean;
  /** 激活时是否发光 */
  glowWhenActive: boolean;
  /** 谜题数据 */
  puzzleData: Record<string, unknown>;
  /** 解决方案 */
  solution: Record<string, unknown>;
}

/**
 * 谜题实例接口
 */
export interface IPuzzleController {
  /** 谜题定义 */
  readonly definition: PuzzleDefinition;
  /** 当前状态 */
  readonly currentState: PuzzleState;
  /** 尝试次数 */
  readonly attemptCount: number;
  /** 已用时间（秒） */
  readonly elapsedTime: number;
  /** 是否正在计时 */
  readonly isTiming: boolean;
  /** 当前进度（0-1） */
  readonly progress: number;
  
  /**
   * 初始化谜题
   * @param definition 谜题定义
   */
  initialize(definition: PuzzleDefinition): void;
  
  /**
   * 设置状态
   * @param newState 新状态
   */
  setState(newState: PuzzleState): void;
  
  /**
   * 解锁谜题
   */
  unlock(): void;
  
  /**
   * 激活谜题
   */
  activate(): void;
  
  /**
   * 重置谜题
   */
  reset(): void;
  
  /**
   * 检查解决方案
   * @returns 是否正确
   */
  checkSolution(): boolean;
  
  /**
   * 接收输入
   * @param inputData 输入数据
   */
  receiveInput(inputData: Record<string, unknown>): void;
  
  /**
   * 是否可以交互
   */
  canInteract(): boolean;
  
  /**
   * 交互
   * @param playerId 玩家ID
   */
  interact(playerId: string): void;
  
  /**
   * 添加依赖谜题
   * @param puzzleId 谜题ID
   */
  addRequiredPuzzle(puzzleId: string): void;
  
  /**
   * 添加连接谜题
   * @param puzzleId 谜题ID
   */
  addConnectedPuzzle(puzzleId: string): void;
  
  /**
   * 通知连接谜题已解决
   * @param solvedPuzzleId 已解决谜题ID
   */
  onConnectedPuzzleSolved(solvedPuzzleId: string): void;
  
  /**
   * 是否已解决
   */
  isSolved(): boolean;
  
  /**
   * 导出状态（用于存档）
   */
  exportState(): PuzzleStateData;
  
  /**
   * 导入状态（从存档加载）
   * @param data 状态数据
   */
  importState(data: PuzzleStateData): void;
}

/**
 * 谜题状态数据
 */
export interface PuzzleStateData {
  puzzleId: string;
  state: PuzzleState;
  attempts: number;
  time: number;
  progress: number;
  puzzleData?: Record<string, unknown>;
}

/**
 * 谜题管理器接口
 */
export interface IPuzzleManager {
  /**
   * 注册谜题
   * @param puzzle 谜题控制器
   */
  registerPuzzle(puzzle: IPuzzleController): void;
  
  /**
   * 注销谜题
   * @param puzzleId 谜题ID
   */
  unregisterPuzzle(puzzleId: string): void;
  
  /**
   * 获取谜题
   * @param puzzleId 谜题ID
   */
  getPuzzle(puzzleId: string): IPuzzleController | null;
  
  /**
   * 获取所有谜题
   */
  getAllPuzzles(): IPuzzleController[];
  
  /**
   * 获取关卡中的所有谜题
   * @param levelId 关卡ID
   */
  getPuzzlesByLevel(levelId: number): IPuzzleController[];
  
  /**
   * 获取已解决谜题
   */
  getSolvedPuzzles(): IPuzzleController[];
  
  /**
   * 获取未解决谜题
   */
  getUnsolvedPuzzles(): IPuzzleController[];
  
  /**
   * 检查是否所有谜题都已解决
   * @param levelId 关卡ID（可选）
   */
  areAllPuzzlesSolved(levelId?: number): boolean;
  
  /**
   * 重置关卡中的所有谜题
   * @param levelId 关卡ID
   */
  resetLevelPuzzles(levelId: number): void;
  
  /**
   * 重置所有谜题
   */
  resetAllPuzzles(): void;
  
  /**
   * 导出所有谜题状态
   */
  exportAllStates(): PuzzleStateData[];
  
  /**
   * 导入所有谜题状态
   * @param states 状态数据列表
   */
  importAllStates(states: PuzzleStateData[]): void;
}

/**
 * 谜题激活事件
 */
export interface PuzzleActivatedEvent {
  puzzleId: string;
  puzzleType: PuzzleType;
}

/**
 * 谜题解决事件
 */
export interface PuzzleSolvedEvent {
  puzzleId: string;
  puzzleType: PuzzleType;
  time: number;
  attempts: number;
}

/**
 * 谜题失败事件
 */
export interface PuzzleFailedEvent {
  puzzleId: string;
  puzzleType: PuzzleType;
  time: number;
  attempts: number;
}

/**
 * 谜题进度更新事件
 */
export interface PuzzleProgressUpdatedEvent {
  puzzleId: string;
  progress: number;
}
