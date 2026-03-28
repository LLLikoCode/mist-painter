/**
 * EventBus 实现
 * 类型安全的事件订阅和发布系统
 */

import {
  IEventBus,
  IEvent,
  IEventSubscription,
  EventType,
  EventHandler
} from '../interfaces/IEventBus';

/**
 * 事件订阅实现
 */
class EventSubscription implements IEventSubscription {
  public subscriptionId: string;
  
  constructor(
    public eventType: EventType,
    private eventBus: EventBus,
    id?: string
  ) {
    this.subscriptionId = id || this.generateId();
  }
  
  private generateId(): string {
    return `${this.eventType}_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }
  
  unsubscribe(): void {
    this.eventBus.unsubscribe(this);
  }
}

/**
 * 事件实现
 */
class Event implements IEvent {
  public timestamp: number;
  
  constructor(
    public type: EventType,
    public data: Record<string, unknown>,
    public source?: string
  ) {
    this.timestamp = Date.now();
  }
}

/**
 * 事件总线实现
 * 单例模式
 */
export class EventBus implements IEventBus {
  private static _instance: EventBus | null = null;
  
  /**
   * 获取单例实例
   */
  public static getInstance(): EventBus {
    if (!EventBus._instance) {
      EventBus._instance = new EventBus();
    }
    return EventBus._instance;
  }
  
  /**
   * 销毁单例
   */
  public static destroy(): void {
    if (EventBus._instance) {
      EventBus._instance.clearAllListeners();
      EventBus._instance = null;
    }
  }
  
  // 监听器存储
  private _listeners: Map<EventType, Map<string, EventHandler>> = new Map();
  
  // 一次性监听器
  private _oneShotListeners: Map<EventType, Map<string, EventHandler>> = new Map();
  
  // 事件队列（用于延迟处理）
  private _eventQueue: Array<IEvent> = [];
  private _processingQueue: boolean = false;
  
  // 调试模式
  private _debugMode: boolean = false;
  
  private constructor() {
    // 私有构造函数，确保单例
  }
  
  /**
   * 订阅事件
   */
  subscribe<T extends IEvent>(
    eventType: EventType,
    handler: EventHandler<T>
  ): IEventSubscription {
    if (!this._listeners.has(eventType)) {
      this._listeners.set(eventType, new Map());
    }
    
    const subscription = new EventSubscription(eventType, this);
    this._listeners.get(eventType)!.set(
      subscription.subscriptionId,
      handler as EventHandler
    );
    
    if (this._debugMode) {
      console.log(`EventBus: Subscribed to ${eventType}, ID: ${subscription.subscriptionId}`);
    }
    
    return subscription;
  }
  
  /**
   * 订阅事件（一次性）
   */
  subscribeOnce<T extends IEvent>(
    eventType: EventType,
    handler: EventHandler<T>
  ): IEventSubscription {
    if (!this._oneShotListeners.has(eventType)) {
      this._oneShotListeners.set(eventType, new Map());
    }
    
    const subscription = new EventSubscription(eventType, this);
    this._oneShotListeners.get(eventType)!.set(
      subscription.subscriptionId,
      handler as EventHandler
    );
    
    if (this._debugMode) {
      console.log(`EventBus: Subscribed once to ${eventType}, ID: ${subscription.subscriptionId}`);
    }
    
    return subscription;
  }
  
  /**
   * 取消订阅
   */
  unsubscribe(subscription: IEventSubscription): void {
    // 从普通监听器中移除
    const listeners = this._listeners.get(subscription.eventType);
    if (listeners) {
      listeners.delete(subscription.subscriptionId);
      if (listeners.size === 0) {
        this._listeners.delete(subscription.eventType);
      }
    }
    
    // 从一次性监听器中移除
    const oneShotListeners = this._oneShotListeners.get(subscription.eventType);
    if (oneShotListeners) {
      oneShotListeners.delete(subscription.subscriptionId);
      if (oneShotListeners.size === 0) {
        this._oneShotListeners.delete(subscription.eventType);
      }
    }
    
    if (this._debugMode) {
      console.log(`EventBus: Unsubscribed from ${subscription.eventType}, ID: ${subscription.subscriptionId}`);
    }
  }
  
  /**
   * 发布事件（立即执行）
   */
  emit<T extends Record<string, unknown> = Record<string, unknown>>(
    eventType: EventType,
    data?: T,
    source?: string
  ): void {
    const event = new Event(
      eventType,
      data || {},
      source
    );
    
    if (this._debugMode) {
      console.log(`EventBus: Emitting ${eventType}`, data);
    }
    
    // 执行普通监听器
    const listeners = this._listeners.get(eventType);
    if (listeners) {
      for (const handler of listeners.values()) {
        try {
          handler(event);
        } catch (error) {
          console.error(`EventBus: Error in handler for ${eventType}:`, error);
        }
      }
    }
    
    // 执行一次性监听器
    const oneShotListeners = this._oneShotListeners.get(eventType);
    if (oneShotListeners) {
      for (const handler of oneShotListeners.values()) {
        try {
          handler(event);
        } catch (error) {
          console.error(`EventBus: Error in one-shot handler for ${eventType}:`, error);
        }
      }
      // 清除一次性监听器
      this._oneShotListeners.delete(eventType);
    }
  }
  
  /**
   * 发布事件（延迟执行）
   */
  emitDeferred<T extends Record<string, unknown> = Record<string, unknown>>(
    eventType: EventType,
    data?: T,
    source?: string
  ): void {
    const event = new Event(
      eventType,
      data || {},
      source
    );
    
    this._eventQueue.push(event);
    
    // 如果不在处理队列，开始处理
    if (!this._processingQueue) {
      this._processEventQueue();
    }
  }
  
  /**
   * 处理事件队列
   */
  private _processEventQueue(): void {
    this._processingQueue = true;
    
    // 使用 setTimeout 实现延迟执行
    setTimeout(() => {
      while (this._eventQueue.length > 0) {
        const event = this._eventQueue.shift();
        if (event) {
          this.emit(event.type, event.data, event.source);
        }
      }
      this._processingQueue = false;
    }, 0);
  }
  
  /**
   * 清空特定事件的所有监听器
   */
  clearEventListeners(eventType: EventType): void {
    this._listeners.delete(eventType);
    this._oneShotListeners.delete(eventType);
    
    if (this._debugMode) {
      console.log(`EventBus: Cleared all listeners for ${eventType}`);
    }
  }
  
  /**
   * 清空所有监听器
   */
  clearAllListeners(): void {
    this._listeners.clear();
    this._oneShotListeners.clear();
    this._eventQueue = [];
    
    if (this._debugMode) {
      console.log('EventBus: All listeners cleared');
    }
  }
  
  /**
   * 获取事件的监听器数量
   */
  getListenerCount(eventType: EventType): number {
    let count = 0;
    
    const listeners = this._listeners.get(eventType);
    if (listeners) {
      count += listeners.size;
    }
    
    const oneShotListeners = this._oneShotListeners.get(eventType);
    if (oneShotListeners) {
      count += oneShotListeners.size;
    }
    
    return count;
  }
  
  /**
   * 检查是否有监听器
   */
  hasListeners(eventType: EventType): boolean {
    return this.getListenerCount(eventType) > 0;
  }
  
  /**
   * 设置调试模式
   */
  setDebugMode(enabled: boolean): void {
    this._debugMode = enabled;
    console.log(`EventBus: Debug mode ${enabled ? 'enabled' : 'disabled'}`);
  }
  
  /**
   * 获取所有注册的事件类型
   */
  getRegisteredEventTypes(): EventType[] {
    const types = new Set<EventType>();
    
    for (const type of this._listeners.keys()) {
      types.add(type);
    }
    
    for (const type of this._oneShotListeners.keys()) {
      types.add(type);
    }
    
    return Array.from(types);
  }
  
  /**
   * 获取总监听器数量
   */
  getTotalListenerCount(): number {
    let total = 0;
    
    for (const listeners of this._listeners.values()) {
      total += listeners.size;
    }
    
    for (const listeners of this._oneShotListeners.values()) {
      total += listeners.size;
    }
    
    return total;
  }
  
  /**
   * 获取调试信息
   */
  getDebugInfo(): Record<string, unknown> {
    const eventCounts: Record<string, number> = {};
    
    for (const [type, listeners] of this._listeners.entries()) {
      eventCounts[type] = listeners.size;
    }
    
    for (const [type, listeners] of this._oneShotListeners.entries()) {
      eventCounts[type] = (eventCounts[type] || 0) + listeners.size;
    }
    
    return {
      debugMode: this._debugMode,
      totalListeners: this.getTotalListenerCount(),
      eventQueueLength: this._eventQueue.length,
      eventCounts,
      registeredEventTypes: this.getRegisteredEventTypes()
    };
  }
}

// 导出单例获取函数
export const eventBus = EventBus.getInstance();
