/**
 * AsyncUtils
 * 异步工具函数 - 提供常用的异步操作辅助
 */

/**
 * 延迟指定时间
 * @param ms 毫秒数
 */
export function delay(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}

/**
 * 带超时的 Promise
 * @param promise 原始 Promise
 * @param timeoutMs 超时时间（毫秒）
 * @param timeoutMessage 超时错误消息
 */
export function withTimeout<T>(
  promise: Promise<T>,
  timeoutMs: number,
  timeoutMessage: string = 'Operation timed out'
): Promise<T> {
  return Promise.race([
    promise,
    new Promise<T>((_, reject) => {
      setTimeout(() => reject(new Error(timeoutMessage)), timeoutMs);
    })
  ]);
}

/**
 * 重试异步操作
 * @param operation 异步操作
 * @param maxRetries 最大重试次数
 * @param delayMs 重试间隔（毫秒）
 * @param shouldRetry 自定义重试条件
 */
export async function retry<T>(
  operation: () => Promise<T>,
  maxRetries: number = 3,
  delayMs: number = 1000,
  shouldRetry?: (error: Error) => boolean
): Promise<T> {
  let lastError: Error | undefined;
  
  for (let attempt = 0; attempt <= maxRetries; attempt++) {
    try {
      return await operation();
    } catch (error) {
      lastError = error as Error;
      
      // 检查是否应该重试
      if (attempt < maxRetries && (!shouldRetry || shouldRetry(lastError))) {
        if (delayMs > 0) {
          await delay(delayMs);
        }
      } else {
        throw lastError;
      }
    }
  }
  
  throw lastError || new Error('Retry failed');
}

/**
 * 带指数退避的重试
 * @param operation 异步操作
 * @param maxRetries 最大重试次数
 * @param initialDelayMs 初始延迟（毫秒）
 * @param maxDelayMs 最大延迟（毫秒）
 */
export async function retryWithBackoff<T>(
  operation: () => Promise<T>,
  maxRetries: number = 3,
  initialDelayMs: number = 1000,
  maxDelayMs: number = 30000
): Promise<T> {
  let delayMs = initialDelayMs;
  
  return retry(
    operation,
    maxRetries,
    0,
    () => {
      const shouldRetry = true;
      if (shouldRetry) {
        delayMs = Math.min(delayMs * 2, maxDelayMs);
      }
      return shouldRetry;
    }
  );
}

/**
 * 防抖函数
 * @param fn 原函数
 * @param delayMs 防抖延迟（毫秒）
 */
export function debounce<T extends (...args: unknown[]) => unknown>(
  fn: T,
  delayMs: number
): (...args: Parameters<T>) => void {
  let timeoutId: ReturnType<typeof setTimeout> | null = null;
  
  return (...args: Parameters<T>) => {
    if (timeoutId) {
      clearTimeout(timeoutId);
    }
    
    timeoutId = setTimeout(() => {
      fn(...args);
      timeoutId = null;
    }, delayMs);
  };
}

/**
 * 节流函数
 * @param fn 原函数
 * @param intervalMs 节流间隔（毫秒）
 */
export function throttle<T extends (...args: unknown[]) => unknown>(
  fn: T,
  intervalMs: number
): (...args: Parameters<T>) => void {
  let lastExecution = 0;
  let timeoutId: ReturnType<typeof setTimeout> | null = null;
  
  return (...args: Parameters<T>) => {
    const now = Date.now();
    
    if (now - lastExecution >= intervalMs) {
      fn(...args);
      lastExecution = now;
    } else if (!timeoutId) {
      timeoutId = setTimeout(() => {
        fn(...args);
        lastExecution = Date.now();
        timeoutId = null;
      }, intervalMs - (now - lastExecution));
    }
  };
}

/**
 * 并行执行多个 Promise，限制并发数
 * @param tasks 任务数组
 * @param concurrency 并发数限制
 */
export async function parallelLimit<T>(
  tasks: (() => Promise<T>)[],
  concurrency: number = 5
): Promise<T[]> {
  const results: T[] = [];
  const executing: Promise<void>[] = [];
  
  for (const [index, task] of tasks.entries()) {
    const promise = task().then(result => {
      results[index] = result;
    });
    
    results.push(undefined as T);
    executing.push(promise);
    
    if (executing.length >= concurrency) {
      await Promise.race(executing);
      executing.splice(executing.findIndex(p => p === promise), 1);
    }
  }
  
  await Promise.all(executing);
  return results;
}

/**
 * 顺序执行多个 Promise
 * @param tasks 任务数组
 */
export async function sequential<T>(
  tasks: (() => Promise<T>)[]
): Promise<T[]> {
  const results: T[] = [];
  
  for (const task of tasks) {
    results.push(await task());
  }
  
  return results;
}

/**
 * 带优先级的任务队列
 */
export class PriorityQueue<T> {
  private _queue: Array<{ item: T; priority: number }> = [];
  
  /**
   * 添加任务
   * @param item 任务项
   * @param priority 优先级（数值越小优先级越高）
   */
  enqueue(item: T, priority: number = 0): void {
    const entry = { item, priority };
    const index = this._queue.findIndex(e => e.priority > priority);
    
    if (index === -1) {
      this._queue.push(entry);
    } else {
      this._queue.splice(index, 0, entry);
    }
  }
  
  /**
   * 取出优先级最高的任务
   */
  dequeue(): T | undefined {
    return this._queue.shift()?.item;
  }
  
  /**
   * 查看优先级最高的任务
   */
  peek(): T | undefined {
    return this._queue[0]?.item;
  }
  
  /**
   * 获取队列长度
   */
  get length(): number {
    return this._queue.length;
  }
  
  /**
   * 检查队列是否为空
   */
  isEmpty(): boolean {
    return this._queue.length === 0;
  }
  
  /**
   * 清空队列
   */
  clear(): void {
    this._queue = [];
  }
}

/**
 * 异步互斥锁
 */
export class AsyncMutex {
  private _locked: boolean = false;
  private _queue: Array<() => void> = [];
  
  /**
   * 获取锁
   */
  async acquire(): Promise<void> {
    if (!this._locked) {
      this._locked = true;
      return;
    }
    
    return new Promise(resolve => {
      this._queue.push(resolve);
    });
  }
  
  /**
   * 释放锁
   */
  release(): void {
    if (this._queue.length > 0) {
      const next = this._queue.shift();
      next?.();
    } else {
      this._locked = false;
    }
  }
  
  /**
   * 在锁保护下执行操作
   * @param fn 要执行的函数
   */
  async runExclusive<T>(fn: () => Promise<T>): Promise<T> {
    await this.acquire();
    try {
      return await fn();
    } finally {
      this.release();
    }
  }
}

/**
 * 信号量
 */
export class Semaphore {
  private _available: number;
  private _queue: Array<() => void> = [];
  
  constructor(capacity: number) {
    this._available = capacity;
  }
  
  /**
   * 获取许可
   */
  async acquire(): Promise<void> {
    if (this._available > 0) {
      this._available--;
      return;
    }
    
    return new Promise(resolve => {
      this._queue.push(resolve);
    });
  }
  
  /**
   * 释放许可
   */
  release(): void {
    if (this._queue.length > 0) {
      const next = this._queue.shift();
      next?.();
    } else {
      this._available++;
    }
  }
}

/**
 * 取消令牌
 * 用于取消异步操作
 */
export class CancellationToken {
  private _cancelled: boolean = false;
  private _callbacks: Array<() => void> = [];
  
  /**
   * 是否已取消
   */
  get isCancelled(): boolean {
    return this._cancelled;
  }
  
  /**
   * 取消
   */
  cancel(): void {
    if (this._cancelled) return;
    
    this._cancelled = true;
    this._callbacks.forEach(cb => cb());
    this._callbacks = [];
  }
  
  /**
   * 注册取消回调
   * @param callback 取消时执行的回调
   */
  onCancelled(callback: () => void): void {
    if (this._cancelled) {
      callback();
    } else {
      this._callbacks.push(callback);
    }
  }
  
  /**
   * 如果已取消则抛出错误
   */
  throwIfCancelled(): void {
    if (this._cancelled) {
      throw new Error('Operation was cancelled');
    }
  }
}
