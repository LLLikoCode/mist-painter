import Phaser from 'phaser';
import type { LevelEditor } from './LevelEditor';
import type { PixelPosition, PuzzleData, PuzzleType } from '../types';
import { PUZZLE_TEMPLATES } from '../config/editor.config';

/**
 * 谜题编辑器
 * 负责谜题元素的放置、编辑和管理
 */
export class PuzzleEditor {
  private editor: LevelEditor;
  private scene: Phaser.Scene | null = null;
  
  // 谜题对象映射
  private puzzleObjects: Map<string, Phaser.GameObjects.Container> = new Map();
  
  // 选中高亮
  private selectionGraphics: Phaser.GameObjects.Graphics | null = null;
  
  // 谜题容器
  private puzzleContainer: Phaser.GameObjects.Container | null = null;
  
  constructor(editor: LevelEditor) {
    this.editor = editor;
  }
  
  /**
   * 创建谜题编辑器
   */
  create(): void {
    this.scene = this.editor.getScene();
    if (!this.scene) return;
    
    // 创建谜题容器
    this.puzzleContainer = this.scene.add.container(0, 0);
    this.puzzleContainer.setDepth(10);
    
    // 创建选中高亮图形
    this.selectionGraphics = this.scene.add.graphics();
    this.selectionGraphics.setDepth(100);
    
    // 渲染现有谜题
    this.renderAllPuzzles();
  }
  
  /**
   * 放置谜题
   */
  placePuzzle(position: PixelPosition, puzzleType: PuzzleType): void {
    const levelData = this.editor.getLevelData();
    const template = PUZZLE_TEMPLATES.find(t => t.type === puzzleType);
    
    if (!template) return;
    
    // 生成唯一ID
    const id = `puzzle_${puzzleType}_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    
    // 创建谜题数据
    const puzzleData: PuzzleData = {
      id,
      type: puzzleType,
      name: template.name,
      position: { ...position },
      size: { ...template.defaultSize },
      properties: { ...template.defaultProperties },
      hint: template.description
    };
    
    // 特殊处理起点和终点
    if (puzzleType === PuzzleType.START_POINT) {
      // 移除旧的起点
      const oldStart = levelData.puzzles.find(p => p.type === PuzzleType.START_POINT);
      if (oldStart) {
        this.removePuzzle(oldStart.id);
      }
      levelData.spawnPoint = { ...position };
    } else if (puzzleType === PuzzleType.END_POINT) {
      // 移除旧的终点
      const oldEnd = levelData.puzzles.find(p => p.type === PuzzleType.END_POINT);
      if (oldEnd) {
        this.removePuzzle(oldEnd.id);
      }
      levelData.goal.position = { ...position };
      levelData.goal.radius = 40;
    }
    
    // 添加到关卡数据
    levelData.puzzles.push(puzzleData);
    
    // 创建视觉表示
    this.createPuzzleVisual(puzzleData);
    
    this.editor.emit('puzzle:placed', { puzzle: puzzleData });
    
    // 自动选中新放置的谜题
    this.editor.setSelectedObject({ type: 'puzzle', data: puzzleData });
  }
  
  /**
   * 创建谜题视觉表示
   */
  private createPuzzleVisual(puzzleData: PuzzleData): void {
    if (!this.scene || !this.puzzleContainer) return;
    
    const container = this.scene.add.container(puzzleData.position.x, puzzleData.position.y);
    
    // 根据类型创建不同的视觉
    const graphics = this.scene.add.graphics();
    
    switch (puzzleData.type) {
      case PuzzleType.START_POINT:
        graphics.fillStyle(0x00b894, 0.8);
        graphics.fillCircle(0, 0, 16);
        graphics.lineStyle(2, 0x00b894, 1);
        graphics.strokeCircle(0, 0, 16);
        break;
        
      case PuzzleType.END_POINT:
        graphics.fillStyle(0xe74c3c, 0.6);
        graphics.fillCircle(0, 0, 30);
        graphics.lineStyle(3, 0xe74c3c, 1);
        graphics.strokeCircle(0, 0, 30);
        // 内部标记
        graphics.fillStyle(0xffffff, 0.8);
        graphics.fillRect(-10, -10, 20, 20);
        break;
        
      case PuzzleType.COLLECTIBLE:
        graphics.fillStyle(0xf1c40f, 0.9);
        graphics.fillCircle(0, 0, 12);
        graphics.lineStyle(2, 0xf39c12, 1);
        graphics.strokeCircle(0, 0, 12);
        break;
        
      case PuzzleType.SWITCH:
        graphics.fillStyle(0x9b59b6, 0.8);
        graphics.fillRect(-20, -20, 40, 40);
        graphics.lineStyle(2, 0x8e44ad, 1);
        graphics.strokeRect(-20, -20, 40, 40);
        // 开关标记
        graphics.fillStyle(0xffffff, 0.6);
        graphics.fillCircle(0, 0, 8);
        break;
        
      case PuzzleType.PRESSURE_PLATE:
        graphics.fillStyle(0x95a5a6, 0.8);
        graphics.fillRect(-24, -24, 48, 48);
        graphics.lineStyle(2, 0x7f8c8d, 1);
        graphics.strokeRect(-24, -24, 48, 48);
        // 压力标记
        graphics.fillStyle(0x2c3e50, 0.5);
        graphics.fillRect(-16, -16, 32, 32);
        break;
        
      case PuzzleType.PATH_DRAWING:
        graphics.fillStyle(0x3498db, 0.3);
        graphics.fillRect(-50, -50, 100, 100);
        graphics.lineStyle(2, 0x3498db, 0.8);
        graphics.strokeRect(-50, -50, 100, 100);
        // 路径标记
        graphics.lineStyle(2, 0x3498db, 1);
        graphics.moveTo(-30, 0);
        graphics.lineTo(30, 0);
        graphics.strokePath();
        break;
        
      case PuzzleType.SEQUENCE:
        graphics.fillStyle(0xe67e22, 0.7);
        graphics.fillRect(-24, -24, 48, 48);
        graphics.lineStyle(2, 0xd35400, 1);
        graphics.strokeRect(-24, -24, 48, 48);
        // 数字标记
        const text = this.scene.add.text(0, 0, '1', {
          fontSize: '20px',
          color: '#ffffff',
          fontStyle: 'bold'
        });
        text.setOrigin(0.5);
        container.add(text);
        break;
        
      case PuzzleType.SYMBOL_MATCH:
        graphics.fillStyle(0x1abc9c, 0.7);
        graphics.fillRect(-24, -24, 48, 48);
        graphics.lineStyle(2, 0x16a085, 1);
        graphics.strokeRect(-24, -24, 48, 48);
        // 符号标记
        const symbolText = this.scene.add.text(0, 0, '★', {
          fontSize: '24px',
          color: '#ffffff'
        });
        symbolText.setOrigin(0.5);
        container.add(symbolText);
        break;
        
      case PuzzleType.LIGHT_MIRROR:
        graphics.fillStyle(0xf39c12, 0.7);
        graphics.fillRect(-30, -30, 60, 60);
        graphics.lineStyle(2, 0xe67e22, 1);
        graphics.strokeRect(-30, -30, 60, 60);
        // 光线标记
        graphics.lineStyle(3, 0xffffff, 0.8);
        graphics.moveTo(-15, 0);
        graphics.lineTo(15, 0);
        graphics.strokePath();
        break;
        
      case PuzzleType.COMBINATION:
        graphics.fillStyle(0x5d4037, 0.9);
        graphics.fillRect(-40, -60, 80, 120);
        graphics.lineStyle(3, 0x3e2723, 1);
        graphics.strokeRect(-40, -60, 80, 120);
        // 门锁标记
        graphics.fillStyle(0xffd700, 0.8);
        graphics.fillCircle(0, 0, 12);
        break;
        
      default:
        graphics.fillStyle(0x95a5a6, 0.5);
        graphics.fillRect(-20, -20, 40, 40);
    }
    
    container.add(graphics);
    
    // 添加标签
    const label = this.scene.add.text(0, puzzleData.size.height / 2 + 10, puzzleData.name, {
      fontSize: '12px',
      color: '#ffffff',
      backgroundColor: '#00000080'
    });
    label.setOrigin(0.5, 0);
    container.add(label);
    
    // 设置交互
    graphics.setInteractive(new Phaser.Geom.Rectangle(
      -puzzleData.size.width / 2,
      -puzzleData.size.height / 2,
      puzzleData.size.width,
      puzzleData.size.height
    ), Phaser.Geom.Rectangle.Contains);
    
    graphics.on('pointerdown', () => {
      this.editor.setSelectedObject({ type: 'puzzle', data: puzzleData });
      this.highlightPuzzle(puzzleData.id);
    });
    
    graphics.on('pointerover', () => {
      document.body.style.cursor = 'pointer';
    });
    
    graphics.on('pointerout', () => {
      document.body.style.cursor = 'default';
    });
    
    // 添加到容器
    this.puzzleContainer.add(container);
    this.puzzleObjects.set(puzzleData.id, container);
  }
  
  /**
   * 高亮谜题
   */
  highlightPuzzle(puzzleId: string): void {
    if (!this.selectionGraphics) return;
    
    this.selectionGraphics.clear();
    
    const container = this.puzzleObjects.get(puzzleId);
    if (!container) return;
    
    // 绘制选中框
    this.selectionGraphics.lineStyle(2, 0xe94560, 1);
    this.selectionGraphics.strokeRect(
      container.x - 30,
      container.y - 30,
      60,
      60
    );
  }
  
  /**
   * 移除谜题
   */
  removePuzzle(puzzleId: string): void {
    const container = this.puzzleObjects.get(puzzleId);
    if (container) {
      container.destroy();
      this.puzzleObjects.delete(puzzleId);
    }
    
    const levelData = this.editor.getLevelData();
    const index = levelData.puzzles.findIndex(p => p.id === puzzleId);
    if (index >= 0) {
      levelData.puzzles.splice(index, 1);
    }
  }
  
  /**
   * 渲染所有谜题
   */
  private renderAllPuzzles(): void {
    const levelData = this.editor.getLevelData();
    for (const puzzle of levelData.puzzles) {
      this.createPuzzleVisual(puzzle);
    }
  }
  
  /**
   * 更新
   */
  update(time: number, delta: number): void {
    // 谜题编辑器更新逻辑
  }
}