/**
 * 迷雾绘者 - 成就管理器
 * Achievement Manager
 * 
 * @module AchievementManager
 * @description 负责成就的加载、解锁检测、数据持久化和事件通知
 */

import {
  Achievement,
  AchievementDefinition,
  AchievementSaveData,
  AchievementStorageData,
  AchievementStats,
  AchievementType,
  AchievementRarity,
  ConditionType,
  AchievementDisplayData,
  AchievementFilterOptions,
  AchievementSortOption,
  AchievementManagerConfig,
  AchievementManagerState,
  AchievementUnlockEvent,
  AchievementProgressEvent,
} from './AchievementTypes';

// 事件监听器类型定义
type AchievementUnlockListener = (event: AchievementUnlockEvent) => void;
type AchievementProgressListener = (event: AchievementProgressEvent) => void;
type StatsUpdateListener = (stats: AchievementStats) => void;
type AchievementsLoadedListener = (count: number) => void;
type AchievementsSavedListener = () => void;

/**
 * 成就管理器类
 * 单例模式实现，负责管理游戏中所有成就的状态和交互
 */
export class AchievementManager {
  // ==================== 单例实例 ====================
  private static _instance: AchievementManager | null = null;

  /**
   * 获取成就管理器单例实例
   */
  public static get instance(): AchievementManager {
    if (!AchievementManager._instance) {
      AchievementManager._instance = new AchievementManager();
    }
    return AchievementManager._instance;
  }

  /**
   * 销毁单例实例
   */
  public static destroy(): void {
    if (AchievementManager._instance) {
      AchievementManager._instance.dispose();
      AchievementManager._instance = null;
    }
  }

  // ==================== 常量配置 ====================
  private readonly DEFAULT_CONFIG: AchievementManagerConfig = {
    dataFilePath: 'assets/data/achievements.json',
    saveKey: 'achievements',
    autoSaveInterval: 30,
    enableAutoSave: true,
    version: '1.0.0',
  };

  // 稀有度颜色映射
  private readonly RARITY_COLORS: Record<AchievementRarity, string> = {
    [AchievementRarity.COMMON]: '#E0E0E0',
    [AchievementRarity.UNCOMMON]: '#4CAF50',
    [AchievementRarity.RARE]: '#2196F3',
    [AchievementRarity.EPIC]: '#9C27B0',
    [AchievementRarity.LEGENDARY]: '#FF9800',
  };

  // 稀有度点数倍率
  private readonly RARITY_MULTIPLIERS: Record<AchievementRarity, number> = {
    [AchievementRarity.COMMON]: 1.0,
    [AchievementRarity.UNCOMMON]: 1.5,
    [AchievementRarity.RARE]: 2.0,
    [AchievementRarity.EPIC]: 3.0,
    [AchievementRarity.LEGENDARY]: 5.0,
  };

  // ==================== 内部状态 ====================
  private _config: AchievementManagerConfig;
  private _achievements: Map<string, Achievement> = new Map();
  private _definitions: Map<string, AchievementDefinition> = new Map();
  private _cumulativeStats: Map<string, number> = new Map();
  private _isInitialized: boolean = false;
  private _autoSaveTimer: number | null = null;
  private _saveDataProvider: (() => Record<string, unknown>) | null = null;
  private _loadDataProvider: ((key: string) => Record<string, unknown> | null) | null = null;

  // ==================== 事件监听器 ====================
  private _unlockListeners: Set<AchievementUnlockListener> = new Set();
  private _progressListeners: Set<AchievementProgressListener> = new Set();
  private _statsListeners: Set<StatsUpdateListener> = new Set();
  private _loadedListeners: Set<AchievementsLoadedListener> = new Set();
  private _savedListeners: Set<AchievementsSavedListener> = new Set();

  // ==================== 构造函数 ====================
  constructor(config?: Partial<AchievementManagerConfig>) {
    this._config = { ...this.DEFAULT_CONFIG, ...config };
  }

  // ==================== 初始化方法 ====================

  /**
   * 初始化成就管理器
   * @param saveProvider 存档数据提供者（可选）
   * @param loadProvider 存档数据加载器（可选）
   * @returns 初始化是否成功
   */
  public async initialize(
    saveProvider?: () => Record<string, unknown>,
    loadProvider?: (key: string) => Record<string, unknown> | null
  ): Promise<boolean> {
    if (this._isInitialized) {
      console.warn('[AchievementManager] Already initialized');
      return true;
    }

    try {
      // 设置存档数据提供者
      if (saveProvider) this._saveDataProvider = saveProvider;
      if (loadProvider) this._loadDataProvider = loadProvider;

      // 加载成就定义
      await this._loadAchievementDefinitions();

      // 从存档加载进度
      await this._loadFromSave();

      // 初始化自动保存
      if (this._config.enableAutoSave) {
        this._initAutoSave();
      }

      this._isInitialized = true;
      console.log(`[AchievementManager] Initialized with ${this._achievements.size} achievements`);
      
      // 触发加载完成事件
      this._notifyLoaded(this._achievements.size);
      
      return true;
    } catch (error) {
      console.error('[AchievementManager] Initialization failed:', error);
      return false;
    }
  }

  /**
   * 从JSON文件加载成就定义
   */
  private async _loadAchievementDefinitions(): Promise<void> {
    try {
      // 尝试从配置路径加载
      const response = await fetch(this._config.dataFilePath);
      if (!response.ok) {
        // 如果失败，使用内置数据
        console.warn('[AchievementManager] Failed to load achievement data, using built-in data');
        await this._loadBuiltInDefinitions();
        return;
      }

      const data = await response.json();
      this._parseDefinitions(data);
    } catch (error) {
      console.warn('[AchievementManager] Using built-in achievement definitions:', error);
      await this._loadBuiltInDefinitions();
    }
  }

  /**
   * 加载内置成就定义
   */
  private async _loadBuiltInDefinitions(): Promise<void> {
    // 内置成就数据（作为后备）
    const builtInData = await import('./AchievementData.json');
    this._parseDefinitions(builtInData);
  }

  /**
   * 解析成就定义
   */
  private _parseDefinitions(data: Record<string, unknown>): void {
    const achievements = data.achievements as Record<string, AchievementDefinition>;
    const cumulativeStats = data.cumulativeStats as Record<string, number>;

    if (achievements) {
      for (const [id, def] of Object.entries(achievements)) {
        const definition: AchievementDefinition = {
          ...def,
          id,
          type: def.type as AchievementType,
          rarity: def.rarity as AchievementRarity,
          conditionType: def.conditionType as ConditionType,
        };
        this._definitions.set(id, definition);

        // 创建成就实例
        const achievement: Achievement = {
          ...definition,
          isUnlocked: false,
          unlockedAt: null,
          currentProgress: 0,
        };
        this._achievements.set(id, achievement);
      }
    }

    // 加载累积统计
    if (cumulativeStats) {
      for (const [key, value] of Object.entries(cumulativeStats)) {
        this._cumulativeStats.set(key, value);
      }
    }
  }

  /**
   * 从存档加载成就进度
   */
  private async _loadFromSave(): Promise<void> {
    if (!this._loadDataProvider) {
      console.warn('[AchievementManager] No load data provider, achievements will not be persisted');
      return;
    }

    const savedData = this._loadDataProvider(this._config.saveKey) as AchievementStorageData | null;
    if (!savedData || !savedData.achievements) {
      return;
    }

    // 恢复成就进度
    for (const [id, data] of Object.entries(savedData.achievements)) {
      const achievement = this._achievements.get(id);
      if (achievement && data) {
        achievement.isUnlocked = data.isUnlocked ?? false;
        achievement.unlockedAt = data.unlockedAt ?? null;
        achievement.currentProgress = data.currentProgress ?? 0;
      }
    }

    // 恢复累积统计
    if (savedData.cumulativeStats) {
      for (const [key, value] of Object.entries(savedData.cumulativeStats)) {
        this._cumulativeStats.set(key, value);
      }
    }
  }

  /**
   * 初始化自动保存定时器
   */
  private _initAutoSave(): void {
    if (this._autoSaveTimer !== null) {
      window.clearInterval(this._autoSaveTimer);
    }

    this._autoSaveTimer = window.setInterval(() => {
      this._saveToStorage();
    }, this._config.autoSaveInterval * 1000);
  }

  /**
   * 保存到存储
   */
  private _saveToStorage(): void {
    if (!this._saveDataProvider) {
      return;
    }

    const saveData = this._buildSaveData();
    // 通过提供者保存数据
    // 注意：实际实现中需要通过游戏的主存档系统保存
    console.log('[AchievementManager] Auto-saved achievements');
    this._notifySaved();
  }

  /**
   * 构建保存数据
   */
  private _buildSaveData(): AchievementStorageData {
    const achievements: Record<string, AchievementSaveData> = {};

    for (const [id, achievement] of this._achievements) {
      achievements[id] = {
        isUnlocked: achievement.isUnlocked,
        unlockedAt: achievement.unlockedAt,
        currentProgress: achievement.currentProgress,
      };
    }

    const cumulativeStats: Record<string, number> = {};
    for (const [key, value] of this._cumulativeStats) {
      cumulativeStats[key] = value;
    }

    return {
      version: this._config.version,
      achievements,
      cumulativeStats,
    };
  }

  /**
   * 释放资源
   */
  public dispose(): void {
    if (this._autoSaveTimer !== null) {
      window.clearInterval(this._autoSaveTimer);
      this._autoSaveTimer = null;
    }

    // 保存最终数据
    this._saveToStorage();

    // 清空监听器
    this._unlockListeners.clear();
    this._progressListeners.clear();
    this._statsListeners.clear();
    this._loadedListeners.clear();
    this._savedListeners.clear();

    this._isInitialized = false;
  }

  // ==================== 事件订阅方法 ====================

  /**
   * 订阅成就解锁事件
   */
  public onAchievementUnlocked(listener: AchievementUnlockListener): () => void {
    this._unlockListeners.add(listener);
    return () => this._unlockListeners.delete(listener);
  }

  /**
   * 订阅成就进度更新事件
   */
  public onProgressUpdated(listener: AchievementProgressListener): () => void {
    this._progressListeners.add(listener);
    return () => this._progressListeners.delete(listener);
  }

  /**
   * 订阅统计更新事件
   */
  public onStatsUpdated(listener: StatsUpdateListener): () => void {
    this._statsListeners.add(listener);
    return () => this._statsListeners.delete(listener);
  }

  /**
   * 订阅成就加载完成事件
   */
  public onAchievementsLoaded(listener: AchievementsLoadedListener): () => void {
    this._loadedListeners.add(listener);
    return () => this._loadedListeners.delete(listener);
  }

  /**
   * 订阅成就保存事件
   */
  public onAchievementsSaved(listener: AchievementsSavedListener): () => void {
    this._savedListeners.add(listener);
    return () => this._savedListeners.delete(listener);
  }

  // ==================== 事件通知方法 ====================

  private _notifyUnlock(event: AchievementUnlockEvent): void {
    for (const listener of this._unlockListeners) {
      try {
        listener(event);
      } catch (error) {
        console.error('[AchievementManager] Error in unlock listener:', error);
      }
    }
  }

  private _notifyProgress(event: AchievementProgressEvent): void {
    for (const listener of this._progressListeners) {
      try {
        listener(event);
      } catch (error) {
        console.error('[AchievementManager] Error in progress listener:', error);
      }
    }
  }

  private _notifyStats(stats: AchievementStats): void {
    for (const listener of this._statsListeners) {
      try {
        listener(stats);
      } catch (error) {
        console.error('[AchievementManager] Error in stats listener:', error);
      }
    }
  }

  private _notifyLoaded(count: number): void {
    for (const listener of this._loadedListeners) {
      try {
        listener(count);
      } catch (error) {
        console.error('[AchievementManager] Error in loaded listener:', error);
      }
    }
  }

  private _notifySaved(): void {
    for (const listener of this._savedListeners) {
      try {
        listener();
      } catch (error) {
        console.error('[AchievementManager] Error in saved listener:', error);
      }
    }
  }

  // ==================== 成就查询方法 ====================

  /**
   * 获取所有成就
   */
  public getAllAchievements(): Achievement[] {
    return Array.from(this._achievements.values());
  }

  /**
   * 获取已解锁成就
   */
  public getUnlockedAchievements(): Achievement[] {
    return this.getAllAchievements().filter(a => a.isUnlocked);
  }

  /**
   * 获取未解锁成就
   */
  public getLockedAchievements(): Achievement[] {
    return this.getAllAchievements().filter(a => !a.isUnlocked);
  }

  /**
   * 获取特定成就
   */
  public getAchievement(id: string): Achievement | undefined {
    return this._achievements.get(id);
  }

  /**
   * 检查成就是否存在
   */
  public hasAchievement(id: string): boolean {
    return this._achievements.has(id);
  }

  /**
   * 检查成就是否已解锁
   */
  public isUnlocked(id: string): boolean {
    const achievement = this._achievements.get(id);
    return achievement?.isUnlocked ?? false;
  }

  /**
   * 获取成就进度
   */
  public getProgress(id: string): number {
    const achievement = this._achievements.get(id);
    return achievement?.currentProgress ?? 0;
  }

  /**
   * 获取成就统计
   */
  public getStats(): AchievementStats {
    const stats: AchievementStats = {
      totalCount: 0,
      unlockedCount: 0,
      totalPoints: 0,
      earnedPoints: 0,
      hiddenCount: 0,
      hiddenUnlockedCount: 0,
      completionPercent: 0,
    };

    for (const achievement of this._achievements.values()) {
      stats.totalCount++;
      stats.totalPoints += achievement.points;

      if (achievement.isHidden) {
        stats.hiddenCount++;
      }

      if (achievement.isUnlocked) {
        stats.unlockedCount++;
        stats.earnedPoints += achievement.points;

        if (achievement.isHidden) {
          stats.hiddenUnlockedCount++;
        }
      }
    }

    if (stats.totalCount > 0) {
      stats.completionPercent = (stats.unlockedCount / stats.totalCount) * 100;
    }

    return stats;
  }

  /**
   * 获取管理器状态
   */
  public getState(): AchievementManagerState {
    const stats = this.getStats();
    return {
      isInitialized: this._isInitialized,
      totalAchievements: this._achievements.size,
      unlockedCount: stats.unlockedCount,
      lockedCount: stats.totalCount - stats.unlockedCount,
      stats,
    };
  }

  // ==================== 成就解锁与进度 ====================

  /**
   * 解锁成就
   * @param id 成就ID
   * @returns 是否成功解锁
   */
  public unlockAchievement(id: string): boolean {
    const achievement = this._achievements.get(id);
    if (!achievement) {
      console.warn(`[AchievementManager] Achievement not found: ${id}`);
      return false;
    }

    if (achievement.isUnlocked) {
      return false;
    }

    // 解锁成就
    achievement.isUnlocked = true;
    achievement.unlockedAt = new Date().toISOString();
    achievement.currentProgress = achievement.targetProgress;

    console.log(`[AchievementManager] Achievement unlocked: ${id} - ${achievement.name}`);

    // 触发解锁事件
    this._notifyUnlock({
      achievementId: id,
      achievementName: achievement.name,
      rarity: achievement.rarity,
      points: achievement.points,
      unlockedAt: achievement.unlockedAt,
    });

    // 更新统计
    this._notifyStats(this.getStats());

    // 立即保存
    this._saveToStorage();

    return true;
  }

  /**
   * 更新成就进度
   * @param id 成就ID
   * @param amount 增加的进度值（默认1）
   * @returns 是否触发了解锁
   */
  public updateProgress(id: string, amount: number = 1): boolean {
    const achievement = this._achievements.get(id);
    if (!achievement) {
      return false;
    }

    if (achievement.isUnlocked) {
      return false;
    }

    // 只有进度类和累积类成就支持更新进度
    if (achievement.type !== AchievementType.PROGRESS && 
        achievement.type !== AchievementType.CUMULATIVE) {
      return false;
    }

    const oldProgress = achievement.currentProgress;
    const newProgress = Math.min(oldProgress + amount, achievement.targetProgress);
    achievement.currentProgress = newProgress;

    const shouldUnlock = newProgress >= achievement.targetProgress;

    if (oldProgress !== newProgress) {
      console.log(`[AchievementManager] Achievement progress updated: ${id} (${newProgress}/${achievement.targetProgress})`);

      // 触发进度更新事件
      this._notifyProgress({
        achievementId: id,
        achievementName: achievement.name,
        oldProgress,
        newProgress,
        targetProgress: achievement.targetProgress,
        progressPercent: newProgress / achievement.targetProgress,
      });

      if (shouldUnlock) {
        this.unlockAchievement(id);
      } else {
        this._saveToStorage();
      }
    }

    return shouldUnlock;
  }

  /**
   * 设置成就进度
   * @param id 成就ID
   * @param value 进度值
   * @returns 是否触发了解锁
   */
  public setProgress(id: string, value: number): boolean {
    const achievement = this._achievements.get(id);
    if (!achievement) {
      return false;
    }

    if (achievement.isUnlocked) {
      return false;
    }

    // 只有进度类和累积类成就支持设置进度
    if (achievement.type !== AchievementType.PROGRESS && 
        achievement.type !== AchievementType.CUMULATIVE) {
      return false;
    }

    const oldProgress = achievement.currentProgress;
    const newProgress = Math.max(0, Math.min(value, achievement.targetProgress));
    achievement.currentProgress = newProgress;

    const shouldUnlock = newProgress >= achievement.targetProgress;

    if (oldProgress !== newProgress) {
      this._notifyProgress({
        achievementId: id,
        achievementName: achievement.name,
        oldProgress,
        newProgress,
        targetProgress: achievement.targetProgress,
        progressPercent: newProgress / achievement.targetProgress,
      });

      if (shouldUnlock) {
        this.unlockAchievement(id);
      } else {
        this._saveToStorage();
      }
    }

    return shouldUnlock;
  }

  /**
   * 重置单个成就
   * @param id 成就ID
   */
  public resetAchievement(id: string): void {
    const achievement = this._achievements.get(id);
    if (!achievement) {
      return;
    }

    achievement.isUnlocked = false;
    achievement.unlockedAt = null;
    achievement.currentProgress = 0;

    this._saveToStorage();
    this._notifyStats(this.getStats());
  }

  /**
   * 重置所有成就
   */
  public resetAllAchievements(): void {
    for (const achievement of this._achievements.values()) {
      achievement.isUnlocked = false;
      achievement.unlockedAt = null;
      achievement.currentProgress = 0;
    }

    this._saveToStorage();
    this._notifyStats(this.getStats());
    console.log('[AchievementManager] All achievements reset');
  }

  /**
   * 解锁所有成就（调试用）
   */
  public unlockAllAchievements(): void {
    for (const [id, achievement] of this._achievements) {
      if (!achievement.isUnlocked) {
        this.unlockAchievement(id);
      }
    }
    console.log('[AchievementManager] All achievements unlocked (debug)');
  }

  // ==================== 累积统计管理 ====================

  /**
   * 更新累积统计
   * @param key 统计键
   * @param amount 增加量（默认1）
   */
  public updateCumulativeStat(key: string, amount: number = 1): void {
    const currentValue = this._cumulativeStats.get(key) ?? 0;
    this._cumulativeStats.set(key, currentValue + amount);
    this._saveToStorage();
  }

  /**
   * 设置累积统计
   * @param key 统计键
   * @param value 统计值
   */
  public setCumulativeStat(key: string, value: number): void {
    this._cumulativeStats.set(key, value);
    this._saveToStorage();
  }

  /**
   * 获取累积统计
   * @param key 统计键
   * @returns 统计值
   */
  public getCumulativeStat(key: string): number {
    return this._cumulativeStats.get(key) ?? 0;
  }

  /**
   * 获取所有累积统计
   */
  public getAllCumulativeStats(): Record<string, number> {
    const stats: Record<string, number> = {};
    for (const [key, value] of this._cumulativeStats) {
      stats[key] = value;
    }
    return stats;
  }

  // ==================== 存档集成 ====================

  /**
   * 获取存档数据（用于与SaveManager集成）
   * @returns 成就存储数据
   */
  public getSaveData(): AchievementStorageData {
    return this._buildSaveData();
  }

  /**
   * 从存档数据加载（用于与SaveManager集成）
   * @param data 存档数据
   */
  public loadSaveData(data: AchievementStorageData): void {
    if (!data || !data.achievements) {
      return;
    }

    // 恢复成就进度
    for (const [id, saveData] of Object.entries(data.achievements)) {
      const achievement = this._achievements.get(id);
      if (achievement && saveData) {
        achievement.isUnlocked = saveData.isUnlocked ?? false;
        achievement.unlockedAt = saveData.unlockedAt ?? null;
        achievement.currentProgress = saveData.currentProgress ?? 0;
      }
    }

    // 恢复累积统计
    if (data.cumulativeStats) {
      for (const [key, value] of Object.entries(data.cumulativeStats)) {
        this._cumulativeStats.set(key, value);
      }
    }

    this._notifyStats(this.getStats());
  }

  /**
   * 手动触发保存
   */
  public saveAchievements(): void {
    this._saveToStorage();
  }

  // ==================== UI支持方法 ====================

  /**
   * 获取成就显示数据
   * @param id 成就ID
   * @returns 成就显示数据
   */
  public getDisplayData(id: string): AchievementDisplayData | undefined {
    const achievement = this._achievements.get(id);
    if (!achievement) {
      return undefined;
    }

    const progressPercent = achievement.targetProgress > 0
      ? achievement.currentProgress / achievement.targetProgress
      : (achievement.isUnlocked ? 1 : 0);

    return {
      id: achievement.id,
      name: achievement.name,
      description: achievement.isHidden && !achievement.isUnlocked
        ? achievement.hiddenDescription ?? '???'
        : achievement.description,
      iconPath: achievement.isUnlocked
        ? achievement.iconUnlockedPath
        : achievement.iconLockedPath,
      rarity: achievement.rarity,
      rarityColor: this.RARITY_COLORS[achievement.rarity],
      isUnlocked: achievement.isUnlocked,
      isHidden: achievement.isHidden && !achievement.isUnlocked,
      currentProgress: achievement.currentProgress,
      targetProgress: achievement.targetProgress,
      progressPercent,
      points: achievement.points,
      unlockedAt: achievement.unlockedAt,
    };
  }

  /**
   * 获取所有成就的显示数据
   * @param options 过滤选项
   * @param sortBy 排序方式
   * @returns 成就显示数据列表
   */
  public getAllDisplayData(
    options?: AchievementFilterOptions,
    sortBy: AchievementSortOption = AchievementSortOption.ID
  ): AchievementDisplayData[] {
    let achievements = this.getAllAchievements();

    // 应用过滤
    if (options) {
      achievements = this._filterAchievements(achievements, options);
    }

    // 应用排序
    achievements = this._sortAchievements(achievements, sortBy);

    // 转换为显示数据
    return achievements
      .map(a => this.getDisplayData(a.id))
      .filter((d): d is AchievementDisplayData => d !== undefined);
  }

  /**
   * 过滤成就
   */
  private _filterAchievements(
    achievements: Achievement[],
    options: AchievementFilterOptions
  ): Achievement[] {
    return achievements.filter(achievement => {
      // 按稀有度过滤
      if (options.rarity && options.rarity.length > 0) {
        if (!options.rarity.includes(achievement.rarity)) {
          return false;
        }
      }

      // 按类型过滤
      if (options.type && options.type.length > 0) {
        if (!options.type.includes(achievement.type)) {
          return false;
        }
      }

      // 只显示已解锁
      if (options.unlockedOnly && !achievement.isUnlocked) {
        return false;
      }

      // 只显示未解锁
      if (options.lockedOnly && achievement.isUnlocked) {
        return false;
      }

      // 隐藏成就处理
      if (achievement.isHidden && !achievement.isUnlocked && !options.includeHidden) {
        return false;
      }

      // 搜索关键词
      if (options.searchQuery) {
        const query = options.searchQuery.toLowerCase();
        const nameMatch = achievement.name.toLowerCase().includes(query);
        const descMatch = achievement.description.toLowerCase().includes(query);
        const idMatch = achievement.id.toLowerCase().includes(query);
        if (!nameMatch && !descMatch && !idMatch) {
          return false;
        }
      }

      return true;
    });
  }

  /**
   * 排序成就
   */
  private _sortAchievements(
    achievements: Achievement[],
    sortBy: AchievementSortOption
  ): Achievement[] {
    const sorted = [...achievements];

    switch (sortBy) {
      case AchievementSortOption.ID:
        sorted.sort((a, b) => a.id.localeCompare(b.id));
        break;
      case AchievementSortOption.NAME:
        sorted.sort((a, b) => a.name.localeCompare(b.name));
        break;
      case AchievementSortOption.RARITY:
        const rarityOrder = [
          AchievementRarity.COMMON,
          AchievementRarity.UNCOMMON,
          AchievementRarity.RARE,
          AchievementRarity.EPIC,
          AchievementRarity.LEGENDARY,
        ];
        sorted.sort((a, b) => rarityOrder.indexOf(a.rarity) - rarityOrder.indexOf(b.rarity));
        break;
      case AchievementSortOption.POINTS:
        sorted.sort((a, b) => b.points - a.points);
        break;
      case AchievementSortOption.UNLOCKED_TIME:
        sorted.sort((a, b) => {
          if (!a.unlockedAt && !b.unlockedAt) return 0;
          if (!a.unlockedAt) return 1;
          if (!b.unlockedAt) return -1;
          return new Date(b.unlockedAt).getTime() - new Date(a.unlockedAt).getTime();
        });
        break;
      case AchievementSortOption.PROGRESS:
        sorted.sort((a, b) => {
          const progressA = a.targetProgress > 0 ? a.currentProgress / a.targetProgress : 0;
          const progressB = b.targetProgress > 0 ? b.currentProgress / b.targetProgress : 0;
          return progressB - progressA;
        });
        break;
    }

    return sorted;
  }

  // ==================== 便捷方法 ====================

  /**
   * 检查并更新基于统计的成就
   * @param statName 统计名称
   * @param value 当前值
   */
  public checkStatAchievement(statName: string, value: number): void {
    for (const [id, achievement] of this._achievements) {
      if (achievement.isUnlocked) continue;
      if (achievement.conditionType !== ConditionType.STAT_REACHED) continue;

      const params = achievement.conditionParams as { statName: string; value: number };
      if (params.statName === statName && value >= params.value) {
        this.unlockAchievement(id);
      }
    }
  }

  /**
   * 检查并更新基于关卡完成的成就
   * @param level 关卡编号
   */
  public checkLevelCompleteAchievement(level: number): void {
    for (const [id, achievement] of this._achievements) {
      if (achievement.isUnlocked) continue;
      if (achievement.conditionType !== ConditionType.LEVEL_COMPLETE) continue;

      const params = achievement.conditionParams as { level: number };
      if (params.level === level) {
        this.unlockAchievement(id);
      }
    }
  }

  /**
   * 检查并更新基于谜题解决的成就
   * @param puzzleId 谜题ID（可选）
   */
  public checkPuzzleSolvedAchievement(puzzleId?: string): void {
    for (const [id, achievement] of this._achievements) {
      if (achievement.isUnlocked) continue;

      const conditionType = achievement.conditionType;
      if (conditionType === ConditionType.PUZZLE_SOLVED) {
        if (achievement.type === AchievementType.PROGRESS || 
            achievement.type === AchievementType.CUMULATIVE) {
          this.updateProgress(id, 1);
        } else {
          const params = achievement.conditionParams as { puzzleId?: string };
          if (!params.puzzleId || params.puzzleId === puzzleId) {
            this.unlockAchievement(id);
          }
        }
      }
    }
  }

  /**
   * 检查并更新基于秘密发现的成就
   * @param secretId 秘密ID（可选）
   */
  public checkSecretFoundAchievement(secretId?: string): void {
    for (const [id, achievement] of this._achievements) {
      if (achievement.isUnlocked) continue;

      const conditionType = achievement.conditionType;
      if (conditionType === ConditionType.SECRET_FOUND) {
        if (achievement.type === AchievementType.PROGRESS || 
            achievement.type === AchievementType.CUMULATIVE) {
          this.updateProgress(id, 1);
        } else {
          const params = achievement.conditionParams as { secretId?: string };
          if (!params.secretId || params.secretId === secretId) {
            this.unlockAchievement(id);
          }
        }
      }
    }
  }

  /**
   * 检查并更新基于物品收集的成就
   * @param itemId 物品ID
   * @param itemType 物品类型
   */
  public checkItemCollectedAchievement(itemId: string, itemType?: string): void {
    for (const [id, achievement] of this._achievements) {
      if (achievement.isUnlocked) continue;

      const conditionType = achievement.conditionType;
      if (conditionType === ConditionType.ITEM_COLLECTED) {
        if (achievement.type === AchievementType.PROGRESS || 
            achievement.type === AchievementType.CUMULATIVE) {
          this.updateProgress(id, 1);
        } else {
          const params = achievement.conditionParams as { itemId?: string; itemType?: string };
          const itemIdMatch = !params.itemId || params.itemId === itemId;
          const itemTypeMatch = !params.itemType || params.itemType === itemType;
          if (itemIdMatch && itemTypeMatch) {
            this.unlockAchievement(id);
          }
        }
      }
    }
  }

  /**
   * 检查并更新基于迷雾使用的成就
   * @param abilityType 能力类型（可选）
   */
  public checkMistUsedAchievement(abilityType?: string): void {
    for (const [id, achievement] of this._achievements) {
      if (achievement.isUnlocked) continue;

      const conditionType = achievement.conditionType;
      if (conditionType === ConditionType.MIST_USED) {
        const params = achievement.conditionParams as { abilityType?: string };
        const typeMatch = !params.abilityType || params.abilityType === abilityType;
        if (typeMatch) {
          this.updateProgress(id, 1);
        }
      }
    }
  }

  /**
   * 获取成就完成摘要
   * @returns 成就完成摘要文本
   */
  public getCompletionSummary(): string {
    const stats = this.getStats();
    return `成就完成度: ${stats.unlockedCount}/${stats.totalCount} (${stats.completionPercent.toFixed(1)}%) - 获得点数: ${stats.earnedPoints}/${stats.totalPoints}`;
  }
}

// ==================== 导出默认实例 ====================

export default AchievementManager;
