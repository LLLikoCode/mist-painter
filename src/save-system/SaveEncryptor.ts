/**
 * 迷雾绘者 - 存档加密器
 * Save Data Encryption and Checksum
 */

import { SaveError, SaveErrorType } from './types';

export interface EncryptionConfig {
  enabled: boolean;
  key: string;
}

export class SaveEncryptor {
  private readonly config: EncryptionConfig;
  private readonly SAVE_SIGNATURE = 'MPSAVE';

  constructor(config: EncryptionConfig) {
    this.config = config;
  }

  /**
   * 加密存档数据
   * 格式: SIGNATURE + CHECKSUM(8) + ENCRYPTED_DATA
   */
  encrypt(data: string): string {
    if (!this.config.enabled) {
      const checksum = this.calculateChecksum(data);
      return `${this.SAVE_SIGNATURE}:${checksum}:${data}`;
    }

    // XOR 加密
    const encrypted = this.xorEncrypt(data, this.config.key);
    const checksum = this.calculateChecksum(encrypted);
    
    // 格式: 签名:校验和:加密数据
    return `${this.SAVE_SIGNATURE}:${checksum}:${encrypted}`;
  }

  /**
   * 解密存档数据
   */
  decrypt(encryptedData: string): string {
    const parts = encryptedData.split(':', 3);
    
    if (parts.length !== 3) {
      throw new SaveError(
        SaveErrorType.CORRUPTED,
        'Invalid save data format'
      );
    }

    const [signature, checksum, data] = parts;

    // 验证签名
    if (signature !== this.SAVE_SIGNATURE) {
      throw new SaveError(
        SaveErrorType.CORRUPTED,
        'Invalid save signature'
      );
    }

    // 验证校验和
    if (!this.verifyChecksum(data, checksum)) {
      throw new SaveError(
        SaveErrorType.CORRUPTED,
        'Save data checksum mismatch - data may be corrupted'
      );
    }

    if (!this.config.enabled) {
      return data;
    }

    // XOR 解密
    return this.xorEncrypt(data, this.config.key);
  }

  /**
   * XOR 加密/解密（对称）
   */
  private xorEncrypt(data: string, key: string): string {
    if (!key) return data;
    
    const keyBytes = this.stringToBytes(key);
    const dataBytes = this.stringToBytes(data);
    const result: number[] = [];

    for (let i = 0; i < dataBytes.length; i++) {
      result[i] = dataBytes[i] ^ keyBytes[i % keyBytes.length];
    }

    return this.bytesToBase64(result);
  }

  /**
   * 计算校验和（使用简单的 FNV-1a 哈希）
   */
  calculateChecksum(data: string): string {
    const bytes = this.stringToBytes(data);
    let hash = 0x811c9dc5; // FNV offset basis

    for (const byte of bytes) {
      hash ^= byte;
      hash = Math.imul(hash, 0x01000193); // FNV prime
    }

    // 转换为 8 位十六进制字符串
    return (hash >>> 0).toString(16).padStart(8, '0');
  }

  /**
   * 验证校验和
   */
  verifyChecksum(data: string, checksum: string): boolean {
    return this.calculateChecksum(data) === checksum;
  }

  /**
   * 字符串转字节数组
   */
  private stringToBytes(str: string): number[] {
    const bytes: number[] = [];
    for (let i = 0; i < str.length; i++) {
      const char = str.charCodeAt(i);
      bytes.push(char >>> 8, char & 0xff);
    }
    return bytes;
  }

  /**
   * 字节数组转 Base64
   */
  private bytesToBase64(bytes: number[]): string {
    const chars: string[] = [];
    for (let i = 0; i < bytes.length; i += 3) {
      const b1 = bytes[i];
      const b2 = bytes[i + 1] ?? 0;
      const b3 = bytes[i + 2] ?? 0;

      const bitmap = (b1 << 16) | (b2 << 8) | b3;

      chars.push(
        this.base64Chars[(bitmap >> 18) & 63],
        this.base64Chars[(bitmap >> 12) & 63],
        this.base64Chars[(bitmap >> 6) & 63],
        this.base64Chars[bitmap & 63]
      );
    }

    // 处理填充
    const padding = bytes.length % 3;
    if (padding === 1) {
      chars[chars.length - 2] = '=';
      chars[chars.length - 1] = '=';
    } else if (padding === 2) {
      chars[chars.length - 1] = '=';
    }

    return chars.join('');
  }

  private base64Chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

  /**
   * 生成设备指纹作为加密密钥
   */
  static generateDeviceFingerprint(): string {
    const components = [
      navigator.userAgent,
      navigator.language,
      screen.width + 'x' + screen.height,
      screen.colorDepth.toString(),
      new Date().getTimezoneOffset().toString(),
      !!navigator.hardwareConcurrency ? navigator.hardwareConcurrency.toString() : '0',
    ];

    // 简单哈希
    let hash = 0;
    const str = components.join('|');
    for (let i = 0; i < str.length; i++) {
      const char = str.charCodeAt(i);
      hash = ((hash << 5) - hash) + char;
      hash = hash & hash;
    }

    return Math.abs(hash).toString(36).padStart(16, '0');
  }

  /**
   * Base64 编码（用于导出）
   */
  static encodeBase64(data: string): string {
    try {
      return btoa(data);
    } catch (e) {
      // 处理非 Latin1 字符
      const bytes = new TextEncoder().encode(data);
      let binary = '';
      for (let i = 0; i < bytes.length; i++) {
        binary += String.fromCharCode(bytes[i]);
      }
      return btoa(binary);
    }
  }

  /**
   * Base64 解码（用于导入）
   */
  static decodeBase64(data: string): string {
    try {
      const binary = atob(data);
      const bytes = new Uint8Array(binary.length);
      for (let i = 0; i < binary.length; i++) {
        bytes[i] = binary.charCodeAt(i);
      }
      return new TextDecoder().decode(bytes);
    } catch (e) {
      throw new SaveError(
        SaveErrorType.INVALID_DATA,
        'Invalid base64 data'
      );
    }
  }
}
