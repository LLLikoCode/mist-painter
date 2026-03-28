/**
 * ISystem 接口
 * 所有系统管理器必须实现此接口，确保统一的初始化和生命周期管理
 */
export interface ISystem {
  /** 系统名称 */
  readonly systemName: string;
  
  /** 系统是否已初始化 */
  readonly isInitialized: boolean;
  
  /**
   * 初始化系统
   * @param config 配置对象
   * @returns 初始化是否成功
   */
  initialize(config?: Record<string, unknown>): Promise<boolean>;
  
  /**
   * 系统更新（每帧调用）
   * @param deltaTime 时间增量（秒）
   */
  update(deltaTime: number): void;
  
  /**
   * 清理系统资源
   */
  dispose(): void;
  
  /**
   * 获取系统状态
   */
  getStatus(): SystemStatus;
}

/**
 * 系统状态接口
 */
export interface SystemStatus {
  /** 系统名称 */
  name: string;
  /** 是否已初始化 */
  initialized: boolean;
  /** 是否活跃 */
  active: boolean;
  /** 附加信息 */
  metadata?: Record<string, unknown>;
}

/**
 * 系统优先级枚举
 * 用于确定系统初始化顺序
 */
export enum SystemPriority {
  CRITICAL = 0,   // 核心系统（最先初始化）
  HIGH = 1,       // 高优先级
  MEDIUM = 2,     // 中等优先级
  LOW = 3,        // 低优先级
  BACKGROUND = 4  // 后台系统（最后初始化）
}

/**
 * 系统配置接口
 */
export interface SystemConfig {
  /** 系统优先级 */
  priority: SystemPriority;
  /** 是否启用 */
  enabled: boolean;
  /** 系统特定配置 */
  settings?: Record<string, unknown>;
}
