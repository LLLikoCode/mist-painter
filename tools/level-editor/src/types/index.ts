// ============================================
// 关卡编辑器类型定义
// ============================================

/** 网格坐标 */
export interface GridPosition {
  x: number;
  y: number;
}

/** 像素坐标 */
export interface PixelPosition {
  x: number;
  y: number;
}

/** 网格大小 */
export interface GridSize {
  width: number;
  height: number;
}

/** 图块类型 */
export enum TileType {
  EMPTY = 0,
  FLOOR = 1,
  WALL = 2,
  WATER = 3,
  GRASS = 4,
  STONE = 5,
  WOOD = 6
}

/** 图块数据 */
export interface TileData {
  type: TileType;
  x: number;
  y: number;
  variant?: number;
  rotation?: number;
}

/** 地形层 */
export interface TerrainLayer {
  name: string;
  tiles: TileData[];
  visible: boolean;
}

/** 谜题类型 */
export enum PuzzleType {
  SWITCH = 'switch',
  SEQUENCE = 'sequence',
  PATH_DRAWING = 'path_drawing',
  SYMBOL_MATCH = 'symbol_match',
  LIGHT_MIRROR = 'light_mirror',
  PRESSURE_PLATE = 'pressure_plate',
  COMBINATION = 'combination',
  START_POINT = 'start_point',
  END_POINT = 'end_point',
  COLLECTIBLE = 'collectible'
}

/** 谜题数据 */
export interface PuzzleData {
  id: string;
  type: PuzzleType;
  name: string;
  position: PixelPosition;
  size: { width: number; height: number };
  properties: Record<string, unknown>;
  hint?: string;
  requiredPuzzles?: string[];
}

/** 迷雾区域 */
export interface MistZone {
  id: string;
  type: 'clear' | 'fill';
  position: PixelPosition;
  radius: number;
}

/** 迷雾数据 */
export interface MistData {
  defaultDensity: number;
  zones: MistZone[];
  clearOnStart?: PixelPosition[];
}

/** 关卡元数据 */
export interface LevelMetadata {
  id: string;
  name: string;
  description?: string;
  author?: string;
  createdAt?: string;
  updatedAt?: string;
  version?: string;
}

/** 完整关卡数据 */
export interface LevelData {
  metadata: LevelMetadata;
  gridSize: GridSize;
  tileSize: number;
  layers: {
    floor: TileData[];
    walls: TileData[];
    decorations: TileData[];
  };
  puzzles: PuzzleData[];
  mist: MistData;
  spawnPoint: PixelPosition;
  goal: {
    position: PixelPosition;
    radius: number;
  };
  cameraBounds?: {
    minX: number;
    minY: number;
    maxX: number;
    maxY: number;
  };
}

/** 编辑器工具类型 */
export enum EditorTool {
  SELECT = 'select',
  TERRAIN = 'terrain',
  PUZZLE = 'puzzle',
  MIST = 'mist',
  ERASER = 'eraser'
}

/** 编辑器状态 */
export interface EditorState {
  currentTool: EditorTool;
  selectedTileType: TileType;
  selectedPuzzleType: PuzzleType;
  brushSize: number;
  zoom: number;
  gridVisible: boolean;
  snapToGrid: boolean;
}

/** 编辑器配置 */
export interface EditorConfig {
  defaultGridSize: GridSize;
  defaultTileSize: number;
  maxZoom: number;
  minZoom: number;
  zoomStep: number;
  autoSaveInterval: number;
}

/** 导出选项 */
export interface ExportOptions {
  format: 'json' | 'tscn';
  includeMetadata: boolean;
  minify: boolean;
  outputPath?: string;
}

/** 编辑器事件 */
export interface EditorEvents {
  'tool:changed': { tool: EditorTool };
  'level:loaded': { level: LevelData };
  'level:saved': { path: string };
  'level:exported': { path: string; format: string };
  'selection:changed': { selection: unknown | null };
  'canvas:clicked': { position: PixelPosition; button: number };
  'property:changed': { property: string; value: unknown };
}

/** 谜题配置模板 */
export interface PuzzleTemplate {
  type: PuzzleType;
  name: string;
  icon: string;
  defaultSize: { width: number; height: number };
  defaultProperties: Record<string, unknown>;
  description: string;
}

/** 图块配置 */
export interface TileConfig {
  type: TileType;
  name: string;
  icon: string;
  color: string;
  walkable: boolean;
  description: string;
}
