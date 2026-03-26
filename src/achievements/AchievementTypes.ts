/**
 * 迷雾绘者 - 成就系统类型定义
 * Achievement System Type Definitions
 * 
 * @module AchievementTypes
 * @description 定义成就系统的所有类型、接口和枚举
 */

// ==================== 成就类型枚举 ====================

/**
 * 成就类型枚举
 * 定义不同类型的成就机制
 */
export enum AchievementType {
  /** 进度类 - 需要累积进度完成，如收集10个物品 */
  PROGRESS = 'PROGRESS',
  /** 一次性 - 只需触发一次即可完成的成就 */
  ONE_TIME = 'ONE_TIME',
  /** 累积类 - 跨存档累积的成就，如累计游玩100小时 */
  CUMULATIVE = 'CUMULATIVE',
  /** 隐藏成就 - 描述隐藏，解锁后才显示真实内容 */
  HIDDEN = 'HIDDEN',
  /** 连锁成就 - 需要按顺序完成多个条件 */
  CHAINED = 'CHAINED',
}

/**
 * 成就稀有度枚举
 * 影响成就的视觉表现和点数奖励
 */
export enum AchievementRarity {
  /** 普通 - 白色 */
  COMMON = 'COMMON',
  /** 稀有 - 绿色 */
  UNCOMMON = 'UNCOMMON',
  /** 罕见 - 蓝色 */
  RARE = 'RARE',
  /** 史诗 - 紫色 */
  EPIC = 'EPIC',
  /** 传说 - 橙色 */
  LEGENDARY = 'LEGENDARY',
}

/**
 * 解锁条件类型枚举
 * 定义成就的各种解锁条件
 */
export enum ConditionType {
  /** 关卡完成 - 完成指定关卡 */
  LEVEL_COMPLETE = 'LEVEL_COMPLETE',
  /** 多关卡完成 - 完成多个关卡 */
  LEVELS_COMPLETED = 'LEVELS_COMPLETED',
  /** 谜题解决 - 解决谜题 */
  PUZZLE_SOLVED = 'PUZZLE_SOLVED',
  /** 物品收集 - 收集物品 */
  ITEM_COLLECTED = 'ITEM_COLLECTED',
  /** 秘密发现 - 发现隐藏秘密 */
  SECRET_FOUND = 'SECRET_FOUND',
  /** 迷雾使用 - 使用迷雾能力 */
  MIST_USED = 'MIST_USED',
  /** 游戏时长 - 累计游戏时间 */
  PLAY_TIME = 'PLAY_TIME',
  /** 统计达标 - 某项统计达到目标值 */
  STAT_REACHED = 'STAT_REACHED',
  /** 死亡次数 - 死亡特定次数（恶搞成就） */
  DEATH_COUNT = 'DEATH_COUNT',
  /** 无死亡通关 - 不死亡完成特定内容 */
  NO_DEATH_RUN = 'NO_DEATH_RUN',
  /** 连击达成 - 达成特定连击 */
  COMBO_ACHIEVED = 'COMBO_ACHIEVED',
  /** 自定义条件 - 通过代码自定义的条件 */
  CUSTOM = 'CUSTOM',
}

// ==================== 基础接口 ====================

/**
 * 成就定义接口
 * 描述成就的基本属性和解锁条件
 */
export interface AchievementDefinition {
  /** 成就唯一标识符 */
  id: string;
  /** 成就名称 */
  name: string;
  /** 成就描述 */
  description: string;
  /** 隐藏成就未解锁时的替代描述 */
  hiddenDescription?: string;
  /** 成就图标路径（未解锁） */
  iconLockedPath: string;
  /** 成就图标路径（已解锁） */
  iconUnlockedPath: string;
  /** 成就类型 */
  type: AchievementType;
  /** 成就稀有度 */
  rarity: AchievementRarity;
  /** 解锁条件类型 */
  conditionType: ConditionType;
  /** 解锁条件参数 */
  conditionParams: Record<string, unknown>;
  /** 目标进度值（用于进度类成就） */
  targetProgress: number;
  /** 奖励点数 */
  points: number;
  /** 是否隐藏成就 */
  isHidden: boolean;
}

/**
 * 成就实例接口
 * 包含成就的运行时状态
 */
export interface Achievement extends AchievementDefinition {
  /** 是否已解锁 */
  isUnlocked: boolean;
  /** 解锁时间戳（ISO格式） */
  unlockedAt: string | null;
  /** 当前进度（用于进度类成就） */
  currentProgress: number;
}

/**
 * 成就保存数据接口
 * 用于存档系统存储的精简数据
 */
export interface AchievementSaveData {
  /** 是否已解锁 */
  isUnlocked: boolean;
  /** 解锁时间戳 */
  unlockedAt: string | null;
  /** 当前进度 */
  currentProgress: number;
}

/**
 * 成就数据存储格式
 * 与存档系统兼容的完整存储结构
 */
export interface AchievementStorageData {
  /** 数据版本 */
  version: string;
  /** 成就数据字典 { achievement_id: AchievementSaveData } */
  achievements: Record<string, AchievementSaveData>;
  /** 跨存档累积统计 */
  cumulativeStats: Record<string, number>;
}

// ==================== 成就统计接口 ====================

/**
 * 成就统计接口
 * 提供成就完成情况的统计信息
 */
export interface AchievementStats {
  /** 总成就数 */
  totalCount: number;
  /** 已解锁成就数 */
  unlockedCount: number;
  /** 总成就点数 */
  totalPoints: number;
  /** 已获得成就点数 */
  earnedPoints: number;
  /** 隐藏成就数 */
  hiddenCount: number;
  /** 已解锁隐藏成就数 */
  hiddenUnlockedCount: number;
  /** 完成百分比 (0-100) */
  completionPercent: number;
}

// ==================== 成就事件接口 ====================

/**
 * 成就解锁事件
 */
export interface AchievementUnlockEvent {
  /** 成就ID */
  achievementId: string;
  /** 成就名称 */
  achievementName: string;
  /** 成就稀有度 */
  rarity: AchievementRarity;
  /** 获得点数 */
  points: number;
  /** 解锁时间 */
  unlockedAt: string;
}

/**
 * 成就进度更新事件
 */
export interface AchievementProgressEvent {
  /** 成就ID */
  achievementId: string;
  /** 成就名称 */
  achievementName: string;
  /** 旧进度值 */
  oldProgress: number;
  /** 新进度值 */
  newProgress: number;
  /** 目标进度值 */
  targetProgress: number;
  /** 进度百分比 (0-1) */
  progressPercent: number;
}

// ==================== UI相关接口 ====================

/**
 * 成就显示数据
 * 用于UI渲染的成就数据
 */
export interface AchievementDisplayData {
  /** 成就ID */
  id: string;
  /** 显示名称 */
  name: string;
  /** 显示描述 */
  description: string;
  /** 图标路径 */
  iconPath: string;
  /** 稀有度 */
  rarity: AchievementRarity;
  /** 稀有度颜色 */
  rarityColor: string;
  /** 是否已解锁 */
  isUnlocked: boolean;
  /** 是否隐藏（未解锁时） */
  isHidden: boolean;
  /** 当前进度 */
  currentProgress: number;
  /** 目标进度 */
  targetProgress: number;
  /** 进度百分比 (0-1) */
  progressPercent: number;
  /** 奖励点数 */
  points: number;
  /** 解锁时间 */
  unlockedAt: string | null;
}

/**
 * 成就列表过滤选项
 */
export interface AchievementFilterOptions {
  /** 按稀有度过滤 */
  rarity?: AchievementRarity[];
  /** 按类型过滤 */
  type?: AchievementType[];
  /** 只显示已解锁 */
  unlockedOnly?: boolean;
  /** 只显示未解锁 */
  lockedOnly?: boolean;
  /** 包含隐藏成就 */
  includeHidden?: boolean;
  /** 搜索关键词 */
  searchQuery?: string;
}

/**
 * 成就排序选项
 */
export enum AchievementSortOption {
  /** 按ID排序 */
  ID = 'id',
  /** 按名称排序 */
  NAME = 'name',
  /** 按稀有度排序 */
  RARITY = 'rarity',
  /** 按点数排序 */
  POINTS = 'points',
  /** 按解锁时间排序 */
  UNLOCKED_TIME = 'unlockedTime',
  /** 按进度排序 */
  PROGRESS = 'progress',
}

// ==================== 管理器配置接口 ====================

/**
 * 成就管理器配置
 */
export interface AchievementManagerConfig {
  /** 成就数据文件路径 */
  dataFilePath: string;
  /** 存档键名 */
  saveKey: string;
  /** 自动保存间隔（秒） */
  autoSaveInterval: number;
  /** 是否启用自动保存 */
  enableAutoSave: boolean;
  /** 数据版本 */
  version: string;
}

/**
 * 成就管理器状态
 */
export interface AchievementManagerState {
  /** 是否已初始化 */
  isInitialized: boolean;
  /** 成就总数 */
  totalAchievements: number;
  /** 已解锁数量 */
  unlockedCount: number;
  /** 未解锁数量 */
  lockedCount: number;
  /** 统计信息 */
  stats: AchievementStats;
}

// ==================== 条件参数类型 ====================

/**
 * 关卡完成条件参数
 */
export interface LevelCompleteParams {
  /** 关卡编号 */
  level: number;
  /** 时间限制（秒，可选） */
  timeLimit?: number;
  /** 是否禁用提示 */
  noHints?: boolean;
}

/**
 * 多关卡完成条件参数
 */
export interface LevelsCompletedParams {
  /** 完成数量 */
  count: number;
  /** 特定关卡列表（可选） */
  specificLevels?: number[];
}

/**
 * 谜题解决条件参数
 */
export interface PuzzleSolvedParams {
  /** 特定谜题ID（可选） */
  puzzleId?: string;
  /** 解决数量（可选） */
  count?: number;
  /** 难度要求（可选） */
  difficulty?: 'easy' | 'normal' | 'hard';
}

/**
 * 物品收集条件参数
 */
export interface ItemCollectedParams {
  /** 特定物品ID（可选） */
  itemId?: string;
  /** 物品类型（可选） */
  itemType?: string;
  /** 收集数量（可选） */
  count?: number;
}

/**
 * 秘密发现条件参数
 */
export interface SecretFoundParams {
  /** 特定秘密ID（可选） */
  secretId?: string;
  /** 发现数量（可选） */
  count?: number;
}

/**
 * 迷雾使用条件参数
 */
export interface MistUsedParams {
  /** 使用次数 */
  count: number;
  /** 特定能力类型（可选） */
  abilityType?: string;
}

/**
 * 游戏时长条件参数
 */
export interface PlayTimeParams {
  /** 目标秒数 */
  seconds: number;
}

/**
 * 统计达标条件参数
 */
export interface StatReachedParams {
  /** 统计项名称 */
  statName: string;
  /** 目标值 */
  value: number;
}

/**
 * 死亡次数条件参数
 */
export interface DeathCountParams {
  /** 死亡次数 */
  count: number;
}

/**
 * 无死亡通关条件参数
 */
export interface NoDeathRunParams {
  /** 特定关卡（可选） */
  level?: number;
  /** 层数（可选） */
  layers?: number;
}

/**
 * 连击达成条件参数
 */
export interface ComboAchievedParams {
  /** 连击数 */
  comboCount: number;
  /** 连击类型（可选） */
  comboType?: string;
}

/**
 * 自定义条件参数
 */
export interface CustomConditionParams {
  /** 自定义检查器ID */
  checkerId: string;
  /** 自定义数据（可选） */
  customData?: Record<string, unknown>;
}

//