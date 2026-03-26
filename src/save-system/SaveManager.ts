/**
 * 迷雾绘者 - 存档管理器
 * Save Manager - Core save/load functionality
 */

import {
  SaveData,
  SaveSlotInfo,
  SaveType,
  SaveError,
  SaveErrorType,
  StorageAdapter,
  SaveSystemConfig,
  AutoSaveConfig,
  AutoSaveTrigger,
} from './types';
import { SaveEncryptor, EncryptionConfig } from './SaveEncryptor';

export interface SaveManagerOptions {
  storage: StorageAdapter;
  config: SaveSystemConfig;
}

export class SaveManager {
  private storage: StorageAdapter;
  private config: SaveSystemConfig;
  private encryptor: SaveEncryptor;
  private autoSaveTimer: number | null = null;
  private currentPlayTime: number = 0;
  private lastSaveTime: number = Date.now();
  private autoSaveConfig: AutoSaveConfig;

  constructor(options: SaveManagerOptions) {
    this.storage = options.storage;
    this.config = options.config;
    
    const encryptionConfig: EncryptionConfig = {
      enabled: this.config.enableEncryption,
      key: this.config.encryptionKey || SaveEncryptor.generateDeviceFingerprint(),
    };
    this.encryptor = new SaveEncryptor(encryptionConfig);

    this.autoSaveConfig = {
      enabled: this.config.autoSaveInterval > 0,
      interval: this.config.autoSaveInterval * 60 * 1000, // 转换为毫秒
      maxAutoSaves: this.config.maxAutoSaves,
      triggers: [
        AutoSaveTrigger.INTERVAL,
        AutoSaveTrigger.CHECKPOINT,
        AutoSaveTrigger.LAYER_CHANGE,
      ],
    };
  }

  // ==================== 核心存档方法 ====================

  /**
   * 保存到指定槽位
   */
  async save(slotId: number, data: SaveData): Promise<void> {
    if (slotId < 1 || slotId > this.config.maxManualSlots) {
      throw new SaveError(
        SaveErrorType.INVALID_DATA,
        `Invalid slot ID: ${slotId}. Must be between 1 and ${this.config.maxManualSlots}`
      );
    }

    // 更新元数据
    const saveData: SaveData = {
      ...data,
      version: this.config.version,
      gameVersion: this.config.gameVersion,
      timestamp: Date.now(),
      saveType: SaveType.MANUAL,
    };

    // 序列化和加密
    const serialized = JSON.stringify(saveData);
    const encrypted = this.encryptor.encrypt(serialized);

    // 存储
    const key = `manual_${slotId}`;
    await this.storage.set(key, encrypted);

    // 更新槽位信息
    await this.updateSlotInfo(slotId, saveData);

    this.lastSaveTime = Date.now();
  }

  /**
   * 从指定槽位加载
   */
  async load(slotId: number): Promise<SaveData> {
    if (slotId < 1 || slotId > this.config.maxManualSlots) {
      throw new SaveError(
        SaveErrorType.INVALID_DATA,
        `Invalid slot ID: ${slotId}`
      );
    }

    const key = `manual_${slotId}`;
    const encrypted = await this.storage.get(key);

    if (!encrypted) {
      throw new SaveError(
        SaveErrorType.NOT_FOUND,
        `No save data found in slot ${slotId}`
      );
    }

    return this.parseSaveData(encrypted);
  }

  /**
   * 删除指定槽位的存档
   */
  async delete(slotId: number): Promise<void> {
    if (slotId < 1 || slotId > this.config.maxManualSlots) {
      throw new SaveError(
        SaveErrorType.INVALID_DATA,
        `Invalid slot ID: ${slotId}`
      );
    }

    const key = `manual_${slotId}`;
    await this.storage.remove(key);
    await this.storage.remove(`info_${slotId}`);
  }

  /**
   * 检查槽位是否存在存档
   */
  async exists(slotId: number): Promise<boolean> {
    const key = `manual_${slotId}`;
    const data = await this.storage.get(key);
    return data !== null;
  }

  // ==================== 自动存档 ====================

  /**
   * 自动存档
   */
  async autoSave(data: SaveData): Promise<void> {
    const autoSaveIndex = await this.getNextAutoSaveIndex();
    
    const saveData: SaveData = {
      ...data,
      version: this.config.version,
      gameVersion: this.config.gameVersion,
      timestamp: Date.now(),
      saveType: SaveType.AUTO,
    };

    const serialized = JSON.stringify(saveData);
    const encrypted = this.encryptor.encrypt(serialized);

    const key = `auto_${autoSaveIndex}`;
    await this.storage.set(key, encrypted);

    this.lastSaveTime = Date.now();
  }

  /**
   * 获取最新的自动存档
   */
  async getLatestAutoSave(): Promise<SaveData | null> {
    const autoSaves = await this.listAutoSaves();
    if (autoSaves.length === 0) return null;

    autoSaves.sort((a, b) => b.timestamp - a.timestamp);
    const latest = autoSaves[0];

    const key = `auto_${latest.index}`;
    const encrypted = await this.storage.get(key);
    
    if (!encrypted) return null;

    return this.parseSaveData(encrypted);
  }

  /**
   * 列出所有自动存档
   */
  async listAutoSaves(): Promise<{ index: number; timestamp: number }[]> {
    const keys = await this.storage.keys();
    const autoSaveKeys = keys.filter(k => k.startsWith('auto_'));
    
    const autoSaves: { index: number; timestamp: number }[] = [];
    
    for (const key of autoSaveKeys) {
      const index = parseInt(key.split('_')[1], 10);
      const encrypted = await this.storage.get(key);
      if (encrypted) {
        try {
          const data = this.parseSaveData(encrypted);
          autoSaves.push({ index, timestamp: data.timestamp });
        } catch (e) {
          // 忽略损坏的自动存档
        }
      }
    }

    return autoSaves;
  }

  /**
   * 清除所有自动存档
   */
  async clearAutoSaves(): Promise<void> {
    const keys = await this.storage.keys();
    const autoSaveKeys = keys.filter(k => k.startsWith('auto_'));
    
    for (const key of autoSaveKeys) {
      await this.storage.remove(key);
    }
  }

  // ==================== 导入/导出 ====================

  /**
   * 导出存档为字符串（用于分享或备份）
   */
  async exportSave(slotId: number): Promise<string> {
    const data = await this.load(slotId);
    const serialized = JSON.stringify(data);
    return SaveEncryptor.encodeBase64(serialized);
  }

  /**
   * 从字符串导入存档
   */
  async importSave(data: string, targetSlotId?: number): Promise<number> {
    let serialized: string;
    
    try {
      serialized = SaveEncryptor.decodeBase64(data);
    } catch (e) {
      try {
        JSON.parse(data);
        serialized = data;
      } catch {
        throw new SaveError(
          SaveErrorType.INVALID_DATA,
          'Invalid import data format'
        );
      }
    }

    const saveData: SaveData = JSON.parse(serialized);

    if (!this.validateSaveData(saveData)) {
      throw new SaveError(
        SaveErrorType.INVALID_DATA,
        'Invalid save data structure'
      );
    }

    if (saveData.version !== this.config.version) {
      saveData.version = this.config.version;
    }

    let slotId = targetSlotId;
    if (!slotId) {
      slotId = await this.findEmptySlot();
      if (!slotId) {
        slotId = await this.findOldestSlot();
      }
    }

    await this.save(slotId, saveData);
    return slotId;
  }

  /**
   * 导出为 JSON 文件内容
   */
  async exportToJson(slotId: number): Promise<string> {
    const data = await this.load(slotId);
    return JSON.stringify(data, null, 2);
  }

  // ==================== 槽位管理 ====================

  /**
   * 获取所有槽位信息
   */
  async getSlotInfos(): Promise<SaveSlotInfo[]> {
    const infos: SaveSlotInfo[] = [];

    for (let i = 1; i <= this.config.maxManualSlots; i++) {
      const info = await this.getSlotInfo(i);
      infos.push(info);
    }

    return infos;
  }

  /**
   * 获取单个槽位信息
   */
  async getSlotInfo(slotId: number): Promise<SaveSlotInfo> {
    const infoKey = `info_${slotId}`;
    const infoData = await this.storage.get(infoKey);

    if (infoData) {
      try {
        const info: SaveSlotInfo = JSON.parse(infoData);
        const exists = await this.exists(slotId);
        if (!exists) {
          return {
            slotId,
            exists: false,
            timestamp: null,
            playTime: null,
            playerLevel: null,
            currentLayer: null,
            thumbnail: null,
          };
        }
        return info;
      } catch (e) {
        // 信息损坏
      }
    }

    // 检查是否有存档但没有信息
    const exists = await this.exists(slotId);
    if (exists) {
      try {
        const data = await this.load(slotId);
        const info: SaveSlotInfo = {
          slotId,
          exists: true,
          timestamp: data.timestamp,
          playTime: data.playTime,
          playerLevel: data.player.level,
          currentLayer: data.world.currentLayer,
          thumbnail: null,
        };
        await this.storage.set(infoKey, JSON.stringify(info));
        return info;
      } catch (e) {
        // 存档损坏
      }
    }

    return {
      slotId,
      exists: false,
      timestamp: null,
      playTime: null,
      playerLevel: null,
      currentLayer: null,
      thumbnail: null,
    };
  }

  /**
   * 更新槽位信息
   */
  private async updateSlotInfo(slotId: number, data: SaveData): Promise<void> {
    const info: SaveSlotInfo = {
      slotId,
      exists: true,
      timestamp: data.timestamp,
      playTime: data.playTime,
      playerLevel: data.player.level,
      currentLayer: data.world.currentLayer,
      thumbnail: null,
    };
    await this.storage.set(`info_${slotId}`, JSON.stringify(info));
  }

  /**
   * 查找空槽位
   */
  async findEmptySlot(): Promise<number | null> {
    for (let i = 1; i <= this.config.maxManualSlots; i++) {
      const exists = await this.exists(i);
      if (!exists) return i;
    }
    return null;
  }

  /**
   * 查找最旧的槽位
   */
  async findOldestSlot(): Promise<number> {
    const infos = await this.getSlotInfos();
    const existing = infos.filter(i => i.exists && i.timestamp !== null);
    
    if (existing.length === 0) return 1;
    
    existing.sort((a, b) => (a.timestamp || 0) - (b.timestamp || 0));
    return existing[0].slotId;
  }

  // ==================== 自动存档管理 ====================

  /**
   * 获取下一个自动存档索引
   */
  private async getNextAutoSaveIndex(): Promise<number> {
    const autoSaves = await this.listAutoSaves();
    
    if (autoSaves.length < this.config.maxAutoSaves) {
      // 还有空位
      const usedIndices = autoSaves.map(a => a.index);
      for (let i = 0; i < this.config.maxAutoSaves; i++) {
        if (!usedIndices.includes(i)) return i;
      }
    }
    
    // 循环覆盖最旧的
    autoSaves.sort((a, b) => a.timestamp - b.timestamp);
    return autoSaves[0].index;
  }

  /**
   * 启动自动存档定时器
   */
  startAutoSaveTimer(callback: () => Promise<SaveData>): void {
    if (!this.autoSaveConfig.enabled) return;
    
    this.stopAutoSaveTimer();
    
    this.autoSaveTimer = window.setInterval(async () => {
      if (this.autoSaveConfig.triggers.includes(AutoSaveTrigger.INTERVAL)) {
        try {
          const data = await callback();
          await this.autoSave(data);
        } catch (e) {
          console.error('Auto-save failed:', e);
        }
      }
    }, this.autoSaveConfig.interval);
  }

  /**
   * 停止自动存档定时器
   */
  stopAutoSaveTimer(): void {
    if (this.autoSaveTimer !== null) {
      clearInterval(this.autoSaveTimer);
      this.autoSaveTimer = null;
    }
  }

  /**
   * 触发检查点存档
   */
  async triggerCheckpoint(data: SaveData): Promise<void> {
    if (this.autoSaveConfig.triggers.includes(AutoSaveTrigger.CHECKPOINT)) {
      await this.autoSave({
        ...data,
        saveType: SaveType.CHECKPOINT,
      });
    }
  }

  // ==================== 工具方法 ====================

  /**
   * 解析存档数据
   */
  private parseSaveData(encrypted: string): SaveData {
    try {
      const decrypted = this.encryptor.decrypt(encrypted);
      const data: SaveData = JSON.parse(decrypted);
      
      if (!this.validateSaveData(data)) {
        throw new SaveError(
          SaveErrorType.CORRUPTED,
          'Invalid save data structure'
        );
      }
      
      return data;
    } catch (e) {
      if (e instanceof SaveError) throw e;
      throw new SaveError(
        SaveErrorType.CORRUPTED,
        'Failed to parse save data',
        e as Error
      );
    }
  }

  /**
   * 验证存档数据结构
   */
  private validateSaveData(data: unknown): boolean {
    if (!data || typeof data !== 'object') return false;
    
    const save = data as Partial<SaveData>;
    
    return (
      typeof save.version === 'string' &&
      typeof save.timestamp === 'number' &&
      save.player !== undefined &&
      save.world !== undefined &&
      save.settings !== undefined &&
      save.statistics !== undefined
    );
  }

  /**
   * 获取存储使用情况
   */
  async getStorageUsage(): Promise<{ used: number; quota: number | null }> {
    const used = await this.storage.getSize();
    const quota = await this.storage.getQuota();
    return { used, quota };
  }

  /**
   * 删除所有存档
   */
  async deleteAll(): Promise<void> {
    await this.storage.clear();
  }
}
