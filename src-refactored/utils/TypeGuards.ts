/**
 * TypeGuards
 * 类型守卫工具函数 - 提供运行时类型检查
 */

/**
 * 检查值是否为对象
 */
export function isObject(value: unknown): value is Record<string, unknown> {
  return value !== null && typeof value === 'object' && !Array.isArray(value);
}

/**
 * 检查值是否为数组
 */
export function isArray<T>(value: unknown): value is T[] {
  return Array.isArray(value);
}

/**
 * 检查值是否为字符串
 */
export function isString(value: unknown): value is string {
  return typeof value === 'string';
}

/**
 * 检查值是否为数字
 */
export function isNumber(value: unknown): value is number {
  return typeof value === 'number' && !isNaN(value);
}

/**
 * 检查值是否为整数
 */
export function isInteger(value: unknown): value is number {
  return isNumber(value) && Number.isInteger(value);
}

/**
 * 检查值是否为布尔值
 */
export function isBoolean(value: unknown): value is boolean {
  return typeof value === 'boolean';
}

/**
 * 检查值是否为函数
 */
export function isFunction(value: unknown): value is (...args: unknown[]) => unknown {
  return typeof value === 'function';
}

/**
 * 检查值是否为 null
 */
export function isNull(value: unknown): value is null {
  return value === null;
}

/**
 * 检查值是否为 undefined
 */
export function isUndefined(value: unknown): value is undefined {
  return value === undefined;
}

/**
 * 检查值是否为 null 或 undefined
 */
export function isNullOrUndefined(value: unknown): value is null | undefined {
  return value === null || value === undefined;
}

/**
 * 检查值是否已定义（非 null 且非 undefined）
 */
export function isDefined<T>(value: T | null | undefined): value is T {
  return value !== null && value !== undefined;
}

/**
 * 检查值是否为日期
 */
export function isDate(value: unknown): value is Date {
  return value instanceof Date && !isNaN(value.getTime());
}

/**
 * 检查值是否为 Error
 */
export function isError(value: unknown): value is Error {
  return value instanceof Error;
}

/**
 * 检查值是否为 Promise
 */
export function isPromise<T>(value: unknown): value is Promise<T> {
  return value instanceof Promise || 
    (isObject(value) && isFunction((value as Record<string, unknown>).then));
}

/**
 * 检查值是否为 Map
 */
export function isMap<K, V>(value: unknown): value is Map<K, V> {
  return value instanceof Map;
}

/**
 * 检查值是否为 Set
 */
export function isSet<T>(value: unknown): value is Set<T> {
  return value instanceof Set;
}

/**
 * 检查值是否为 RegExp
 */
export function isRegExp(value: unknown): value is RegExp {
  return value instanceof RegExp;
}

/**
 * 检查值是否为 URL
 */
export function isURL(value: unknown): value is URL {
  return value instanceof URL;
}

/**
 * 检查字符串是否为有效的 JSON
 */
export function isValidJSON(value: string): boolean {
  try {
    JSON.parse(value);
    return true;
  } catch {
    return false;
  }
}

/**
 * 检查字符串是否为有效的 URL
 */
export function isValidURL(value: string): boolean {
  try {
    new URL(value);
    return true;
  } catch {
    return false;
  }
}

/**
 * 检查字符串是否为有效的电子邮件地址
 */
export function isValidEmail(value: string): boolean {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(value);
}

/**
 * 检查值是否在指定范围内
 */
export function isInRange(value: number, min: number, max: number): boolean {
  return value >= min && value <= max;
}

/**
 * 检查数组是否为空
 */
export function isEmptyArray<T>(value: T[]): boolean {
  return value.length === 0;
}

/**
 * 检查对象是否为空
 */
export function isEmptyObject(value: Record<string, unknown>): boolean {
  return Object.keys(value).length === 0;
}

/**
 * 检查值是否为枚举成员
 */
export function isEnumValue<T extends Record<string, string | number>>(
  enumObj: T,
  value: unknown
): value is T[keyof T] {
  return Object.values(enumObj).includes(value as string | number);
}

/**
 * 断言值已定义
 * 如果值为 null 或 undefined，抛出错误
 */
export function assertDefined<T>(
  value: T | null | undefined,
  message: string = 'Value is null or undefined'
): asserts value is T {
  if (!isDefined(value)) {
    throw new Error(message);
  }
}

/**
 * 断言值为特定类型
 */
export function assertIs<T>(
  value: unknown,
  guard: (v: unknown) => v is T,
  message?: string
): asserts value is T {
  if (!guard(value)) {
    throw new Error(message || `Value failed type guard`);
  }
}
