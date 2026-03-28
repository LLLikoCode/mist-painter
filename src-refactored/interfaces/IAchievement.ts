/**
 * 成就系统接口
 * 负责管理成就的加载、解锁、进度追踪和持久化
 */

/**
 * 成就条件类型
 */
export enum AchievementConditionType {
  STAT = 'stat',
  LEVEL_COMPLETE = 'level_complete',
  LEVEL_COMPLETE_FIRST = 'level_complete_first',
  PUZZLE_SOLVED = 'puzzle_solved',
  CUSTOM = 'custom'
}

/**
 * 成就稀有度
 */
export enum AchievementRarity {
  COMMON = 'common',
  UNCOMMON = 'uncommon',
  RARE = 'rare',
  EPIC = 'epic',
  LEGENDARY = 'legendary'
}

/**
 * 成就定义接口
 */
export interface AchievementDefinition {
  /** 成就ID */
  id: string;
  /** 成就名称 */
  name: string;
  /** 成就描述 */
  description: string;
  /** 图标路径 */
  iconPath?: string;
  /** 积分 */
  points: number;
  /** 稀有度 */
  rarity: AchievementRarity;
  /** 是否隐藏 */
  isHidden: boolean;
  /** 条件类型 */
  conditionType: AchievementConditionType;
  /** 条件参数 */
  conditionParams: Record<string, unknown>;
  /** 目标进度 */
  targetProgress: number;
}

/**
 * 成就实例接口
 */
export interface Achievement {
  /** 成就定义 */
  definition: AchievementDefinition;
  /** 是否已解锁 */
  isUnlocked: boolean;
  /** 解锁时间 */
  unlockedAt: string | null;
  /** 当前进度 */
  currentProgress: number;
}

/**
 * 成就统计接口
 */
export interface AchievementStats {
  /** 总成就数 */
  totalCount: number;
  /** 已解锁数 */
  unlockedCount: number;
  /** 隐藏成就数 */
  hiddenCount: number;
  /** 已解锁隐藏成就数 */
  hiddenUnlockedCount: number;
  /** 总积分 */
  totalPoints: number;
  /** 已获得积分 */
  earnedPoints: number;
}

/**
 * 成就通知配置
 */
export interface AchievementNotificationConfig {
  /** 通知持续时间（秒） */
  duration: number;
  /** 最大队列长度 */
  maxQueueSize: number;
  /** 是否显示通知 */
  enabled: boolean;
}

/**
 * 成就系统接口
 */
export interface IAchievementManager {
  /** 通知配置 */
  notificationConfig: AchievementNotificationConfig;
  
  /**
   * 初始化成就系统
   * @param definitionsPath 成就定义文件路径
   */
  initialize(definitionsPath: string): Promise<boolean>;
  
  /**
   * 获取所有成就
   */
  getAllAchievements(): Achievement[];
  
  /**
   * 获取已解锁成就
   */
  getUnlockedAchievements(): Achievement[];
  
  /**
   * 获取未解锁成就
   */
  getLockedAchievements(): Achievement[];
  
  /**
   * 获取特定成就
   * @param achievementId 成就ID
   */
  getAchievement(achievementId: string): Achievement | null;
  
  /**
   * 检查成就是否已解锁
   * @param achievementId 成就ID
   */
  isAchievementUnlocked(achievementId: string): boolean;
  
  /**
   * 解锁成就
   * @param achievementId 成就ID
   * @param showNotification 是否显示通知
   * @returns 是否成功
   */
  unlockAchievement(achievementId: string, showNotification?: boolean): boolean;
  
  /**
   * 更新成就进度
   * @param achievementId 成就ID
   * @param amount 增量
   * @returns 是否解锁
   */
  updateAchievementProgress(achievementId: string, amount?: number): boolean;
  
  /**
   * 设置成就进度
   * @param achievementId 成就ID
   * @param value 进度值
   * @returns 是否解锁
   */
  setAchievementProgress(achievementId: string, value: number): boolean;
  
  /**
   * 增加统计值（自动更新相关成就）
   * @param statName 统计名称
   * @param amount 增量
   */
  incrementStat(statName: string, amount?: number): void;
  
  /**
   * 重置单个成就
   * @param achievementId 成就ID
   */
  resetAchievement(achievementId: string): void;
  
  /**
   * 重置所有成就
   */
  resetAllAchievements(): void;
  
  /**
   * 获取成就统计
   */
  getStats(): AchievementStats;
  
  /**
   * 注册自定义解锁检查器
   * @param achievementId 成就ID
   * @param checker 检查函数
   */
  registerUnlockChecker(
    achievementId: string,
    checker: (data: Record<string, unknown>) => boolean
  ): void;
  
  /**
   * 构建保存数据
   */
  buildSaveData(): Record<string, unknown>;
  
  /**
   * 从保存数据加载
   * @param data 保存数据
   */
  loadFromSaveData(data: Record<string, unknown>): void;
  
  /**
   * 导出成就数据（用于备份）
   */
  exportAchievements(): Record<string, unknown>;
  
  /**
   * 导入成就数据
   * @param data 成就数据
   */
  importAchievements(data: Record<string, unknown>): void;
  
  /**
   * 解锁所有成就（调试用）
   */
  unlockAllAchievements(): void;
  
  /**
   * 获取系统状态
   */
  getStatus(): AchievementSystemStatus;
}

/**
 * 成就系统状态
 */
export interface AchievementSystemStatus {
  totalAchievements: number;
  unlockedCount: number;
  lockedCount: number;
  notificationQueueSize: number;
  stats: AchievementStats;
}
