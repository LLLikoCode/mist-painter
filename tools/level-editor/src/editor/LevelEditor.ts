import Phaser from 'phaser';
import type { LevelData, EditorState, EditorTool, PixelPosition, GridPosition, PuzzleData, TileData, MistZone } from '../types';
import { TileType, PuzzleType } from '../types';
import { DEFAULT_EDITOR_CONFIG, DEFAULT_LEVEL_SIZE } from '../config/editor.config';
import { MapEditor } from './MapEditor';
import { PuzzleEditor } from './PuzzleEditor';
import { MistEditor } from './MistEditor';
import { LevelExporter } from '../export/LevelExporter';

/**
 * 关卡编辑器主类
 * 整合地图编辑、谜题编辑和迷雾编辑功能
 */
export class LevelEditor {
  private game: Phaser.Game | null = null;
  private scene: Phaser.Scene | null = null;
  private levelData: LevelData;
  private state: EditorState;
  private mapEditor: MapEditor;
  private puzzleEditor: PuzzleEditor;
  private mistEditor: MistEditor;
  private exporter: LevelExporter;
  
  // 事件监听
  private eventListeners: Map<string, Set<(data: unknown) => void>> = new Map();
  
  // 选中对象
  private selectedObject: unknown = null;
  
  constructor() {
    // 初始化空关卡
    this.levelData = this.createEmptyLevel();
    
    // 初始化编辑器状态
    this.state = {
      currentTool: EditorTool.SELECT,
      selectedTileType: TileType.FLOOR,
      selectedPuzzleType: PuzzleType.SWITCH,
      brushSize: 30,
      zoom: 100,
      gridVisible: true,
      snapToGrid: true
    };
    
    // 初始化子编辑器
    this.mapEditor = new MapEditor(this);
    this.puzzleEditor = new PuzzleEditor(this);
    this.mistEditor = new MistEditor(this);
    this.exporter = new LevelExporter();
  }
  
  /**
   * 初始化Phaser游戏
   */
  init(containerId: string): void {
    const config: Phaser.Types.Core.GameConfig = {
      type: Phaser.AUTO,
      width: 1280,
      height: 720,
      parent: containerId,
      backgroundColor: '#1a1a2e',
      scale: {
        mode: Phaser.Scale.FIT,
        autoCenter: Phaser.Scale.CENTER_BOTH
      },
      scene: {
        preload: this.preload.bind(this),
        create: this.create.bind(this),
        update: this.update.bind(this)
      }
    };
    
    this.game = new Phaser.Game(config);
  }
  
  /**
   * 资源预加载
   */
  private preload(): void {
    // 创建基础图形资源
    const graphics = this.scene!.make.graphics({ x: 0, y: 0, add: false });
    
    // 网格纹理
    graphics.clear();
    graphics.lineStyle(1, 0x333333, 0.5);
    for (let i = 0; i <= 40; i++) {
      graphics.moveTo(i * 32, 0);
      graphics.lineTo(i * 32, 720);
    }
    for (let i = 0; i <= 22; i++) {
      graphics.moveTo(0, i * 32);
      graphics.lineTo(1280, i * 32);
    }
    graphics.strokePath();
    graphics.generateTexture('grid', 1280, 720);
    
    // 各种图块纹理
    this.createTileTexture('tile_floor', 0x2d3436);
    this.createTileTexture('tile_wall', 0x636e72);
    this.createTileTexture('tile_water', 0x0984e3);
    this.createTileTexture('tile_grass', 0x00b894);
    this.createTileTexture('tile_stone', 0xb2bec3);
    this.createTileTexture('tile_wood', 0x8b5a2b);
    
    // 谜题图标
    this.createPuzzleTextures();
  }
  
  /**
   * 创建图块纹理
   */
  private createTileTexture(key: string, color: number): void {
    const graphics = this.scene!.make.graphics({ x: 0, y: 0, add: false });
    graphics.fillStyle(color, 1);
    graphics.fillRect(0, 0, 32, 32);
    graphics.lineStyle(1, 0xffffff, 0.1);
    graphics.strokeRect(0, 0, 32, 32);
    graphics.generateTexture(key, 32, 32);
  }
  
  /**
   * 创建谜题纹理
   */
  private createPuzzleTextures(): void {
    const graphics = this.scene!.make.graphics({ x: 0, y: 0, add: false });
    
    // 起点
    graphics.clear();
    graphics.fillStyle(0x00b894, 0.8);
    graphics.fillCircle(16, 16, 16);
    graphics.generateTexture('puzzle_start', 32, 32);
    
    // 终点
    graphics.clear();
    graphics.fillStyle(0xe74c3c, 0.8);
    graphics.fillCircle(30, 30, 30);
    graphics.generateTexture('puzzle_end', 60, 60);
    
    // 收集物
    graphics.clear();
    graphics.fillStyle(0xf1c40f, 0.9);
    graphics.fillCircle(12, 12, 12);
    graphics.generateTexture('puzzle_collectible', 24, 24);
    
    // 开关
    graphics.clear();
    graphics.fillStyle(0x9b59b6, 0.8);
    graphics.fillRect(0, 0, 40, 40);
    graphics.generateTexture('puzzle_switch', 40, 40);
    
    // 压力板
    graphics.clear();
    graphics.fillStyle(0x95a5a6, 0.8);
    graphics.fillRect(0, 0, 48, 48);
    graphics.generateTexture('puzzle_plate', 48, 48);
    
    // 门
    graphics.clear();
    graphics.fillStyle(0x5d4037, 0.9);
    graphics.fillRect(0, 0, 80, 120);
    graphics.generateTexture('puzzle_door', 80, 120);
  }
  
  /**
   * 场景创建
   */
  private create(): void {
    this.scene = this.game!.scene.scenes[0];
    
    // 创建网格
    this.createGrid();
    
    // 创建地图层
    this.mapEditor.create();
    
    // 创建谜题层
    this.puzzleEditor.create();
    
    // 创建迷雾层
    this.mistEditor.create();
    
    // 设置输入事件
    this.setupInput();
    
    // 触发初始化完成事件
    this.emit('editor:ready', {});
  }
  
  /**
   * 创建网格
   */
  private createGrid(): void {
    const grid = this.scene!.add.image(640, 360, 'grid');
    grid.setDepth(0);
    grid.setAlpha(0.3);
    grid.setVisible(this.state.gridVisible);
  }
  
  /**
   * 设置输入事件
   */
  private setupInput(): void {
    const canvas = this.scene!.game.canvas;
    
    canvas.addEventListener('mousedown', (e) => {
      const rect = canvas.getBoundingClientRect();
      const x = (e.clientX - rect.left) * (1280 / rect.width);
      const y = (e.clientY - rect.top) * (720 / rect.height);
      
      this.handleCanvasClick({ x, y }, e.button);
    });
    
    canvas.addEventListener('mousemove', (e) => {
      const rect = canvas.getBoundingClientRect();
      const x = (e.clientX - rect.left) * (1280 / rect.width);
      const y = (e.clientY - rect.top) * (720 / rect.height);
      
      this.emit('canvas:mousemove', { position: { x, y } });
    });
  }
  
  /**
   * 处理画布点击
   */
  private handleCanvasClick(position: PixelPosition, button: number): void {
    if (button !== 0) return; // 只处理左键
    
    const gridPos = this.pixelToGrid(position);
    
    switch (this.state.currentTool) {
      case EditorTool.TERRAIN:
        this.mapEditor.placeTile(gridPos, this.state.selectedTileType);
        break;
      case EditorTool.PUZZLE:
        this.puzzleEditor.placePuzzle(position, this.state.selectedPuzzleType);
        break;
      case EditorTool.MIST:
        this.mistEditor.paintMist(position, this.state.brushSize);
        break;
      case EditorTool.ERASER:
        this.eraseAt(position);
        break;
      case EditorTool.SELECT:
        this.selectAt(position);
        break;
    }
    
    this.emit('canvas:clicked', { position, button });
  }
  
  /**
   * 像素坐标转网格坐标
   */
  pixelToGrid(position: PixelPosition): GridPosition {
    if (this.state.snapToGrid) {
      return {
        x: Math.floor(position.x / DEFAULT_EDITOR_CONFIG.defaultTileSize),
        y: Math.floor(position.y / DEFAULT_EDITOR_CONFIG.defaultTileSize)
      };
    }
    return { x: position.x, y: position.y };
  }
  
  /**
   * 网格坐标转像素坐标
   */
  gridToPixel(gridPos: GridPosition): PixelPosition {
    return {
      x: gridPos.x * DEFAULT_EDITOR_CONFIG.defaultTileSize,
      y: gridPos.y * DEFAULT_EDITOR_CONFIG.defaultTileSize
    };
  }
  
  /**
   * 更新循环
   */
  private update(time: number, delta: number): void {
    // 子编辑器更新
    this.mapEditor.update(time, delta);
    this.puzzleEditor.update(time, delta);
    this.mistEditor.update(time, delta);
  }
  
  /**
   * 创建空关卡
   */
  private createEmptyLevel(): LevelData {
    return {
      metadata: {
        id: 'level_' + Date.now(),
        name: '未命名关卡',
        description: '',
        version: '1.0.0'
      },
      gridSize: DEFAULT_LEVEL_SIZE,
      tileSize: DEFAULT_EDITOR_CONFIG.defaultTileSize,
      layers: {
        floor: [],
        walls: [],
        decorations: []
      },
      puzzles: [],
      mist: {
        defaultDensity: 0.95,
        zones: []
      },
      spawnPoint: { x: 100, y: 360 },
      goal: {
        position: { x: 1100, y: 360 },
        radius: 40
      }
    };
  }
  
  /**
   * 获取Phaser场景
   */
  getScene(): Phaser.Scene | null {
    return this.scene;
  }
  
  /**
   * 获取关卡数据
   */
  getLevelData(): LevelData {
    return this.levelData;
  }
  
  /**
   * 获取当前工具
   */
  getCurrentTool(): EditorTool {
    return this.state.currentTool;
  }
  
  /**
   * 获取选中的图块类型
   */
  getSelectedTileType(): TileType {
    return this.state.selectedTileType;
  }
  
  /**
   * 获取选中的谜题类型
   */
  getSelectedPuzzleType(): PuzzleType {
    return this.state.selectedPuzzleType;
  }
  
  /**
   * 获取笔刷大小
   */
  getBrushSize(): number {
    return this.state.brushSize;
  }
  
  /**
   * 获取选中对象
   */
  getSelectedObject(): unknown {
    return this.selectedObject;
  }
  
  /**
   * 设置当前工具
   */
  setTool(tool: EditorTool): void {
    this.state.currentTool = tool;
    this.emit('tool:changed', { tool });
  }
  
  /**
   * 设置选中的图块类型
   */
  setSelectedTileType(tileType: TileType): void {
    this.state.selectedTileType = tileType;
    this.emit('tiletype:changed', { tileType });
  }
  
  /**
   * 设置选中的谜题类型
   */
  setSelectedPuzzleType(puzzleType: PuzzleType): void {
    this.state.selectedPuzzleType = puzzleType;
    this.emit('puzzletype:changed', { puzzleType });
  }
  
  /**
   * 设置笔刷大小
   */
  setBrushSize(size: number): void {
    this.state.brushSize = size;
    this.emit('brushsize:changed', { size });
  }
  
  /**
   * 设置选中对象
   */
  setSelectedObject(obj: unknown): void {
    this.selectedObject = obj;
    this.emit('selection:changed', { selection: obj });
  }
  
  /**
   * 擦除指定位置的对象
   */
  private eraseAt(position: PixelPosition): void {
    // 这里可以实现擦除逻辑
    this.emit('erase', { position });
  }
  
  /**
   * 选择指定位置的对象
   */
  private selectAt(position: PixelPosition): void {
    // 这里可以实现选择逻辑
    this.emit('select', { position });
  }
  
  /**
   * 创建新关卡
   */
  newLevel(): void {
    this.levelData = this.createEmptyLevel();
    // 重新渲染
    if (this.scene) {
      this.scene.scene.restart();
    }
    this.emit('level:new', {});
  }
  
  /**
   * 保存关卡
   */
  saveLevel(): void {
    const data = JSON.stringify(this.levelData, null, 2);
    const blob = new Blob([data], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = this.levelData.metadata.id + '.json';
    a.click();
    URL.revokeObjectURL(url);
    this.emit('level:saved', { path: a.download });
  }
  
  /**
   * 加载关卡
   */
  loadLevel(data: LevelData): void {
    this.levelData = data;
    if (this.scene) {
      this.scene.scene.restart();
    }
    this.emit('level:loaded', { level: data });
  }
  
  /**
   * 导出关卡
   */
  exportLevel(format: 'json' | 'tscn' = 'json'): string {
    let content: string;
    let extension: string;
    
    if (format === 'tscn') {
      content = this.exporter.exportToTSCN(this.levelData);
      extension = 'tscn';
    } else {
      content = this.exporter.exportToJSON(this.levelData, {
        format: 'json',
        includeMetadata: true,
        minify: false
      });
      extension = 'json';
    }
    
    const blob = new Blob([content], { type: 'text/plain' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = this.levelData.metadata.id + '.' + extension;
    a.click();
    URL.revokeObjectURL(url);
    
    this.emit('level:exported', { path: a.download, format });
    return content;
  }
  
  /**
   * 注册事件监听
   */
  on(event: string, callback: (data: unknown) => void): void {
    if (!this.eventListeners.has(event)) {
      this.eventListeners.set(event, new Set());
    }
    this.eventListeners.get(event)!.add(callback);
  }
  
  /**
   * 移除事件监听
   */
  off(event: string, callback: (data: unknown) => void): void {
    const listeners = this.eventListeners.get(event);
    if (listeners) {
      listeners.delete(callback);
    }
  }
  
  /**
   * 触发事件
   */
  emit(event: string, data: unknown): void {
    const listeners = this.eventListeners.get(event);
    if (listeners) {
      listeners.forEach(callback => callback(data));
    }
  }
}