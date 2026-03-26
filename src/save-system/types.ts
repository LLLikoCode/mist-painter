/**
 * 迷雾绘者 - 存档系统类型定义
 * Save System Type Definitions
 */

// ==================== 基础类型 ====================

export enum SaveType {
  AUTO = 'auto',
  MANUAL = 'manual',
  CHECKPOINT = 'checkpoint',
  QUIT = 'quit',
}

export enum CellType {
  WALL = 0,
  PATH = 1,
  ROOM = 2,
  ENTRANCE = 3,
  EXIT = 4,
  STAIRS_UP = 5,
  STAIRS_DOWN = 6,
  SECRET_DOOR = 7,
  TELEPORTER = 8,
  TRAP = 9,
}

export enum Direction {
  UP = 0,
  RIGHT = 1,
  DOWN = 2,
  LEFT = 3,
}

export enum ToolType {
  PENCIL = 'pencil',
  QUILL = 'quill',
  SURVEYOR = 'surveyor',
  SCROLL = 'scroll',
}

export enum PaperType {
  NORMAL = 'normal',
  DURABLE = 'durable',
  WATERPROOF = 'waterproof',
}

export enum MarkType {
  IMPORTANT = 'important',
  DANGER = 'danger',
  TREASURE = 'treasure',
  EXIT = 'exit',
  NOTE = 'note',
}

// ==================== 存档数据结构 ====================

export interface SaveData {
  version: string;
  gameVersion: string;
  timestamp: number;
  playTime: number;
  saveType: SaveType;
  player: PlayerData;
  world: WorldData;
  settings: GameSettings;
  statistics: GameStatistics;
  checksum?: string;
}

export interface PlayerData {
  id: string;
  name: string;
  level: number;
  exp: number;
  position: Position;
  layer: number;
  direction: Direction;
  stamina: number;
  maxStamina: number;
  equippedTool: ToolData | null;
  lightSource: LightSourceData | null;
  inventory: InventoryData;
  drawnMaps: Record<number, PlayerMapData>;
  unlockedTools: string[];
  discoveredSecrets: string[];
}

export interface Position {
  x: number;
  y: number;
}

export interface ToolData {
  type: ToolType;
  name: string;
  durability: number;
  maxDurability: number;
  accuracy: number;
  speed: number;
  erasable: boolean;
}

export interface LightSourceData {
  id: string;
  name: string;
  radiusBonus: number;
  duration: number;
  maxDuration: number;
}

export interface InventoryData {
  items: InventoryItem[];
  maxSlots: number;
}

export interface InventoryItem {
  id: string;
  name: string;
  type: string;
  quantity: number;
  metadata?: Record<string, unknown>;
}

export interface PlayerMapData {
  layer: number;
  cells: Record<string, DrawnCellData>;
  lastVisited: Record<string, number>;
  paperType: PaperType;
  marks: MapMarkData[];
}

export interface DrawnCellData {
  x: number;
  y: number;
  drawnType: CellType;
  accuracy: number;
  timestamp: number;
  toolUsed: ToolType;
}

export interface MapMarkData {
  x: number;
  y: number;
  type: MarkType;
  note: string;
  timestamp: number;
}

// ==================== 世界数据 ====================

export interface WorldData {
  seed: string;
  currentLayer: number;
  layers: Record<number, LayerData>;
  globalState: GlobalState;
}

export interface LayerData {
  layer: number;
  maze: MazeData;
  visitedCells: string[];
  activatedTriggers: string[];
  collectedItems: string[];
  defeatedEnemies: string[];
  modifiedCells: Record<string, CellModification>;
}

export interface MazeData {
  width: number;
  height: number;
  cells: CellData[][];
  rooms: RoomData[];
  entrance: Position;
  exit: Position;
}

export interface CellData {
  x: number;
  y: number;
  type: CellType;
  discovered: boolean;
  isOneWay: boolean;
  oneWayDir: Direction | null;
  teleporterId: string | null;
  roomId: string | null;
  isShifting: boolean;
}

export interface RoomData {
  id: string;
  x: number;
  y: number;
  width: number;
  height: number;
  type: string;
}

export interface CellModification {
  x: number;
  y: number;
  originalType: CellType;
  currentType: CellType;
  shiftTimer: number;
}

export interface GlobalState {
  flags: Record<string, boolean>;
  variables: Record<string, number | string | boolean>;
  puzzlesSolved: string[];
  eventsTriggered: string[];
}

// ==================== 设置与统计 ====================

export interface GameSettings {
  masterVolume: number;
  musicVolume: number;
  sfxVolume: number;
  fullscreen: boolean;
  showFPS: boolean;
  minimapEnabled: boolean;
  autoSave: boolean;
  autoSaveInterval: number;
  tutorialEnabled: boolean;
  colorblindMode: boolean;
  highContrast: boolean;
  screenShake: boolean;
}

export interface GameStatistics {
  totalPlayTime: number;
  totalDeaths: number;
  totalSteps: number;
  mapsDrawn: number;
  puzzlesSolved: number;
  secretsFound: number;
  itemsCollected: number;
  layersExplored: number;
  achievements: string[];
  achievementProgress: Record<string, number>;
}

// ==================== 存档槽位 ====================

export interface SaveSlotInfo {
  slotId: number;
  exists: boolean;
  timestamp: number | null;
  playTime: number | null;
  playerLevel: number | null;
  currentLayer: number | null;
  thumbnail: string | null;
}

// ==================== 错误类型 ====================

export enum SaveErrorType {
  STORAGE_FULL = 'storage_full',
  CORRUPTED = 'corrupted',
  VERSION_MISMATCH = 'version_mismatch',
  PERMISSION_DENIED = 'permission_denied',
  NOT_FOUND = 'not_found',
  INVALID_DATA = 'invalid_data',
  UNKNOWN = 'unknown',
}

export class SaveError extends Error {
  constructor(
    public type: SaveErrorType,
    message: string,
    public originalError?: Error
  ) {
    super(message);
    this.name = 'SaveError';
  }
}

// ==================== 配置类型 ====================

export interface SaveSystemConfig {
  version: string;
  gameVersion: string;
  maxManualSlots: number;
  maxAutoSaves: number;
  encryptionKey: string;
  enableEncryption: boolean;
  enableCompression: boolean;
  autoSaveInterval: number;
  backupCount: number;
}

export interface AutoSaveConfig {
  enabled: boolean;
  interval: number;
  maxAutoSaves: number;
  triggers: AutoSaveTrigger[];
}

export enum AutoSaveTrigger {
  INTERVAL = 'interval',
  CHECKPOINT = 'checkpoint',
  LAYER_CHANGE = 'layer',
  REST = 'rest',
  BEFORE_COMBAT = 'pre_combat',
  PUZZLE_SOLVED = 'puzzle',
}

// ==================== 存储适配器接口 ====================

export interface StorageAdapter {
  get(key: string): Promise<string | null>;
  set(key: string, value: string): Promise<void>;
  remove(key: string): Promise<void>;
  keys(): Promise<string[]>;
  clear(): Promise<void>;
  getSize(): Promise<number>;
  getQuota(): Promise<number | null>;
}
