import Phaser from 'phaser';
import type { LevelEditor } from './LevelEditor';
import type { PixelPosition, MistZone } from '../types';

/**
 * 迷雾编辑器
 * 负责迷雾区域的绘制和编辑
 */
export class MistEditor {
  private editor: LevelEditor;
  private scene: Phaser.Scene | null = null;
  
  // 迷雾纹理
  private mistTexture: Phaser.Textures.CanvasTexture | null = null;
  private mistSprite: Phaser.GameObjects.Sprite | null = null;
  private mistImage: HTMLCanvasElement | null = null;
  private mistContext: CanvasRenderingContext2D | null = null;
  
  // 笔刷预览
  private brushPreview: Phaser.GameObjects.Graphics | null = null;
  
  // 迷雾区域标记
  private zoneGraphics: Phaser.GameObjects.Graphics | null = null;
  
  // 绘制状态
  private isDrawing: boolean = false;
  private lastDrawPosition: PixelPosition | null = null;
  
  constructor(editor: LevelEditor) {
    this.editor = editor;
  }
  
  /**
   * 创建迷雾编辑器
   */
  create(): void {
    this.scene = this.editor.getScene();
    if (!this.scene) return;
    
    // 创建迷雾画布
    this.createMistCanvas();
    
    // 创建笔刷预览
    this.brushPreview = this.scene.add.graphics();
    this.brushPreview.setDepth(50);
    
    // 创建区域标记
    this.zoneGraphics = this.scene.add.graphics();
    this.zoneGraphics.setDepth(49);
    
    // 渲染现有迷雾区域
    this.renderMistZones();
  }
  
  /**
   * 创建迷雾画布
   */
  private createMistCanvas(): void {
    if (!this.scene) return;
    
    const width = 1280;
    const height = 720;
    
    // 创建HTML Canvas
    this.mistImage = document.createElement('canvas');
    this.mistImage.width = width;
    this.mistImage.height = height;
    this.mistContext = this.mistImage.getContext('2d')!;
    
    // 初始填充迷雾
    this.mistContext.fillStyle = 'rgba(10, 10, 20, 0.95)';
    this.mistContext.fillRect(0, 0, width, height);
    
    // 创建Phaser纹理
    this.mistTexture = this.scene.textures.addCanvas('mist_texture', this.mistImage);
    
    // 创建精灵
    this.mistSprite = this.scene.add.sprite(width / 2, height / 2, 'mist_texture');
    this.mistSprite.setDepth(20);
    this.mistSprite.setAlpha(0.9);
  }
  
  /**
   * 渲染迷雾区域
   */
  private renderMistZones(): void {
    const levelData = this.editor.getLevelData();
    
    for (const zone of levelData.mist.zones) {
      if (zone.type === 'clear') {
        this.clearMistCircle(zone.position, zone.radius);
      } else {
        this.fillMistCircle(zone.position, zone.radius);
      }
    }
  }
  
  /**
   * 绘制迷雾
   */
  paintMist(position: PixelPosition, radius: number): void {
    if (!this.mistContext || !this.mistTexture) return;
    
    // 清除该位置的迷雾
    this.clearMistCircle(position, radius);
    
    // 添加到关卡数据
    const levelData = this.editor.getLevelData();
    const zone: MistZone = {
      id: `mist_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
      type: 'clear',
      position: { ...position },
      radius
    };
    levelData.mist.zones.push(zone);
    
    this.editor.emit('mist:painted', { position, radius });
  }
  
  /**
   * 清除迷雾圆形区域
   */
  clearMistCircle(position: PixelPosition, radius: number): void {
    if (!this.mistContext || !this.mistTexture) return;
    
    // 使用径向渐变清除迷雾
    const gradient = this.mistContext.createRadialGradient(
      position.x, position.y, 0,
      position.x, position.y, radius
    );
    gradient.addColorStop(0, 'rgba(10, 10, 20, 0)');
    gradient.addColorStop(0.7, 'rgba(10, 10, 20, 0.3)');
    gradient.addColorStop(1, 'rgba(10, 10, 20, 0.95)');
    
    this.mistContext.globalCompositeOperation = 'destination-out';
    this.mistContext.beginPath();
    this.mistContext.arc(position.x, position.y, radius, 0, Math.PI * 2);
    this.mistContext.fillStyle = gradient;
    this.mistContext.fill();
    this.mistContext.globalCompositeOperation = 'source-over';
    
    // 更新纹理
    this.mistTexture.refresh();
  }
  
  /**
   * 填充迷雾圆形区域
   */
  fillMistCircle(position: PixelPosition, radius: number): void {
    if (!this.mistContext || !this.mistTexture) return;
    
    this.mistContext.globalCompositeOperation = 'source-over';
    this.mistContext.beginPath();
    this.mistContext.arc(position.x, position.y, radius, 0, Math.PI * 2);
    this.mistContext.fillStyle = 'rgba(10, 10, 20, 0.95)';
    this.mistContext.fill();
    
    // 更新纹理
    this.mistTexture.refresh();
  }
  
  /**
   * 更新笔刷预览
   */
  updateBrushPreview(position: PixelPosition, radius: number): void {
    if (!this.brushPreview) return;
    
    this.brushPreview.clear();
    this.brushPreview.lineStyle(2, 0xe94560, 0.8);
    this.brushPreview.strokeCircle(position.x, position.y, radius);
    this.brushPreview.fillStyle(0xe94560, 0.1);
    this.brushPreview.fillCircle(position.x, position.y, radius);
  }
  
  /**
   * 隐藏笔刷预览
   */
  hideBrushPreview(): void {
    if (!this.brushPreview) return;
    this.brushPreview.clear();
  }
  
  /**
   * 填充全部迷雾
   */
  fillAllMist(): void {
    if (!this.mistContext || !this.mistTexture) return;
    
    this.mistContext.fillStyle = 'rgba(10, 10, 20, 0.95)';
    this.mistContext.fillRect(0, 0, 1280, 720);
    this.mistTexture.refresh();
    
    // 清空区域数据
    const levelData = this.editor.getLevelData();
    levelData.mist.zones = [];
    
    this.editor.emit('mist:filled', {});
  }
  
  /**
   * 清除全部迷雾
   */
  clearAllMist(): void {
    if (!this.mistContext || !this.mistTexture) return;
    
    this.mistContext.clearRect(0, 0, 1280, 720);
    this.mistTexture.refresh();
    
    // 添加全清区域
    const levelData = this.editor.getLevelData();
    levelData.mist.zones = [{
      id: 'clear_all',
      type: 'clear',
      position: { x: 640, y: 360 },
      radius: 1000
    }];
    
    this.editor.emit('mist:cleared', {});
  }
  
  /**
   * 设置迷雾透明度
   */
  setMistAlpha(alpha: number): void {
    if (!this.mistSprite) return;
    this.mistSprite.setAlpha(alpha);
  }
  
  /**
   * 获取迷雾覆盖率
   */
  getMistCoverage(): number {
    if (!this.mistContext) return 1;
    
    const imageData = this.mistContext.getImageData(0, 0, 1280, 720);
    const data = imageData.data;
    let mistPixels = 0;
    
    // 采样计算
    const sampleStep = 4;
    for (let i = 3; i < data.length; i += 4 * sampleStep) {
      if (data[i] > 50) {
        mistPixels++;
      }
    }
    
    const totalSamples = (1280 * 720) / (sampleStep * sampleStep);
    return mistPixels / totalSamples;
  }
  
  /**
   * 更新
   */
  update(time: number, delta: number): void {
    // 迷雾编辑器更新逻辑
  }
  
  /**
   * 渲染区域标记
   */
  renderZoneMarkers(): void {
    if (!this.zoneGraphics) return;
    
    this.zoneGraphics.clear();
    
    const levelData = this.editor.getLevelData();
    for (const zone of levelData.mist.zones) {
      this.zoneGraphics.lineStyle(1, 0xe94560, 0.5);
      this.zoneGraphics.strokeCircle(zone.position.x, zone.position.y, zone.radius);
    }
  }
  
  /**
   * 移除迷雾区域
   */
  removeMistZone(zoneId: string): void {
    const levelData = this.editor.getLevelData();
    const index = levelData.mist.zones.findIndex(z => z.id === zoneId);
    if (index >= 0) {
      levelData.mist.zones.splice(index, 1);
      
      // 重新渲染
      if (this.mistContext && this.mistTexture) {
        this.mistContext.fillStyle = 'rgba(10, 10, 20, 0.95)';
        this.mistContext.fillRect(0, 0, 1280, 720);
        this.renderMistZones();
      }
      
      this.renderZoneMarkers();
    }
  }
}
