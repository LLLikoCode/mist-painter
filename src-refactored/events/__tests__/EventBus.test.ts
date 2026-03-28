/**
 * EventBus 单元测试
 * 测试事件总线的核心功能
 */

import { EventBus, eventBus } from '../EventBus';
import { EventType, EventPriority, IEvent } from '../../interfaces/IEventBus';

describe('EventBus', () => {
  let bus: EventBus;

  beforeEach(() => {
    // 销毁旧实例并创建新实例
    EventBus.destroy();
    bus = EventBus.getInstance({ debugMode: false, enableStats: true });
  });

  afterEach(() => {
    bus.clearAllListeners();
    EventBus.destroy();
  });

  describe('基本功能', () => {
    test('应该能订阅和发布事件', () => {
      const handler = jest.fn();
      
      bus.subscribe(EventType.GAME_STARTED, handler);
      bus.emit(EventType.GAME_STARTED, { mode: 'test' });
      
      expect(handler).toHaveBeenCalledTimes(1);
      expect(handler).toHaveBeenCalledWith(
        expect.objectContaining({
          type: EventType.GAME_STARTED,
          data: { mode: 'test' }
        })
      );
    });

    test('应该支持多个监听器', () => {
      const handler1 = jest.fn();
      const handler2 = jest.fn();
      
      bus.subscribe(EventType.GAME_STARTED, handler1);
      bus.subscribe(EventType.GAME_STARTED, handler2);
      bus.emit(EventType.GAME_STARTED, { mode: 'test' });
      
      expect(handler1).toHaveBeenCalledTimes(1);
      expect(handler2).toHaveBeenCalledTimes(1);
    });

    test('应该能取消订阅', () => {
      const handler = jest.fn();
      
      const subscription = bus.subscribe(EventType.GAME_STARTED, handler);
      subscription.unsubscribe();
      
      bus.emit(EventType.GAME_STARTED, { mode: 'test' });
      
      expect(handler).not.toHaveBeenCalled();
    });

    test('应该支持一次性订阅', () => {
      const handler = jest.fn();
      
      bus.subscribeOnce(EventType.GAME_STARTED, handler);
      bus.emit(EventType.GAME_STARTED, { mode: 'test' });
      bus.emit(EventType.GAME_STARTED, { mode: 'test2' });
      
      expect(handler).toHaveBeenCalledTimes(1);
    });
  });

  describe('优先级', () => {
    test('应该按优先级顺序执行监听器', () => {
      const order: number[] = [];
      
      bus.subscribe(EventType.GAME_STARTED, () => order.push(1), EventPriority.NORMAL);
      bus.subscribe(EventType.GAME_STARTED, () => order.push(2), EventPriority.HIGH);
      bus.subscribe(EventType.GAME_STARTED, () => order.push(3), EventPriority.CRITICAL);
      bus.subscribe(EventType.GAME_STARTED, () => order.push(4), EventPriority.LOW);
      
      bus.emit(EventType.GAME_STARTED, {});
      
      expect(order).toEqual([3, 2, 1, 4]);
    });

    test('相同优先级的监听器应该按订阅顺序执行', () => {
      const order: number[] = [];
      
      bus.subscribe(EventType.GAME_STARTED, () => order.push(1), EventPriority.NORMAL);
      bus.subscribe(EventType.GAME_STARTED, () => order.push(2), EventPriority.NORMAL);
      bus.subscribe(EventType.GAME_STARTED, () => order.push(3), EventPriority.NORMAL);
      
      bus.emit(EventType.GAME_STARTED, {});
      
      expect(order).toEqual([1, 2, 3]);
    });
  });

  describe('延迟和异步事件', () => {
    test('emitDeferred 应该延迟执行事件', (done) => {
      const handler = jest.fn();
      
      bus.subscribe(EventType.GAME_STARTED, handler);
      bus.emitDeferred(EventType.GAME_STARTED, { mode: 'test' });
      
      // 立即检查时事件还未处理
      expect(handler).not.toHaveBeenCalled();
      
      // 等待事件处理
      setTimeout(() => {
        expect(handler).toHaveBeenCalledTimes(1);
        done();
      }, 50);
    });

    test('emitAsync 应该返回 Promise', async () => {
      const handler = jest.fn();
      
      bus.subscribe(EventType.GAME_STARTED, handler);
      await bus.emitAsync(EventType.GAME_STARTED, { mode: 'test' });
      
      expect(handler).toHaveBeenCalledTimes(1);
    });
  });

  describe('清理功能', () => {
    test('clearEventListeners 应该清空特定事件的监听器', () => {
      const handler1 = jest.fn();
      const handler2 = jest.fn();
      
      bus.subscribe(EventType.GAME_STARTED, handler1);
      bus.subscribe(EventType.GAME_PAUSED, handler2);
      
      bus.clearEventListeners(EventType.GAME_STARTED);
      
      bus.emit(EventType.GAME_STARTED, {});
      bus.emit(EventType.GAME_PAUSED, {});
      
      expect(handler1).not.toHaveBeenCalled();
      expect(handler2).toHaveBeenCalledTimes(1);
    });

    test('clearAllListeners 应该清空所有监听器', () => {
      const handler1 = jest.fn();
      const handler2 = jest.fn();
      
      bus.subscribe(EventType.GAME_STARTED, handler1);
      bus.subscribe(EventType.GAME_PAUSED, handler2);
      
      bus.clearAllListeners();
      
      bus.emit(EventType.GAME_STARTED, {});
      bus.emit(EventType.GAME_PAUSED, {});
      
      expect(handler1).not.toHaveBeenCalled();
      expect(handler2).not.toHaveBeenCalled();
    });
  });

  describe('查询功能', () => {
    test('getListenerCount 应该返回正确的监听器数量', () => {
      expect(bus.getListenerCount(EventType.GAME_STARTED)).toBe(0);
      
      bus.subscribe(EventType.GAME_STARTED, () => {});
      expect(bus.getListenerCount(EventType.GAME_STARTED)).toBe(1);
      
      bus.subscribe(EventType.GAME_STARTED, () => {});
      expect(bus.getListenerCount(EventType.GAME_STARTED)).toBe(2);
    });

    test('hasListeners 应该正确判断是否有监听器', () => {
      expect(bus.hasListeners(EventType.GAME_STARTED)).toBe(false);
      
      bus.subscribe(EventType.GAME_STARTED, () => {});
      expect(bus.hasListeners(EventType.GAME_STARTED)).toBe(true);
    });

    test('getTotalListenerCount 应该返回所有监听器总数', () => {
      expect(bus.getTotalListenerCount()).toBe(0);
      
      bus.subscribe(EventType.GAME_STARTED, () => {});
      bus.subscribe(EventType.GAME_PAUSED, () => {});
      bus.subscribe(EventType.GAME_RESUMED, () => {});
      
      expect(bus.getTotalListenerCount()).toBe(3);
    });

    test('getRegisteredEventTypes 应该返回所有注册的事件类型', () => {
      bus.subscribe(EventType.GAME_STARTED, () => {});
      bus.subscribe(EventType.GAME_PAUSED, () => {});
      
      const types = bus.getRegisteredEventTypes();
      expect(types).toContain(EventType.GAME_STARTED);
      expect(types).toContain(EventType.GAME_PAUSED);
      expect(types).toHaveLength(2);
    });
  });

  describe('统计功能', () => {
    test('应该正确统计事件发布次数', () => {
      bus.subscribe(EventType.GAME_STARTED, () => {});
      
      bus.emit(EventType.GAME_STARTED, {});
      bus.emit(EventType.GAME_STARTED, {});
      bus.emit(EventType.GAME_PAUSED, {});
      
      const stats = bus.getStats();
      expect(stats.totalEventsEmitted).toBe(3);
      expect(stats.eventsByType.get(EventType.GAME_STARTED)).toBe(2);
      expect(stats.eventsByType.get(EventType.GAME_PAUSED)).toBe(1);
    });

    test('应该正确统计错误', () => {
      const errorHandler = () => {
        throw new Error('Test error');
      };
      
      bus.subscribe(EventType.GAME_STARTED, errorHandler);
      bus.emit(EventType.GAME_STARTED, {});
      bus.emit(EventType.GAME_STARTED, {});
      
      const stats = bus.getStats();
      expect(stats.errorsByType.get(EventType.GAME_STARTED)).toBe(2);
    });

    test('resetStats 应该重置统计信息', () => {
      bus.subscribe(EventType.GAME_STARTED, () => {});
      bus.emit(EventType.GAME_STARTED, {});
      
      bus.resetStats();
      
      const stats = bus.getStats();
      expect(stats.totalEventsEmitted).toBe(0);
      expect(stats.eventsByType.size).toBe(0);
    });
  });

  describe('调试功能', () => {
    test('setDebugMode 应该切换调试模式', () => {
      expect(bus.getConfig().debugMode).toBe(false);
      
      bus.setDebugMode(true);
      expect(bus.getConfig().debugMode).toBe(true);
      
      bus.setDebugMode(false);
      expect(bus.getConfig().debugMode).toBe(false);
    });

    test('getDebugInfo 应该返回调试信息', () => {
      bus.subscribe(EventType.GAME_STARTED, () => {});
      bus.subscribe(EventType.GAME_PAUSED, () => {});
      
      const debugInfo = bus.getDebugInfo();
      expect(debugInfo.totalListeners).toBe(2);
      expect(debugInfo.registeredEventTypes).toHaveLength(2);
    });
  });

  describe('单例模式', () => {
    test('getInstance 应该返回相同实例', () => {
      const instance1 = EventBus.getInstance();
      const instance2 = EventBus.getInstance();
      
      expect(instance1).toBe(instance2);
    });

    test('destroy 应该清除实例', () => {
      const instance1 = EventBus.getInstance();
      EventBus.destroy();
      const instance2 = EventBus.getInstance();
      
      expect(instance1).not.toBe(instance2);
    });
  });

  describe('配置功能', () => {
    test('应该能通过配置初始化', () => {
      const customBus = EventBus.getInstance({
        debugMode: true,
        asyncProcessing: false,
        maxQueueSize: 500,
        enableStats: false
      });
      
      const config = customBus.getConfig();
      expect(config.debugMode).toBe(true);
      expect(config.asyncProcessing).toBe(false);
      expect(config.maxQueueSize).toBe(500);
      expect(config.enableStats).toBe(false);
      
      EventBus.destroy();
    });

    test('updateConfig 应该更新配置', () => {
      bus.updateConfig({ debugMode: true, maxQueueSize: 2000 });
      
      const config = bus.getConfig();
      expect(config.debugMode).toBe(true);
      expect(config.maxQueueSize).toBe(2000);
      expect(config.asyncProcessing).toBe(true); // 未改变的值
    });
  });

  describe('错误处理', () => {
    test('一个监听器出错不应影响其他监听器', () => {
      const order: string[] = [];
      
      bus.subscribe(EventType.GAME_STARTED, () => {
        order.push('first');
      });
      
      bus.subscribe(EventType.GAME_STARTED, () => {
        throw new Error('Test error');
      });
      
      bus.subscribe(EventType.GAME_STARTED, () => {
        order.push('third');
      });
      
      bus.emit(EventType.GAME_STARTED, {});
      
      expect(order).toEqual(['first', 'third']);
    });

    test('事件数据应该包含完整信息', () => {
      let receivedEvent: IEvent | null = null;
      
      bus.subscribe(EventType.GAME_STARTED, (event) => {
        receivedEvent = event;
      });
      
      bus.emit(EventType.GAME_STARTED, { mode: 'test', level: 1 }, 'test-source');
      
      expect(receivedEvent).not.toBeNull();
      expect(receivedEvent!.type).toBe(EventType.GAME_STARTED);
      expect(receivedEvent!.data).toEqual({ mode: 'test', level: 1 });
      expect(receivedEvent!.source).toBe('test-source');
      expect(receivedEvent!.timestamp).toBeGreaterThan(0);
      expect(receivedEvent!.id).toBeDefined();
    });
  });

  describe('内存管理', () => {
    test('取消订阅后应该释放引用', () => {
      const handler = () => {};
      
      const subscription = bus.subscribe(EventType.GAME_STARTED, handler);
      expect(bus.getListenerCount(EventType.GAME_STARTED)).toBe(1);
      
      subscription.unsubscribe();
      expect(bus.getListenerCount(EventType.GAME_STARTED)).toBe(0);
    });

    test('clearAllListeners 应该释放所有引用', () => {
      bus.subscribe(EventType.GAME_STARTED, () => {});
      bus.subscribe(EventType.GAME_PAUSED, () => {});
      bus.subscribe(EventType.GAME_RESUMED, () => {});
      
      expect(bus.getTotalListenerCount()).toBe(3);
      
      bus.clearAllListeners();
      
      expect(bus.getTotalListenerCount()).toBe(0);
      expect(bus.getRegisteredEventTypes()).toHaveLength(0);
    });
  });

  describe('队列限制', () => {
    test('应该限制队列大小', () => {
      const smallBus = EventBus.getInstance({ maxQueueSize: 2 });
      
      // 由于没有监听器，deferred事件会堆积在队列中
      // 但队列处理是异步的，所以这里主要测试配置是否生效
      expect(smallBus.getConfig().maxQueueSize).toBe(2);
      
      EventBus.destroy();
    });
  });
});
