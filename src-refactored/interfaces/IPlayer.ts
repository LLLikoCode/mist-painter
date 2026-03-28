/**
 * 玩家控制器接口
 * 负责处理玩家的移动、动画、交互和迷雾绘制输入
 */

/**
 * 玩家状态枚举
 */
export enum PlayerState {
  IDLE = 'IDLE',
  WALKING = 'WALKING',
  SPRINTING = 'SPRINTING',
  INTERACTING = 'INTERACTING',
  PAINTING = 'PAINTING'
}

/**
 * 朝向枚举
 */
export enum FacingDirection {
  UP = 'UP',
  DOWN = 'DOWN',
  LEFT = 'LEFT',
  RIGHT = 'RIGHT'
}

/**
 * 移动设置接口
 */
export interface MovementSettings {
  /** 移动速度 */
  moveSpeed: number;
  /** 冲刺速度 */
  sprintSpeed: number;
  /** 加速度 */
  acceleration: number;
  /** 减速度/摩擦力 */
  friction: number;
}

/**
 * 交互设置接口
 */
export interface InteractionSettings {
  /** 交互半径 */
  interactionRadius: number;
  /** 交互冷却时间（秒） */
  interactionCooldown: number;
}

/**
 * 绘制设置接口
 */
export interface PaintSettings {
  /** 是否可以绘制迷雾 */
  canPaintMist: boolean;
  /** 绘制冷却时间（秒） */
  paintCooldown: number;
}

/**
 * 玩家位置信息
 */
export interface PlayerPosition {
  x: number;
  y: number;
  velocityX: number;
  velocityY: number;
}

/**
 * 玩家控制器接口
 */
export interface IPlayerController {
  /** 当前位置 */
  readonly position: { x: number; y: number };
  /** 当前速度 */
  readonly velocity: { x: number; y: number };
  /** 当前状态 */
  readonly currentState: PlayerState;
  /** 当前朝向 */
  readonly facingDirection: FacingDirection;
  /** 是否正在冲刺 */
  readonly isSprinting: boolean;
  /** 是否正在绘制迷雾 */
  readonly isPainting: boolean;
  /** 移动设置 */
  movementSettings: MovementSettings;
  /** 交互设置 */
  interactionSettings: InteractionSettings;
  /** 绘制设置 */
  paintSettings: PaintSettings;
  
  /**
   * 初始化玩家控制器
   * @param spawnPosition 初始位置
   */
  initialize(spawnPosition?: { x: number; y: number }): void;
  
  /**
   * 设置玩家位置
   * @param position 位置
   */
  setPosition(position: { x: number; y: number }): void;
  
  /**
   * 获取当前朝向
   */
  getFacingDirection(): FacingDirection;
  
  /**
   * 获取朝向向量
   */
  getFacingVector(): { x: number; y: number };
  
  /**
   * 禁用移动
   */
  disableMovement(): void;
  
  /**
   * 启用移动
   */
  enableMovement(): void;
  
  /**
   * 禁用迷雾绘制
   */
  disablePainting(): void;
  
  /**
   * 启用迷雾绘制
   */
  enablePainting(): void;
  
  /**
   * 是否正在移动
   */
  isMoving(): boolean;
  
  /**
   * 是否正在绘制迷雾
   */
  isPaintingMist(): boolean;
  
  /**
   * 获取当前速度
   */
  getCurrentSpeed(): number;
  
  /**
   * 尝试交互
   */
  tryInteract(): void;
  
  /**
   * 序列化状态（用于存档）
   */
  serialize(): Record<string, unknown>;
  
  /**
   * 反序列化状态（从存档加载）
   * @param data 存档数据
   */
  deserialize(data: Record<string, unknown>): void;
}

/**
 * 玩家移动事件
 */
export interface PlayerMovedEvent {
  position: { x: number; y: number };
  velocity: { x: number; y: number };
}

/**
 * 玩家朝向变更事件
 */
export interface PlayerDirectionChangedEvent {
  newDirection: FacingDirection;
  previousDirection: FacingDirection;
}

/**
 * 玩家交互事件
 */
export interface PlayerInteractionEvent {
  target: string;
  targetType: string;
}

/**
 * 玩家绘制事件
 */
export interface PlayerPaintEvent {
  position: { x: number; y: number };
  action: 'STARTED' | 'MOVED' | 'ENDED';
}
