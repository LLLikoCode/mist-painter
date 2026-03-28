/**
 * Logger
 * 日志工具类 - 提供统一的日志记录功能
 */

/**
 * 日志级别枚举
 */
export enum LogLevel {
  DEBUG = 0,
  INFO = 1,
  WARN = 2,
  ERROR = 3,
  NONE = 4
}

/**
 * 日志配置
 */
interface LoggerConfig {
  level: LogLevel;
  prefix: string;
  enableConsole: boolean;
  enableTimestamp: boolean;
}

/**
 * 日志记录
 */
interface LogEntry {
  level: LogLevel;
  message: string;
  timestamp: number;
  data?: unknown;
}

/**
 * 日志工具类
 */
export class Logger {
  private static _globalLevel: LogLevel = LogLevel.DEBUG;
  private static _logHistory: LogEntry[] = [];
  private static _maxHistorySize: number = 1000;
  
  private _config: LoggerConfig;
  
  constructor(prefix: string = '', level?: LogLevel) {
    this._config = {
      level: level ?? Logger._globalLevel,
      prefix,
      enableConsole: true,
      enableTimestamp: true
    };
  }
  
  /**
   * 设置全局日志级别
   */
  static setGlobalLevel(level: LogLevel): void {
    Logger._globalLevel = level;
  }
  
  /**
   * 获取全局日志级别
   */
  static getGlobalLevel(): LogLevel {
    return Logger._globalLevel;
  }
  
  /**
   * 获取日志历史
   */
  static getLogHistory(): LogEntry[] {
    return [...Logger._logHistory];
  }
  
  /**
   * 清空日志历史
   */
  static clearHistory(): void {
    Logger._logHistory = [];
  }
  
  /**
   * 导出日志为字符串
   */
  static exportLogs(): string {
    return Logger._logHistory
      .map(entry => `[${new Date(entry.timestamp).toISOString()}] ${LogLevel[entry.level]}: ${entry.message}`)
      .join('\n');
  }
  
  /**
   * 设置日志级别
   */
  setLevel(level: LogLevel): void {
    this._config.level = level;
  }
  
  /**
   * 设置前缀
   */
  setPrefix(prefix: string): void {
    this._config.prefix = prefix;
  }
  
  /**
   * 记录调试日志
   */
  debug(message: string, ...data: unknown[]): void {
    this._log(LogLevel.DEBUG, message, data);
  }
  
  /**
   * 记录信息日志
   */
  info(message: string, ...data: unknown[]): void {
    this._log(LogLevel.INFO, message, data);
  }
  
  /**
   * 记录警告日志
   */
  warn(message: string, ...data: unknown[]): void {
    this._log(LogLevel.WARN, message, data);
  }
  
   /**
   * 记录错误日志
   */
  error(message: string, ...data: unknown[]): void {
    this._log(LogLevel.ERROR, message, data);
  }
  
  /**
   * 记录日志
   */
  private _log(level: LogLevel, message: string, data: unknown[]): void {
    if (level < this._config.level || level < Logger._globalLevel) {
      return;
    }
    
    const timestamp = Date.now();
    const prefix = this._config.prefix ? `[${this._config.prefix}] ` : '';
    const levelStr = LogLevel[level];
    const timeStr = this._config.enableTimestamp 
      ? `[${new Date(timestamp).toLocaleTimeString()}] ` 
      : '';
    
    const fullMessage = `${timeStr}${prefix}${message}`;
    
    // 添加到历史
    const entry: LogEntry = {
      level,
      message: fullMessage,
      timestamp,
      data: data.length > 0 ? data : undefined
    };
    
    Logger._logHistory.push(entry);
    
    // 限制历史大小
    if (Logger._logHistory.length > Logger._maxHistorySize) {
      Logger._logHistory.shift();
    }
    
    // 输出到控制台
    if (this._config.enableConsole) {
      const consoleData = data.length > 0 ? data : undefined;
      
      switch (level) {
        case LogLevel.DEBUG:
          console.debug(fullMessage, ...(consoleData || []));
          break;
        case LogLevel.INFO:
          console.info(fullMessage, ...(consoleData || []));
          break;
        case LogLevel.WARN:
          console.warn(fullMessage, ...(consoleData || []));
          break;
        case LogLevel.ERROR:
          console.error(fullMessage, ...(consoleData || []));
          break;
      }
    }
  }
}

// 默认日志实例
export const logger = new Logger('App');
