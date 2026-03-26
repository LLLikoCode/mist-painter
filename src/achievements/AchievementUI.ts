/**
 * 迷雾绘者 - 成就UI组件
 * Achievement UI Components
 * 
 * @module AchievementUI
 * @description 提供成就系统的UI显示组件，包括成就列表、解锁通知、进度条等
 */

import {
  AchievementDisplayData,
  AchievementFilterOptions,
  AchievementSortOption,
  AchievementRarity,
  AchievementUnlockEvent,
  AchievementStats,
} from './AchievementTypes';

// ==================== 成就通知组件 ====================

/**
 * 成就解锁通知配置
 */
export interface AchievementNotificationConfig {
  /** 通知显示时长（毫秒） */
  duration: number;
  /** 通知位置 */
  position: 'top-left' | 'top-right' | 'bottom-left' | 'bottom-right' | 'top-center';
  /** 是否显示动画 */
  showAnimation: boolean;
  /** 是否播放音效 */
  playSound: boolean;
  /** 音效路径 */
  soundPath?: string;
  /** 通知宽度 */
  width: number;
  /** 最大同时显示数量 */
  maxStack: number;
}

/**
 * 默认通知配置
 */
export const DEFAULT_NOTIFICATION_CONFIG: AchievementNotificationConfig = {
  duration: 5000,
  position: 'top-right',
  showAnimation: true,
  playSound: true,
  width: 350,
  maxStack: 3,
};

/**
 * 成就解锁通知组件
 * 负责显示成就解锁时的弹窗通知
 */
export class AchievementNotification {
  private _config: AchievementNotificationConfig;
  private _container: HTMLElement | null = null;
  private _activeNotifications: Set<HTMLElement> = new Set();

  constructor(config: Partial<AchievementNotificationConfig> = {}) {
    this._config = { ...DEFAULT_NOTIFICATION_CONFIG, ...config };
    this._createContainer();
  }

  /**
   * 创建通知容器
   */
  private _createContainer(): void {
    if (typeof document === 'undefined') return;

    this._container = document.createElement('div');
    this._container.className = `achievement-notifications achievement-notifications--${this._config.position}`;
    this._container.style.cssText = this._getContainerStyles();
    document.body.appendChild(this._container);
  }

  /**
   * 获取容器样式
   */
  private _getContainerStyles(): string {
    const baseStyles = `
      position: fixed;
      z-index: 9999;
      display: flex;
      flex-direction: column;
      gap: 10px;
      pointer-events: none;
    `;

    switch (this._config.position) {
      case 'top-left':
        return `${baseStyles} top: 20px; left: 20px;`;
      case 'top-right':
        return `${baseStyles} top: 20px; right: 20px;`;
      case 'bottom-left':
        return `${baseStyles} bottom: 20px; left: 20px; flex-direction: column-reverse;`;
      case 'bottom-right':
        return `${baseStyles} bottom: 20px; right: 20px; flex-direction: column-reverse;`;
      case 'top-center':
        return `${baseStyles} top: 20px; left: 50%; transform: translateX(-50%);`;
      default:
        return `${baseStyles} top: 20px; right: 20px;`;
    }
  }

  /**
   * 显示成就解锁通知
   * @param data 成就显示数据
   */
  public show(data: AchievementDisplayData): void {
    if (!this._container) return;

    // 限制同时显示数量
    if (this._activeNotifications.size >= this._config.maxStack) {
      const oldest = this._activeNotifications.values().next().value;
      if (oldest) {
        this._removeNotification(oldest);
      }
    }

    const notification = this._createNotificationElement(data);
    this._container.appendChild(notification);
    this._activeNotifications.add(notification);

    // 播放音效
    if (this._config.playSound && this._config.soundPath) {
      this._playSound(this._config.soundPath);
    }

    // 触发动画
    if (this._config.showAnimation) {
      requestAnimationFrame(() => {
        notification.classList.add('achievement-notification--visible');
      });
    }

    // 自动移除
    setTimeout(() => {
      this._removeNotification(notification);
    }, this._config.duration);
  }

  /**
   * 创建通知元素
   */
  private _createNotificationElement(data: AchievementDisplayData): HTMLElement {
    const element = document.createElement('div');
    element.className = 'achievement-notification';
    element.style.cssText = this._getNotificationStyles(data.rarityColor);

    element.innerHTML = `
      <div class="achievement-notification__icon">
        <img src="${data.iconPath}" alt="${data.name}" />
      </div>
      <div class="achievement-notification__content">
        <div class="achievement-notification__title">成就解锁!</div>
        <div class="achievement-notification__name" style="color: ${data.rarityColor}">${data.name}</div>
        <div class="achievement-notification__description">${data.description}</div>
        <div class="achievement-notification__points">+${data.points} 点数</div>
      </div>
    `;

    return element;
  }

  /**
   * 获取通知样式
   */
  private _getNotificationStyles(rarityColor: string): string {
    return `
      display: flex;
      align-items: center;
      gap: 15px;
      width: ${this._config.width}px;
      padding: 15px;
      background: linear-gradient(135deg, rgba(30, 30, 40, 0.95), rgba(20, 20, 30, 0.98));
      border: 2px solid ${rarityColor};
      border-radius: 12px;
      box-shadow: 0 4px 20px rgba(0, 0, 0, 0.5), 0 0 20px ${rarityColor}40;
      opacity: 0;
      transform: translateX(100px);
      transition: all 0.4s cubic-bezier(0.175, 0.885, 0.32, 1.275);
      pointer-events: auto;
    `;
  }

  /**
   * 移除通知
   */
  private _removeNotification(element: HTMLElement): void {
    if (!this._activeNotifications.has(element)) return;

    element.classList.remove('achievement-notification--visible');
    element.style.opacity = '0';
    element.style.transform = 'translateX(100px)';

    setTimeout(() => {
      element.remove();
      this._activeNotifications.delete(element);
    }, 400);
  }

  /**
   * 播放音效
   */
  private _playSound(path: string): void {
    try {
      const audio = new Audio(path);
      audio.volume = 0.5;
      audio.play();
    } catch (error) {
      console.warn('[AchievementNotification] Failed to play sound:', error);
    }
  }

  /**
   * 销毁通知组件
   */
  public destroy(): void {
    // 移除所有活动通知
    for (const notification of this._activeNotifications) {
      notification.remove();
    }
    this._activeNotifications.clear();

    // 移除容器
    if (this._container) {
      this._container.remove();
      this._container = null;
    }
  }
}

// ==================== 成就列表组件 ====================

/**
 * 成就列表配置
 */
export interface AchievementListConfig {
  /** 容器元素 */
  container: HTMLElement;
  /** 每行显示数量 */
  itemsPerRow: number;
  /** 是否显示进度条 */
  showProgressBar: boolean;
  /** 是否显示过滤控件 */
  showFilters: boolean;
  /** 是否显示排序控件 */
  showSort: boolean;
  /** 成就卡片点击回调 */
  onAchievementClick?: (id: string) => void;
}

/**
 * 成就列表组件
 * 显示成就网格列表
 */
export class AchievementList {
  private _config: AchievementListConfig;
  private _achievements: AchievementDisplayData[] = [];
  private _filterOptions: AchievementFilterOptions = {};
  private _sortOption: AchievementSortOption = AchievementSortOption.ID;

  constructor(config: AchievementListConfig) {
    this._config = config;
    this._render();
  }

  /**
   * 渲染列表
   */
  private _render(): void {
    const { container } = this._config;
    container.innerHTML = '';
    container.className = 'achievement-list';

    // 渲染控制栏
    if (this._config.showFilters || this._config.showSort) {
      this._renderControls(container);
    }

    // 渲染成就网格
    this._renderGrid(container);

    // 添加样式
    this._addStyles();
  }

  /**
   * 渲染控制栏
   */
  private _renderControls(container: HTMLElement): void {
    const controls = document.createElement('div');
    controls.className = 'achievement-list__controls';

    if (this._config.showFilters) {
      controls.appendChild(this._createFilterControls());
    }

    if (this._config.showSort) {
      controls.appendChild(this._createSortControls());
    }

    container.appendChild(controls);
  }

  /**
   * 创建过滤控件
   */
  private _create