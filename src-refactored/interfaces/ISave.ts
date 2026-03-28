/**
 * 存档系统接口
 * 负责游戏的保存和加载功能
 */

/**
 * 存档数据接口
 */
export interface SaveData {
  /** 存档版本 */
  version: string;
  /** 存档时间戳 */
  timestamp: string;
  /** 存档名称 */
  saveName?: string;
  /** 当前关卡 */
  level: number;
  /** 游戏时间（秒） */
  playTime: number;
  /** 游戏统计数据 */
  gameStats: Record<string, number>;
  /** 游戏设置 */
  settings: Record<string, unknown>;
  /** 成就数据 */
  achievements?: Record<string, unknown>;
  /** 自定义数据（其他系统使用） */
  customData?: Record<string, unknown>;
}

/**
 * 存档信息接口
 */
export interface SaveInfo {
  /** 存档槽位 */
  slot: number;
  /** 存档名称 */
  saveName: string;
  /** 关卡 */
  level: number;
  /** 游戏时间（秒） */
  playTime: number;
  /** 存档时间戳 */
  timestamp: string;
  /** 是否存在 */
  exists: boolean;
}

/**
 * 存档系统接口
 */
export interface ISaveManager {
  /** 最大存档槽位数 */
  readonly maxSaveSlots: number;
  /** 当前存档槽位 */
  readonly currentSlot: number;
  /** 当前存档数据 */
  readonly currentSaveData: SaveData | null;
  
  /**
   * 保存游戏
   * @param slot 存档槽位
   * @param saveName 存档名称
   * @returns 是否成功
   */
  saveGame(slot: number, saveName?: string): Promise<boolean>;
  
  /**
   * 加载游戏
   * @param slot 存档槽位
   * @returns 是否成功
   */
  loadGame(slot: number): Promise<boolean>;
  
  /**
   * 删除存档
   * @param slot 存档槽位
   * @returns 是否成功
   */
  deleteSave(slot: number): boolean;
  
  /**
   * 检查存档是否存在
   * @param slot 存档槽位
   */
  hasSave(slot: number): boolean;
  
  /**
   * 获取存档信息
   * @param slot 存档槽位
   */
  getSaveInfo(slot: number): SaveInfo | null;
  
  /**
   * 获取所有存档信息
   */
  getAllSaveInfo(): SaveInfo[];
  
  /**
   * 快速保存（槽位0）
   */
  quickSave(): Promise<boolean>;
  
  /**
   * 快速加载（槽位0）
   */
  quickLoad(): Promise<boolean>;
  
  /**
   * 自动保存（最后一个槽位）
   */
  autoSave(): Promise<boolean>;
  
  /**
   * 设置存档数据项
   * @param key 键
   * @param value 值
   */
  setSaveData<T>(key: string, value: T): void;
  
  /**
   * 获取存档数据项
   * @param key 键
   * @param defaultValue 默认值
   */
  getSaveData<T>(key: string, defaultValue?: T): T | undefined;
  
  /**
   * 导出存档（用于备份）
   * @param slot 存档槽位
   * @param exportPath 导出路径
   */
  exportSave(slot: number, exportPath: string): boolean;
  
  /**
   * 导入存档
   * @param importPath 导入路径
   * @param slot 目标槽位
   */
  importSave(importPath: string, slot: number): boolean;
  
  /**
   * 构建存档数据
   * 收集所有系统的数据
   */
  buildSaveData(): SaveData;
  
  /**
   * 应用存档数据
   * @param data 存档数据
   */
  applySaveData(data: SaveData): void;
}

/**
 * 存档序列化器接口
 * 用于自定义存档数据的序列化和反序列化
 */
export interface ISaveSerializer<T> {
  /**
   * 序列化数据
   * @param data 数据
   */
  serialize(data: T): string;
  
  /**
   * 反序列化数据
   * @param serialized 序列化字符串
   */
  deserialize(serialized: string): T;
  
  /**
   * 验证数据
   * @param data 数据
   */
  validate(data: unknown): boolean;
}

/**
 * 存档加密器接口
 */
export interface ISaveEncryptor {
  /**
   * 加密数据
   * @param data 原始数据
   */
  encrypt(data: string): string;
  
  /**
   * 解密数据
   * @param encrypted 加密数据
   */
  decrypt(encrypted: string): string;
  
  /**
   * 生成校验和
   * @param data 数据
   */
  generateChecksum(data: string): string;
  
  /**
   * 验证校验和
   * @param data 数据
   * @param checksum 校验和
   */
  verifyChecksum(data: string, checksum: string): boolean;
}
