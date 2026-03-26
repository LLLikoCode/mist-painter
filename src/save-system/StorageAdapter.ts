/**
 * 迷雾绘者 - 存储适配器
 * Storage Adapters for LocalStorage and IndexedDB
 */

import { StorageAdapter, SaveError, SaveErrorType } from './types';

// ==================== LocalStorage 适配器 ====================

export class LocalStorageAdapter implements StorageAdapter {
  private readonly prefix: string;

  constructor(prefix: string = 'mist_painter_') {
    this.prefix = prefix;
  }

  async get(key: string): Promise<string | null> {
    try {
      const value = localStorage.getItem(this.prefix + key);
      return value;
    } catch (e) {
      throw new SaveError(
        SaveErrorType.PERMISSION_DENIED,
        `Failed to read from localStorage: ${e}`,
        e as Error
      );
    }
  }

  async set(key: string, value: string): Promise<void> {
    try {
      localStorage.setItem(this.prefix + key, value);
    } catch (e) {
      if (e instanceof Error && e.name === 'QuotaExceededError') {
        throw new SaveError(
          SaveErrorType.STORAGE_FULL,
          'Storage quota exceeded',
          e
        );
      }
      throw new SaveError(
        SaveErrorType.PERMISSION_DENIED,
        `Failed to write to localStorage: ${e}`,
        e as Error
      );
    }
  }

  async remove(key: string): Promise<void> {
    try {
      localStorage.removeItem(this.prefix + key);
    } catch (e) {
      throw new SaveError(
        SaveErrorType.PERMISSION_DENIED,
        `Failed to remove from localStorage: ${e}`,
        e as Error
      );
    }
  }

  async keys(): Promise<string[]> {
    try {
      const keys: string[] = [];
      for (let i = 0; i < localStorage.length; i++) {
        const key = localStorage.key(i);
        if (key && key.startsWith(this.prefix)) {
          keys.push(key.slice(this.prefix.length));
        }
      }
      return keys;
    } catch (e) {
      throw new SaveError(
        SaveErrorType.PERMISSION_DENIED,
        `Failed to list localStorage keys: ${e}`,
        e as Error
      );
    }
  }

  async clear(): Promise<void> {
    try {
      const keysToRemove: string[] = [];
      for (let i = 0; i < localStorage.length; i++) {
        const key = localStorage.key(i);
        if (key && key.startsWith(this.prefix)) {
          keysToRemove.push(key);
        }
      }
      keysToRemove.forEach(key => localStorage.removeItem(key));
    } catch (e) {
      throw new SaveError(
        SaveErrorType.PERMISSION_DENIED,
        `Failed to clear localStorage: ${e}`,
        e as Error
      );
    }
  }

  async getSize(): Promise<number> {
    let size = 0;
    try {
      for (let i = 0; i < localStorage.length; i++) {
        const key = localStorage.key(i);
        if (key && key.startsWith(this.prefix)) {
          const value = localStorage.getItem(key) || '';
          size += key.length + value.length;
        }
      }
      return size * 2; // UTF-16 encoding
    } catch (e) {
      return 0;
    }
  }

  async getQuota(): Promise<number | null> {
    // LocalStorage typically has a 5-10MB limit
    return 5 * 1024 * 1024; // 5MB
  }
}

// ==================== IndexedDB 适配器 ====================

export class IndexedDBAdapter implements StorageAdapter {
  private readonly dbName: string;
  private readonly storeName: string;
  private db: IDBDatabase | null = null;

  constructor(dbName: string = 'MistPainterSaves', storeName: string = 'saves') {
    this.dbName = dbName;
    this.storeName = storeName;
  }

  private async getDB(): Promise<IDBDatabase> {
    if (this.db) return this.db;

    return new Promise((resolve, reject) => {
      const request = indexedDB.open(this.dbName, 1);

      request.onerror = () => {
        reject(new SaveError(
          SaveErrorType.PERMISSION_DENIED,
          'Failed to open IndexedDB'
        ));
      };

      request.onsuccess = () => {
        this.db = request.result;
        resolve(this.db);
      };

      request.onupgradeneeded = (event) => {
        const db = (event.target as IDBOpenDBRequest).result;
        if (!db.objectStoreNames.contains(this.storeName)) {
          db.createObjectStore(this.storeName);
        }
      };
    });
  }

  async get(key: string): Promise<string | null> {
    const db = await this.getDB();
    return new Promise((resolve, reject) => {
      const transaction = db.transaction(this.storeName, 'readonly');
      const store = transaction.objectStore(this.storeName);
      const request = store.get(key);

      request.onsuccess = () => {
        resolve(request.result as string | null);
      };

      request.onerror = () => {
        reject(new SaveError(
          SaveErrorType.UNKNOWN,
          `Failed to read key "${key}" from IndexedDB`
        ));
      };
    });
  }

  async set(key: string, value: string): Promise<void> {
    const db = await this.getDB();
    return new Promise((resolve, reject) => {
      const transaction = db.transaction(this.storeName, 'readwrite');
      const store = transaction.objectStore(this.storeName);
      const request = store.put(value, key);

      request.onsuccess = () => {
        resolve();
      };

      request.onerror = () => {
        reject(new SaveError(
          SaveErrorType.STORAGE_FULL,
          `Failed to write key "${key}" to IndexedDB`
        ));
      };
    });
  }

  async remove(key: string): Promise<void> {
    const db = await this.getDB();
    return new Promise((resolve, reject) => {
      const transaction = db.transaction(this.storeName, 'readwrite');
      const store = transaction.objectStore(this.storeName);
      const request = store.delete(key);

      request.onsuccess = () => {
        resolve();
      };

      request.onerror = () => {
        reject(new SaveError(
          SaveErrorType.UNKNOWN,
          `Failed to delete key "${key}" from IndexedDB`
        ));
      };
    });
  }

  async keys(): Promise<string[]> {
    const db = await this.getDB();
    return new Promise((resolve, reject) => {
      const transaction = db.transaction(this.storeName, 'readonly');
      const store = transaction.objectStore(this.storeName);
      const request = store.getAllKeys();

      request.onsuccess = () => {
        resolve(request.result as string[]);
      };

      request.onerror = () => {
        reject(new SaveError(
          SaveErrorType.UNKNOWN,
          'Failed to list keys from IndexedDB'
        ));
      };
    });
  }

  async clear(): Promise<void> {
    const db = await this.getDB();
    return new Promise((resolve, reject) => {
      const transaction = db.transaction(this.storeName, 'readwrite');
      const store = transaction.objectStore(this.storeName);
      const request = store.clear();

      request.onsuccess = () => {
        resolve();
      };

      request.onerror = () => {
        reject(new SaveError(
          SaveErrorType.UNKNOWN,
          'Failed to clear IndexedDB'
        ));
      };
    });
  }

  async getSize(): Promise<number> {
    const db = await this.getDB();
    return new Promise((resolve, reject) => {
      const transaction = db.transaction(this.storeName, 'readonly');
      const store = transaction.objectStore(this.storeName);
      const request = store.getAll();

      request.onsuccess = () => {
        const values = request.result as string[];
        const size = values.reduce((acc, val) => acc + val.length * 2, 0);
        resolve(size);
      };

      request.onerror = () => {
        resolve(0);
      };
    });
  }

  async getQuota(): Promise<number | null> {
    // IndexedDB typically has a much larger limit (varies by browser)
    // Return null to indicate "unlimited" or browser-dependent
    return null;
  }
}

// ==================== 存储适配器工厂 ====================

export class Storage