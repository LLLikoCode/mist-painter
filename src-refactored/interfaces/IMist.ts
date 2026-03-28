/**
 * 迷雾系统接口
 * 负责管理迷雾的绘制、擦除、渲染和与游戏机制的交互
 */

/**
 * 笔刷设置接口
 */
export interface BrushSettings {
  /** 笔刷大小 */
  size: number;
  /** 笔刷硬度（0-1） */
  hardness: number;
  /** 笔刷透明度（0-1） */
  opacity: number;
}

/**
 * 迷雾设置接口
 */
export interface MistSettings {
  /** 迷雾密度（0-1） */
  density: number;
  /** 迷雾再生速率 */
  regenerationRate: number;
  /** 是否启用再生 */
  enableRegeneration: boolean;
  /** 迷雾颜色 */
  color: { r: number; g: number; b: number; a: number };
}

/**
 * 性能设置接口
 */
export interface MistPerformanceSettings {
  /** 更新间隔（秒） */
  updateInterval: number;
  /** 是否启用优化 */
  enableOptimization: boolean;
  /** 每帧最大绘制操作数 */
  maxPaintPerFrame: number;
  /** 是否启用异步覆盖率计算 */
  enableAsyncCoverage: boolean;
}

/**
 * 迷雾系统接口
 */
export interface IMistPaintingSystem {
  /** 笔刷设置 */
  brushSettings: BrushSettings;
  /** 迷雾设置 */
  mistSettings: MistSettings;
  /** 性能设置 */
  performanceSettings: MistPerformanceSettings;
  /** 当前迷雾覆盖率（0-1） */
  readonly coverage: number;
  /** 是否正在绘制 */
  readonly isDrawing: boolean;
  
  /**
   * 初始化迷雾系统
   * @param textureSize 纹理大小
   */
  initialize(textureSize: { width: number; height: number }): void;
  
  /**
   * 开始绘制
   * @param position 世界坐标位置
   */
  startDrawing(position: { x: number; y: number }): void;
  
  /**
   * 继续绘制（拖动）
   * @param position 世界坐标位置
   */
  continueDrawing(position: { x: number; y: number }): void;
  
  /**
   * 结束绘制
   */
  endDrawing(): void;
  
  /**
   * 清除指定圆形区域的迷雾
   * @param center 中心位置
   * @param radius 半径
   */
  clearMistCircle(center: { x: number; y: number }, radius: number): void;
  
  /**
   * 填充指定圆形区域的迷雾
   * @param center 中心位置
   * @param radius 半径
   */
  fillMistCircle(center: { x: number; y: number }, radius: number): void;
  
  /**
   * 完全清除所有迷雾
   */
  clearAllMist(): void;
  
  /**
   * 完全填充所有迷雾
   */
  fillAllMist(): void;
  
  /**
   * 重置迷雾
   */
  resetMist(): void;
  
  /**
   * 获取指定位置的迷雾密度
   * @param position 位置
   */
  getMistDensityAt(position: { x: number; y: number }): number;
  
  /**
   * 检查位置是否可见（迷雾密度低）
   * @param position 位置
   * @param threshold 可见性阈值
   */
  isPositionVisible(position: { x: number; y: number }, threshold?: number): boolean;
  
  /**
   * 获取当前迷雾覆盖率
   */
  getCoverage(): number;
  
  /**
   * 获取迷雾覆盖率百分比
   */
  getCoveragePercent(): number;
  
  /**
   * 设置笔刷大小
   * @param size 大小
   */
  setBrushSize(size: number): void;
  
  /**
   * 设置笔刷硬度
   * @param hardness 硬度（0-1）
   */
  setBrushHardness(hardness: number): void;
  
  /**
   * 设置笔刷透明度
   * @param opacity 透明度（0-1）
   */
  setBrushOpacity(opacity: number): void;
  
  /**
   * 导出迷雾数据（用于存档）
   */
  exportMistData(): Uint8Array;
  
  /**
   * 导入迷雾数据（从存档加载）
   * @param data 数据
   */
  importMistData(data: Uint8Array): boolean;
  
  /**
   * 保存迷雾图像到文件
   * @param path 文件路径
   */
  saveMistToFile(path: string): boolean;
  
  /**
   * 获取性能统计
   */
  getPerformanceStats(): MistPerformanceStats;
}

/**
 * 迷雾性能统计
 */
export interface MistPerformanceStats {
  /** 绘制队列大小 */
  paintQueueSize: number;
  /** 脏矩形数量 */
  dirtyRectsCount: number;
  /** 笔刷缓存大小 */
  brushCacheSize: number;
  /** 已清除像素数 */
  clearedPixels: number;
  /** 是否启用优化 */
  optimizationEnabled: boolean;
}

/**
 * 迷雾绘制事件
 */
export interface MistPaintedEvent {
  position: { x: number; y: number };
  radius: number;
}

/**
 * 迷雾清除事件
 */
export interface MistClearedEvent {
  position: { x: number; y: number };
  radius: number;
}

/**
 * 覆盖率变更事件
 */
export interface MistCoverageChangedEvent {
  coveragePercent: number;
  previousCoveragePercent: number;
}
