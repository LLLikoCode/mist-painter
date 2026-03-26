/**
 * 迷雾绘者 - 存档系统
 * Save System - Main entry point
 * 
 * 使用示例:
 * ```typescript
 * import { createSaveManager, SaveManager } from './save-system';
 * 
 * // 创建存档管理器
 * const saveManager = createSaveManager({
 *   maxManualSlots: 5,
 *   maxAutoSaves: 3,
 *   enableEncryption: true,
 *   autoSaveInterval: 5, // 分钟
 * });
 * 
 * // 保存游戏
 * await saveManager.save(1, gameState);
 * 
 * // 加载游戏
 * const loadedData = await saveManager.load(1);
 * 
 * // 自动存档
 * await saveManager.autoSave(gameState);
 * 
 * // 导出存档
 * const exported = await saveManager.exportSave(1);
 * 
 * // 导入存档
 * await saveManager.importSave(exportedData);
 * ```
 */

// 类型导出
export * from './types';

// 类导出
export { SaveManager } from './SaveManager';
export { SaveEncryptor, EncryptionConfig } from './SaveEncryptor';
export { LocalStorageAdapter, IndexedDBAdapter } from './StorageAdapter';

// 工具函数
import { SaveManager } from './SaveManager';
import { LocalStorageAdapter, IndexedDBAdapter } from './StorageAdapter';
import { SaveSystemConfig, StorageAdapter } from './types';

export interface CreateSaveManagerOptions {
  storage?: StorageAdapter;
  maxManualSlots?: number;
  maxAutoSaves?: number;
  enableEncryption?: boolean;
  encryptionKey?: string;
  autoSaveInterval?: number; // 分钟
  version?: string;
  gameVersion?: string;
}

/**
 * 创建存档管理器（便捷函数）
 */
export function createSaveManager(options: CreateSaveManagerOptions = {}): SaveManager {
  const storage = options.storage || new LocalStorageAdapter();
  
  const config: SaveSystemConfig = {
    version: options.version || '1.0.0',
    gameVersion: options.gameVersion || '1.0.0',
    maxManualSlots: options.maxManualSlots ?? 5,
    maxAutoSaves: options.maxAutoSaves ?? 3,
    encryptionKey: options.encryptionKey || '',
    enableEncryption: options.enableEncryption ?? true,
    enableCompression: false,
    autoSaveInterval: options.autoSaveInterval ?? 5,
    backupCount: 3,
  };

  return new SaveManager({ storage, config });
}

/**
 * 创建使用 IndexedDB 的存档管理器（适合大容量存档）
 */
export function createIndexedDBSaveManager(
  options: Omit<CreateSaveManagerOptions, 'storage'> = {}
): SaveManager {
  return createSaveManager({
    ...options,
    storage: new IndexedDBAdapter(),
  });
}

/**
 * 默认导出
 */
export default {
  createSaveManager,
  createIndexedDBSaveManager,
  SaveManager,
  LocalStorageAdapter,
  IndexedDBAdapter,
};
