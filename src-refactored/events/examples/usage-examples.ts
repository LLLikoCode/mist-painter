/**
 * EventBus 使用示例
 * 展示如何在游戏中使用事件总线进行系统解耦
 */

import { EventBus, eventBus } from '../EventBus';
import { EventType, EventPriority, IEvent } from '../../interfaces/IEventBus';

// ============================================
// 示例 1: 基本订阅和发布
// ============================================

function basicUsageExample() {
  // 订阅游戏开始事件
  const subscription = eventBus.subscribe(
    EventType.GAME_STARTED,
    (event) => {
      console.log('游戏开始了！', event.data);
    }
  );

  // 发布游戏开始事件
  eventBus.emit(EventType.GAME_STARTED, {
    mode: 'adventure',
    level: 1
  });

  // 取消订阅
  subscription.unsubscribe();
}

// ============================================
// 示例 2: 使用优先级
// ============================================

function priorityExample() {
  // UI系统（高优先级，需要最先响应）
  eventBus.subscribe(
    EventType.PLAYER_DAMAGED,
    (event) => {
      console.log('UI: 显示受伤效果');
    },
    EventPriority.HIGH
  );

  // 音效系统（普通优先级）
  eventBus.subscribe(
    EventType.PLAYER_DAMAGED,
    (event) => {
      console.log('Audio: 播放受伤音效');
    },
    EventPriority.NORMAL
  );

  // 统计系统（低优先级，后台处理）
  eventBus.subscribe(
    EventType.PLAYER_DAMAGED,
    (event) => {
      console.log('Analytics: 记录受伤数据');
    },
    EventPriority.LOW
  );

  // 触发事件，输出顺序：
  // 1. UI: 显示受伤效果
  // 2. Audio: 播放受伤音效
  // 3. Analytics: 记录受伤数据
  eventBus.emit(EventType.PLAYER_DAMAGED, { damage: 10 });
}

// ============================================
// 示例 3: 一次性订阅
// ============================================

function oneTimeSubscriptionExample() {
  // 只监听一次关卡完成事件
  eventBus.subscribeOnce(
    EventType.LEVEL_COMPLETED,
    (event) => {
      console.log('首次通关奖励已发放！');
    }
  );

  // 第一次触发 - 会收到
  eventBus.emit(EventType.LEVEL_COMPLETED, { level: 1 });

  // 第二次触发 - 不会收到（监听器已自动移除）
  eventBus.emit(EventType.LEVEL_COMPLETED, { level: 2 });
}

// ============================================
// 示例 4: 延迟和异步事件
// ============================================

function deferredAndAsyncExample() {
  // 延迟执行 - 在当前调用栈结束后执行
  eventBus.emitDeferred(EventType.SAVE_COMPLETED, {
    slot: 1,
    timestamp: Date.now()
  });
  console.log('这行会在事件处理之前打印');

  // 异步执行 - 返回 Promise
  async function asyncExample() {
    await eventBus.emitAsync(EventType.SETTINGS_CHANGED, {
      setting: 'volume',
      value: 0.8
    });
    console.log('设置已更改并处理完成');
  }

  asyncExample();
}

// ============================================
// 示例 5: 系统解耦 - 玩家系统
// ============================================

class PlayerSystem {
  private position = { x: 0, y: 0 };
  private health = 100;

  constructor() {
    // 监听输入事件
    eventBus.subscribe(EventType.PLAYER_MOVED, this.onPlayerMoved.bind(this));
    eventBus.subscribe(EventType.PLAYER_DAMAGED, this.onPlayerDamaged.bind(this));
  }

  private onPlayerMoved(event: IEvent): void {
    const { position, velocity } = event.data as { position: { x: number; y: number }; velocity: { x: number; y: number } };
    this.position = position;
    console.log(`玩家移动到 (${position.x}, ${position.y})`);
  }

  private onPlayerDamaged(event: IEvent): void {
    const { damage } = event.data as { damage: number };
    this.health -= damage;
    console.log(`玩家受到伤害: ${damage}, 剩余生命: ${this.health}`);

    if (this.health <= 0) {
      eventBus.emit(EventType.GAME_OVER, { reason: 'player_died' });
    }
  }

  move(x: number, y: number): void {
    const velocity = { x: x - this.position.x, y: y - this.position.y };
    this.position = { x, y };

    // 发布移动事件，其他系统可以监听并响应
    eventBus.emit(EventType.PLAYER_MOVED, {
      position: this.position,
      velocity
    }, 'PlayerSystem');
  }

  takeDamage(damage: number): void {
    eventBus.emit(EventType.PLAYER_DAMAGED, { damage }, 'PlayerSystem');
  }
}

// ============================================
// 示例 6: 系统解耦 - UI系统
// ============================================

class UISystem {
  constructor() {
    // 高优先级监听游戏状态变化
    eventBus.subscribe(EventType.GAME_STARTED, this.onGameStarted.bind(this), EventPriority.HIGH);
    eventBus.subscribe(EventType.GAME_OVER, this.onGameOver.bind(this), EventPriority.HIGH);
    eventBus.subscribe(EventType.LEVEL_COMPLETED, this.onLevelCompleted.bind(this), EventPriority.HIGH);
    eventBus.subscribe(EventType.ACHIEVEMENT_UNLOCKED, this.onAchievementUnlocked.bind(this), EventPriority.NORMAL);
  }

  private onGameStarted(event: IEvent): void {
    console.log('UI: 显示游戏界面');
    console.log('UI: 隐藏主菜单');
  }

  private onGameOver(event: IEvent): void {
    console.log('UI: 显示游戏结束画面');
  }

  private onLevelCompleted(event: IEvent): void {
    const { level, score } = event.data as { level: number; score?: number };
    console.log(`UI: 显示关卡 ${level} 完成画面，得分: ${score}`);
  }

  private onAchievementUnlocked(event: IEvent): void {
    const { achievementName } = event.data as { achievementName: string };
    console.log(`UI: 显示成就解锁提示 - ${achievementName}`);
  }
}

// ============================================
// 示例 7: 系统解耦 - 成就系统
// ============================================

class AchievementSystem {
  private unlockedAchievements: Set<string> = new Set();

  constructor() {
    // 监听各种游戏事件来触发成就检查
    eventBus.subscribe(EventType.PUZZLE_SOLVED, this.onPuzzleSolved.bind(this));
    eventBus.subscribe(EventType.LEVEL_COMPLETED, this.onLevelCompleted.bind(this));
    eventBus.subscribe(EventType.MIST_CLEARED, this.onMistCleared.bind(this));
  }

  private onPuzzleSolved(event: IEvent): void {
    const { level } = event.data as { level: number };

    // 检查成就：首次解谜
    this.unlockAchievement('first_puzzle', '初次解谜');

    // 检查成就：解谜大师（完成10个谜题）
    // 这里简化处理，实际需要计数
    if (level >= 10) {
      this.unlockAchievement('puzzle_master', '解谜大师');
    }
  }

  private onLevelCompleted(event: IEvent): void {
    const { level } = event.data as { level: number };

    // 检查成就：通关
    this.unlockAchievement(`level_${level}_complete`, `完成第${level}关`);
  }

  private onMistCleared(event: IEvent): void {
    const { coveragePercent } = event.data as { coveragePercent: number };

    // 检查成就：迷雾清除者（清除90%以上迷雾）
    if (coveragePercent >= 90) {
      this.unlockAchievement('mist_clearer', '迷雾清除者');
    }
  }

  private unlockAchievement(id: string, name: string): void {
    if (this.unlockedAchievements.has(id)) return;

    this.unlockedAchievements.add(id);
    eventBus.emit(EventType.ACHIEVEMENT_UNLOCKED, {
      achievementId: id,
      achievementName: name,
      unlockedAt: Date.now()
    }, 'AchievementSystem');
  }
}

// ============================================
// 示例 8: 调试和统计
// ============================================

function debugAndStatsExample() {
  // 启用调试模式
  eventBus.setDebugMode(true);

  // 添加一些监听器
  eventBus.subscribe(EventType.GAME_STARTED, () => {});
  eventBus.subscribe(EventType.GAME_PAUSED, () => {});
  eventBus.subscribe(EventType.GAME_RESUMED, () => {});

  // 发布一些事件
  eventBus.emit(EventType.GAME_STARTED, { mode: 'test' });
  eventBus.emit(EventType.GAME_PAUSED, {});
  eventBus.emit(EventType.GAME_RESUMED, {});

  // 获取调试信息
  const debugInfo = eventBus.getDebugInfo();
  console.log('调试信息:', debugInfo);

  // 获取统计信息
  const stats = eventBus.getStats();
  console.log('事件统计:', {
    总发布数: stats.totalEventsEmitted,
    总处理数: stats.totalEventsProcessed,
    平均处理时间: `${stats.averageProcessingTime.toFixed(2)}ms`,
    各类型计数: Object.fromEntries(stats.eventsByType)
  });

  // 获取最近处理时间
  const recentTimes = eventBus.getRecentProcessingTimes();
  console.log('最近处理时间:', recentTimes);

  // 关闭调试模式
  eventBus.setDebugMode(false);
}

// ============================================
// 示例 9: 配置管理
// ============================================

function configurationExample() {
  // 创建自定义配置的 EventBus  const customBus = EventBus.getInstance({
    debugMode: true,
    asyncProcessing: false,  // 同步处理
    maxQueueSize: 500,
    enableStats: true
  });

  // 查看配置
  console.log('当前配置:', customBus.getConfig());

  // 更新配置
  customBus.updateConfig({ maxQueueSize: 1000 });
  console.log('更新后配置:', customBus.getConfig());

  // 清理
  EventBus.destroy();
}

// ============================================
// 示例 10: 完整的游戏初始化流程
// ============================================

function gameInitializationExample() {
  console.log('=== 游戏初始化开始 ===');

  // 初始化各个系统
  const uiSystem = new UISystem();
  const playerSystem = new PlayerSystem();
  const achievementSystem = new AchievementSystem();

  // 启动游戏
  console.log('\n--- 启动游戏 ---');
  eventBus.emit(EventType.GAME_STARTED, {
    mode: 'adventure',
    level: 1
  }, 'GameManager');

  // 模拟玩家移动
  console.log('\n--- 玩家移动 ---');
  eventBus.emit(EventType.PLAYER_MOVED, {
    position: { x: 100, y: 200 },
    velocity: { x: 10, y: 0 }
  }, 'InputManager');

  // 模拟解谜成功
  console.log('\n--- 解谜成功 ---');
  eventBus.emit(EventType.PUZZLE_SOLVED, {
    puzzleId: 'puzzle_001',
    level: 1,
    time: 45
  }, 'PuzzleManager');

  // 模拟关卡完成
  console.log('\n--- 关卡完成 ---');
  eventBus.emit(EventType.LEVEL_COMPLETED, {
    level: 1,
    score: 1500,
    time: 120
  }, 'LevelManager');

  // 显示统计
  console.log('\n--- 事件统计 ---');
  const stats = eventBus.getStats();
  console.log(`总事件数: ${stats.totalEventsEmitted}`);
  console.log(`平均处理时间: ${stats.averageProcessingTime.toFixed(2)}ms`);

  console.log('\n=== 游戏初始化完成 ===');
}

// 导出示例函数
export {
  basicUsageExample,
  priorityExample,
  oneTimeSubscriptionExample,
  deferredAndAsyncExample,
  PlayerSystem,
  UISystem,
  AchievementSystem,
  debugAndStatsExample,
  configurationExample,
  gameInitializationExample
};

// 如果直接运行此文件，执行完整示例
if (require.main === module) {
  gameInitializationExample();
}
