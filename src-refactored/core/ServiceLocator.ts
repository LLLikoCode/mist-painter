/**
 * ServiceLocator
 * 服务定位器模式 - 提供全局访问点获取系统服务
 * 与 SystemRegistry 配合使用，提供类型安全的系统访问
 */

import { ISystem } from '../interfaces/ISystem';
import { SystemRegistry } from './SystemRegistry';

/**
 * 服务定位器
 * 单例模式
 */
export class ServiceLocator {
  private static _instance: ServiceLocator | null = null;
  
  /**
   * 获取单例实例
   */
  public static getInstance(): ServiceLocator {
    if (!ServiceLocator._instance) {
      ServiceLocator._instance = new ServiceLocator();
    }
    return ServiceLocator._instance;
  }
  
  /**
   * 销毁单例
   */
  public static destroy(): void {
    ServiceLocator._instance = null;
  }
  
  private _registry: SystemRegistry;
  
  private constructor() {
    this._registry = SystemRegistry.getInstance();
  }
  
  /**
   * 获取服务
   * @param serviceName 服务名称
   */
  getService<T extends ISystem>(serviceName: string): T {
    const service = this._registry.getSystem<T>(serviceName);
    if (!service) {
      throw new Error(`Service not found: ${serviceName}`);
    }
    return service;
  }
  
  /**
   * 安全获取服务（可能返回 null）
   * @param serviceName 服务名称
   */
  tryGetService<T extends ISystem>(serviceName: string): T | null {
    return this._registry.getSystem<T>(serviceName);
  }
  
  /**
   * 检查服务是否可用
   * @param serviceName 服务名称
   */
  hasService(serviceName: string): boolean {
    return this._registry.hasSystem(serviceName);
  }
  
  /**
   * 等待服务可用
   * @param serviceName 服务名称
   * @param timeout 超时时间（毫秒）
   */
  async waitForService<T extends ISystem>(
    serviceName: string,
    timeout: number = 5000
  ): Promise<T> {
    const startTime = Date.now();
    
    while (Date.now() - startTime < timeout) {
      const service = this._registry.getSystem<T>(serviceName);
      if (service && service.isInitialized) {
        return service;
      }
      await new Promise(resolve => setTimeout(resolve, 100));
    }
    
    throw new Error(`Timeout waiting for service: ${serviceName}`);
  }
  
  /**
   * 获取所有可用服务
   */
  getAllServices(): ISystem[] {
    return this._registry.getAllSystems().filter(s => s.isInitialized);
  }
}

// 导出单例获取函数
export const serviceLocator = ServiceLocator.getInstance();
