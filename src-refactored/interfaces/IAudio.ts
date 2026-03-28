/**
 * 音频系统接口
 * 负责管理背景音乐、音效、环境音的播放和控制
 */

/**
 * 音频总线类型
 */
export enum AudioBus {
  MASTER = 'Master',
  MUSIC = 'Music',
  SFX = 'SFX',
  AMBIENT = 'Ambient'
}

/**
 * 音频设置接口
 */
export interface AudioSettings {
  masterVolume: number;
  musicVolume: number;
  sfxVolume: number;
  ambientVolume: number;
  muted: boolean;
}

/**
 * 音频播放选项
 */
export interface AudioPlayOptions {
  /** 音量缩放（0-1） */
  volumeScale?: number;
  /** 音高缩放 */
  pitchScale?: number;
  /** 是否循环 */
  loop?: boolean;
  /** 淡入时长（秒） */
  fadeInDuration?: number;
}

/**
 * BGM播放选项
 */
export interface BGMPlayOptions extends AudioPlayOptions {
  /** 是否交叉淡入淡出 */
  crossfade?: boolean;
  /** 交叉淡入淡出时长（秒） */
  crossfadeDuration?: number;
}

/**
 * 音频系统接口
 */
export interface IAudioManager {
  /** 主音量（0-1） */
  masterVolume: number;
  /** 音乐音量（0-1） */
  musicVolume: number;
  /** 音效音量（0-1） */
  sfxVolume: number;
  /** 环境音音量（0-1） */
  ambientVolume: number;
  /** 是否静音 */
  isMuted: boolean;
  
  /**
   * 播放背景音乐
   * @param path 音频资源路径
   * @param options 播放选项
   */
  playBGM(path: string, options?: BGMPlayOptions): void;
  
  /**
   * 停止背景音乐
   * @param fadeOut 是否淡出
   * @param fadeDuration 淡出时长
   */
  stopBGM(fadeOut?: boolean, fadeDuration?: number): void;
  
  /**
   * 暂停背景音乐
   */
  pauseBGM(): void;
  
  /**
   * 恢复背景音乐
   */
  resumeBGM(): void;
  
  /**
   * 播放音效
   * @param path 音频资源路径
   * @param options 播放选项
   */
  playSFX(path: string, options?: AudioPlayOptions): void;
  
  /**
   * 预加载音效
   * @param paths 音频资源路径列表
   */
  preloadSFX(paths: string[]): void;
  
  /**
   * 停止所有音效
   */
  stopAllSFX(): void;
  
  /**
   * 播放环境音
   * @param path 音频资源路径
   * @param options 播放选项
   */
  playAmbient(path: string, options?: AudioPlayOptions): void;
  
  /**
   * 停止环境音
   * @param fadeOut 是否淡出
   * @param fadeDuration 淡出时长
   */
  stopAmbient(fadeOut?: boolean, fadeDuration?: number): void;
  
  /**
   * 设置总线音量
   * @param bus 音频总线
   * @param volume 音量（0-1）
   */
  setBusVolume(bus: AudioBus, volume: number): void;
  
  /**
   * 获取总线音量
   * @param bus 音频总线
   */
  getBusVolume(bus: AudioBus): number;
  
  /**
   * 设置静音
   * @param muted 是否静音
   */
  setMute(muted: boolean): void;
  
  /**
   * 切换静音状态
   * @returns 当前静音状态
   */
  toggleMute(): boolean;
  
  /**
   * 应用音频设置
   * @param settings 音频设置
   */
  applySettings(settings: AudioSettings): void;
  
  /**
   * 获取当前音频设置
   */
  getSettings(): AudioSettings;
  
  /**
   * 获取当前播放状态
   */
  getStatus(): AudioStatus;
  
  // 便捷方法
  playUISound(soundName: string): void;
  playConfirmSound(): void;
  playCancelSound(): void;
  playErrorSound(): void;
  playItemGetSound(): void;
  playFootstepSound(surface?: string): void;
  playDrawSound(): void;
  playEraseSound(): void;
  playMistClearSound(): void;
  playPuzzleCompleteSound(): void;
}

/**
 * 音频状态接口
 */
export interface AudioStatus {
  bgmPlaying: boolean;
  currentBGM: string | null;
  ambientPlaying: boolean;
  activeSFXCount: number;
  availableSFXChannels: number;
  sfxCacheSize: number;
  isMuted: boolean;
}
