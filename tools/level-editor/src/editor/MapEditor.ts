import Phaser from 'phaser';
import type { LevelEditor } from './LevelEditor';
import type { GridPosition, TileData, TileType } from '../types';
import { DEFAULT_EDITOR_CONFIG } from '../config/editor.config';

/**
 * 地图编辑器
 * 负责地形层的编辑和管理
 */
export class MapEditor {
  private editor: LevelEditor;
  private scene: Phaser.Scene | null = null;
  
  // 图块精灵映射
  private tileSprites: Map<string, Phaser.GameObjects.Sprite> = new Map();
  
  // 当前编辑层
  private currentLayer: 'floor' | 'walls' | 'decorations' = 'floor';
  
  // 图层容器
  private layerContainers: Map<string, Phaser.GameObjects.Container> = new Map();
  
  constructor(editor: LevelEditor) {
    this.editor = editor;
   }
  
  /**
   * 创建地图编辑器
   */
  create(): void {
    this.scene = this.editor.getScene();
    if (!this.scene) return;
    
    // 创建图层容器
    const floorContainer = this.scene.add.container(0, 0);
    const wallsContainer = this.scene.add.container(0, 0);
    const decorationsContainer = this.scene.add.container(0, 0);
    
    floorContainer.setDepth(1);
    wallsContainer.setDepth(2);
    decorationsContainer.setDepth(3);
    
    this.layerContainers.set('floor', floorContainer);
    this.layerContainers.set('walls', wallsContainer);
    this.layerContainers.set('decorations', decorationsContainer);
    
    // 渲染现有图块
    this.renderAllTiles();
  }
  
  /**
   * 放置图块
   */
  placeTile(gridPos: GridPosition, tileType: TileType): void {
    const levelData = this.editor.getLevelData();
    const tileSize = DEFAULT_EDITOR_CONFIG.defaultTileSize;
    
    // 检查边界
    if (gridPos.x < 0 || gridPos.x >= levelData.gridSize.width ||
        gridPos.y < 0 || gridPos.y >= levelData.gridSize.height) {
      return;
    }
    
    // 移除该位置现有图块
    this.removeTileAt(gridPos, this.currentLayer);
    
    // 如果是空白，不创建新图块
    if (tileType === TileType.EMPTY) {
      this.editor.emit('tile:removed', { position: gridPos, layer: this.currentLayer });
      return;
    }
    
    // 创建新图块数据
    const tileData: TileData = {
      type: tileType,
      x: gridPos.x,
      y: gridPos.y,
      variant: 0,
      rotation: 0
    };
    
    // 添加到关卡数据
    levelData.layers[this.currentLayer].push(tileData);
    
    // 创建视觉表示
    this.createTileSprite(tileData, this.currentLayer);
    
    this.editor.emit('tile:placed', { tile: tileData, layer: this.currentLayer });
  }
  
  /**
   * 创建图块精灵
   */
  private createTileSprite(tileData: TileData, layer: string): void {
    if (!this.scene) return;
    
    const tileSize = DEFAULT_EDITOR_CONFIG.defaultTileSize;
    const x = tileData.x * tileSize + tileSize / 2;
    const y = tileData.y * tileSize + tileSize / 2;
    
    const textureKey = this.getTileTextureKey(tileData.type);
    const sprite = this.scene.add.sprite(x, y, textureKey);
    
    // 设置交互
    sprite.setInteractive();
    sprite.on('pointerdown', () => {
      this.editor.setSelectedObject({ type: 'tile', data: tileData, layer });
    });
    
    // 添加到图层容器
    const container = this.layerContainers.get(layer);
    if (container) {
      container.add(sprite);
    }
    
    // 保存引用
    const key = `${layer}_${tileData.x}_${tileData.y}`;
    this.tileSprites.set(key, sprite);
  }
  
  /**
   * 获取图块纹理键
   */
  private getTileTextureKey(tileType: TileType): string {
    switch (tileType) {
      case TileType.FLOOR: return 'tile_floor';
      case TileType.WALL: return 'tile_wall';
      case TileType.WATER: return 'tile_water';
      case TileType.GRASS: return 'tile_grass';
      case TileType.STONE: return 'tile_stone';
      case TileType.WOOD: return 'tile_wood';
      default: return 'tile_floor';
    }
  }
  
  /**
   * 移除指定位置的图块
   */
  removeTileAt(gridPos: GridPosition, layer: string): void {
    const levelData = this.editor.getLevelData();
    const tiles = levelData.layers[layer as keyof typeof levelData.layers];
    
    // 从数据中移除
    const index = tiles.findIndex(t => t.x === gridPos.x && t.y === gridPos.y);
    if (index >= 0) {
      tiles.splice(index, 1);
    }
    
    // 从视觉中移除
    const key = `${layer}_${gridPos.x}_${gridPos.y}`;
    const sprite = this.tileSprites.get(key);
    if (sprite) {
      sprite.destroy();
      this.tileSprites.delete(key);
    }
  }
  
  /**
   * 渲染所有图块
   */
  private renderAllTiles(): void {
    const levelData = this.editor.getLevelData();
    
    // 渲染地板层
    for (const tile of levelData.layers.floor) {
      this.createTileSprite(tile, 'floor');
    }
    
    // 渲染墙壁层
    for (const tile of levelData.layers.walls) {
      this.createTileSprite(tile, 'walls');
    }
    
    // 渲染装饰层
    for (const tile of levelData.layers.decorations) {
      this.createTileSprite(tile, 'decorations');
    }
  }
  
  /**
   * 清除所有图块
   */
  clearAll(): void {
    // 销毁所有精灵
    for (const sprite of this.tileSprites.values()) {
      sprite.destroy();
    }
    this.tileSprites.clear();
    
    // 清空数据
    const levelData = this.editor.getLevelData();
    levelData.layers.floor = [];
    levelData.layers.walls = [];
    levelData.layers.decorations = [];
  }
  
  /**
   * 设置当前编辑层
   */
  setCurrentLayer(layer: 'floor' | 'walls' | 'decorations'): void {
    this.currentLayer = layer;
    this.editor.emit('layer:changed', { layer });
  }
  
  /**
   * 获取当前编辑层
   */
  getCurrentLayer(): string {
    return this.currentLayer;
  }
  
  /**
   * 设置图层可见性
   */
  setLayerVisible(layer: string, visible: boolean): void {
    const container = this.layerContainers.get(layer);
    if (container) {
      container.setVisible(visible);
    }
  }
  
  /**
   * 填充区域
   */
  fillArea(startPos: GridPosition, endPos: GridPosition, tileType: TileType): void {
    const minX = Math.min(startPos.x, endPos.x);
    const maxX = Math.max(startPos.x, endPos.x);
    const minY = Math.min(startPos.y, endPos.y);
    const maxY = Math.max(startPos.y, endPos.y);
    
    for (let x = minX; x <= maxX; x++) {
      for (let y = minY; y <= maxY; y++) {
        this.placeTile({ x, y }, tileType);
      }
    }
  }
  
  /**
   * 更新
   */
  update(time: number, delta: number): void {
    // 地图编辑器更新逻辑
  }
  
  /**
   * 获取指定位置的图块
   */
  getTileAt(gridPos: GridPosition, layer: string): TileData | null {
    const levelData = this.editor.getLevelData();
    const tiles = levelData.layers[layer as keyof typeof levelData.layers];
    return tiles.find(t => t.x === gridPos.x && t.y === gridPos.y) || null;
  }
  
  /**
   * 获取所有图块数量
   */
  getTileCount(): number {
    const levelData = this.editor.getLevelData();
    return levelData.layers.floor.length + 
           levelData.layers.walls.length + 
           levelData.layers.decorations.length;
  }
}
