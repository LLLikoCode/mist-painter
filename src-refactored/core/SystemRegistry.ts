/**
 * SystemRegistry
 * 系统注册表 - 管理所有系统的注册、初始化和依赖关系
 * 实现依赖注入模式
 */

import {
  ISystem,
  SystemStatus,
  SystemPriority,
  SystemConfig
} from '../interfaces/ISystem';

/**
 * 系统注册项
 */
interface SystemRegistryEntry {
  /** 系统实例 */
  system: ISystem;
  /** 系统配置 */
  config: SystemConfig;
  /** 依赖的系统名称列表 */
  dependencies: string[];
}

/**
 * 系统初始化结果
 */
interface SystemInitResult {
  /** 系统名称 */
  systemName: string;
  /** 是否成功 */
  success: boolean;
  /** 错误信息 */
  error?: string;
  /** 初始化耗时（毫秒） */
  duration: number;
}

/**
 * 系统注册表
 * 单例模式
 */
export class SystemRegistry {
  private static _instance: SystemRegistry | null = null;
  
  /**
   * 获取单例实例
   */
  public static getInstance(): SystemRegistry {
    if (!SystemRegistry._instance) {
      SystemRegistry._instance = new SystemRegistry();
    }
    return SystemRegistry._instance;
  }
  
  /**
   * 销毁单例
   */
  public static destroy(): void {
    if (SystemRegistry._instance) {
      SystemRegistry._instance.disposeAllSystems();
      SystemRegistry._instance = null;
    }
  }
  
  // 系统注册表
  private _systems: Map<string, SystemRegistryEntry> = new Map();
  
  // 初始化状态
  private _isInitialized: boolean = false;
  
  // 初始化结果
  private _initResults: SystemInitResult[] = [];
  
  private constructor() {
    // 私有构造函数，确保单例
  }
  
  /**
   * 注册系统
   * @param system 系统实例
   * @param config 系统配置
   * @param dependencies 依赖的系统名称列表
   */
  registerSystem(
    system: ISystem,
    config?: Partial<SystemConfig>,
    dependencies: string[] = []
  ): void {
    if (this._systems.has(system.systemName)) {
      console.warn(`SystemRegistry: System ${system.systemName} is already registered`);
      return;
    }
    
    const fullConfig: SystemConfig = {
      priority: SystemPriority.MEDIUM,
      enabled: true,
      settings: {},
      ...config
    };
    
    this._systems.set(system.systemName, {
      system,
      config: fullConfig,
      dependencies
    });
    
    console.log(`SystemRegistry: Registered system ${system.systemName} with priority ${fullConfig.priority}`);
  }
  
  /**
   * 注销系统
   * @param systemName 系统名称
   */
  unregisterSystem(systemName: string): void {
    const entry = this._systems.get(systemName);
    if (entry) {
      entry.system.dispose();
      this._systems.delete(systemName);
      console.log(`SystemRegistry: Unregistered system ${systemName}`);
    }
  }
  
  /**
   * 获取系统
   * @param systemName 系统名称
   */
  getSystem<T extends ISystem>(systemName: string): T | null {
    const entry = this._systems.get(systemName);
    return entry ? (entry.system as T) : null;
  }
  
  /**
   * 检查系统是否已注册
   * @param systemName 系统名称
   */
  hasSystem(systemName: string): boolean {
    return this._systems.has(systemName);
  }
  
  /**
   * 获取所有已注册的系统
   */
  getAllSystems(): ISystem[] {
    return Array.from(this._systems.values()).map(entry => entry.system);
  }
  
  /**
   * 获取已启用的系统
   */
  getEnabledSystems(): ISystem[] {
    return Array.from(this._systems.values())
      .filter(entry => entry.config.enabled)
      .map(entry => entry.system);
  }
  
  /**
   * 初始化所有系统
   * 按照优先级和依赖关系顺序初始化
   */
  async initializeAllSystems(): Promise<SystemInitResult[]> {
    if (this._isInitialized) {
      console.warn('SystemRegistry: Systems are already initialized');
      return this._initResults;
    }
    
    console.log('SystemRegistry: Starting system initialization...');
    
    this._initResults = [];
    const initializedSystems = new Set<string>();
    
    // 按优先级排序系统
    const sortedEntries = this._sortSystemsByPriority();
    
    for (const entry of sortedEntries) {
      if (!entry.config.enabled) {
        console.log(`SystemRegistry: Skipping disabled system ${entry.system.systemName}`);
        continue;
      }
      
      // 检查依赖是否已初始化
      const missingDeps = entry.dependencies.filter(dep => !initializedSystems.has(dep));
      if (missingDeps.length > 0) {
        const error = `Missing dependencies: ${missingDeps.join(', ')}`;
        this._initResults.push({
          systemName: entry.system.systemName,
          success: false,
          error,
          duration: 0
        });
        console.error(`SystemRegistry: Failed to initialize ${entry.system.systemName}: ${error}`);
        continue;
      }
      
      // 初始化系统
      const startTime = Date.now();
      try {
        const success = await entry.system.initialize(entry.config.settings);
        const duration = Date.now() - startTime;
        
        this._initResults.push({
          systemName: entry.system.systemName,
          success,
          duration
        });
        
        if (success) {
          initializedSystems.add(entry.system.systemName);
          console.log(`SystemRegistry: Initialized ${entry.system.systemName} in ${duration}ms`);
        } else {
          console.error(`SystemRegistry: Failed to initialize ${entry.system.systemName}`);
        }
      } catch (error) {
        const duration = Date.now() - startTime;
        this._initResults.push({
          systemName: entry.system.systemName,
          success: false,
          error: String(error),
          duration
        });
        console.error(`SystemRegistry: Error initializing ${entry.system.systemName}:`, error);
      }
    }
    
    this._isInitialized = true;
    
    const successCount = this._initResults.filter(r => r.success).length;
    const failCount = this._initResults.length - successCount;
    console.log(`SystemRegistry: Initialization complete. ${successCount} succeeded, ${failCount} failed.`);
    
    return this._initResults;
  }
  
  /**
   * 更新所有系统
   * @param deltaTime 时间增量
   */
  updateAllSystems(deltaTime: number): void {
    for (const entry of this._systems.values()) {
      if (entry.config.enabled && entry.system.isInitialized) {
        try {
          entry.system.update(deltaTime);
        } catch (error) {
          console.error(`SystemRegistry: Error updating ${entry.system.systemName}:`, error);
        }
      }
    }
  }
  
  /**
   * 释放所有系统
   */
  disposeAllSystems(): void {
    console.log('SystemRegistry: Disposing all systems...');
    
    // 按优先级反向释放（先释放低优先级）
    const sortedEntries = this._sortSystemsByPriority().reverse();
    
    for (const entry of sortedEntries) {
      try {
        entry.system.dispose();
        console.log(`SystemRegistry: Disposed ${entry.system.systemName}`);
      } catch (error) {
        console.error(`SystemRegistry: Error disposing ${entry.system.systemName}:`, error);
      }
    }
    
    this._systems.clear();
    this._isInitialized = false;
    this._initResults = [];
    
    console.log('SystemRegistry: All systems disposed');
  }
  
  /**
   * 获取系统状态
   */
  getSystemStatus(systemName: string): SystemStatus | null {
    const entry = this._systems.get(systemName);
    return entry ? entry.system.getStatus() : null;
  }
  
  /**
   * 获取所有系统状态
   */
  getAllSystemStatus(): SystemStatus[] {
    return this.getAllSystems().map(system => system.getStatus());
  }
  
  /**
   * 获取初始化结果
   */
  getInitResults(): SystemInitResult[] {
    return [...this._initResults];
  }
  
  /**
   * 检查是否已初始化
   */
  isInitialized(): boolean {
    return this._isInitialized;
  }
  
  /**
   * 设置系统启用状态
   * @param systemName 系统名称
   * @param enabled 是否启用
   */
  setSystemEnabled(systemName: string, enabled: boolean): void {
    const entry = this._systems.get(systemName);
    if (entry) {
      entry.config.enabled = enabled;
      console.log(`SystemRegistry: ${systemName} ${enabled ? 'enabled' : 'disabled'}`);
    }
  }
  
  /**
   * 按优先级排序系统
   */
  private _sortSystemsByPriority(): SystemRegistryEntry[] {
    return Array.from(this._systems.values()).sort((a, b) => {
      return a.config.priority - b.config.priority;
    });
  }
  
  /**
   * 获取系统依赖图
   * 用于检测循环依赖
   */
  getDependencyGraph(): Record<string, string[]> {
    const graph: Record<string, string[]> = {};
    
    for (const [name, entry] of this._systems.entries()) {
      graph[name] = entry.dependencies;
    }
    
    return graph;
  }
  
  /**
   * 检测循环依赖
   * @returns 循环依赖路径，如果没有则返回 null
   */
  detectCircularDependency(): string[] | null {
    const graph = this.getDependencyGraph();
    const visited = new Set<string>();
    const recStack = new Set<string>();
    
    const dfs = (node: string, path: string[]): string[] | null => {
      visited.add(node);
      recStack.add(node);
      path.push(node);
      
      const neighbors = graph[node] || [];
      for (const neighbor of neighbors) {
        if (!visited.has(neighbor)) {
          const cycle = dfs(neighbor, [...path]);
          if (cycle) return cycle;
        } else if (recStack.has(neighbor)) {
          // 发现循环
          const cycleStart = path.indexOf(neighbor);
          return [...path.slice(cycleStart), neighbor];
        }
      }
      
      recStack.delete(node);
      return null;
    };
    
    for (const node of Object.keys(graph)) {
      if (!visited.has(node)) {
        const cycle = dfs(node, []);
        if (cycle) return cycle;
      }
    }
    
    return null;
  }
  
  /**
   * 获取调试信息
   */
  getDebugInfo(): Record<string, unknown> {
    const systemInfo: Record<string, unknown> = {};
    
    for (const [name, entry] of this._systems.entries()) {
      systemInfo[name] = {
        priority: entry.config.priority,
        enabled: entry.config.enabled,
        initialized: entry.system.isInitialized,
        dependencies: entry.dependencies,
        status: entry.system.getStatus()
      };
    }
    
    return {
      isInitialized: this._isInitialized,
      systemCount: this._systems.size,
      initializedCount: this._initResults.filter(r => r.success).length,
      failedCount: this._initResults.filter(r => !r.success).length,
      systems: systemInfo,
      circularDependency: this.detectCircularDependency()
    };
  }
}

// 导出单例获取函数
export const systemRegistry = SystemRegistry.getInstance();
