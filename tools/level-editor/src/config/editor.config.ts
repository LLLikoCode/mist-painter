import type { EditorConfig, PuzzleTemplate, TileConfig, GridSize } from '../types';
import { TileType, PuzzleType } from '../types';

/** 默认编辑器配置 */
export const DEFAULT_EDITOR_CONFIG: EditorConfig = {
  defaultGridSize: { width: 40, height: 22 },
  defaultTileSize: 32,
  maxZoom: 300,
  minZoom: 25,
  zoomStep: 25,
  autoSaveInterval: 30000 // 30秒
};

/** 默认关卡尺寸 (1280x720 分辨率，32px 图块) */
export const DEFAULT_LEVEL_SIZE: GridSize = {
  width: 40,
  height: 22
};

/** 图块配置 */
export const TILE_CONFIGS: TileConfig[] = [
  {
    type: TileType.EMPTY,
    name: '空白',
    icon: '⬜',
    color: '#1a1a2e',
    walkable: false,
    description: '空白区域'
  },
  {
    type: TileType.FLOOR,
    name: '地板',
    icon: '▦',
    color: '#2d3436',
    walkable: true,
    description: '基础地板'
  },
  {
    type: TileType.WALL,
    name: '墙壁',
    icon: '▪',
    color: '#636e72',
    walkable: false,
    description: '阻挡移动的墙壁'
  },
  {
    type: TileType.WATER,
    name: '水域',
    icon: '≈',
    color: '#0984e3',
    walkable: false,
    description: '不可通行的水域'
  },
  {
    type: TileType.GRASS,
    name: '草地',
    icon: '❀',
    color: '#00b894',
    walkable: true,
    description: '草地地形'
  },
  {
    type: TileType.STONE,
    name: '石板',
    icon: '◈',
    color: '#b2bec3',
    walkable: true,
    description: '石板地面'
  },
  {
    type: TileType.WOOD,
    name: '木板',
    icon: '▭',
    color: '#8b5a2b',
    walkable: true,
    description: '木质地板'
  }
];

/** 谜题模板配置 */
export const PUZZLE_TEMPLATES: PuzzleTemplate[] = [
  {
    type: PuzzleType.START_POINT,
    name: '起点',
    icon: '🚀',
    defaultSize: { width: 32, height: 32 },
    defaultProperties: {},
    description: '玩家起始位置'
  },
  {
    type: PuzzleType.END_POINT,
    name: '终点',
    icon: '🏁',
    defaultSize: { width: 60, height: 60 },
    defaultProperties: {},
    description: '关卡终点'
  },
  {
    type: PuzzleType.COLLECTIBLE,
    name: '收集物',
    icon: '💎',
    defaultSize: { width: 24, height: 24 },
    defaultProperties: { value: 1 },
    description: '可收集的物品'
  },
  {
    type: PuzzleType.SWITCH,
    name: '开关',
    icon: '🔘',
    defaultSize: { width: 40, height: 40 },
    defaultProperties: { 
      switches: [],
      targetStates: [],
      initialStates: []
    },
    description: '需要找到正确开关组合的谜题'
  },
  {
    type: PuzzleType.SEQUENCE,
    name: '序列谜题',
    icon: '🔢',
    defaultSize: { width: 48, height: 48 },
    defaultProperties: {
      sequence: [],
      maxLength: 5
    },
    description: '按正确顺序触发的谜题'
  },
  {
    type: PuzzleType.PRESSURE_PLATE,
    name: '压力板',
    icon: '⬛',
    defaultSize: { width: 48, height: 48 },
    defaultProperties: {
      plates: [],
      activationOrder: []
    },
    description: '需要按顺序踩下的压力板'
  },
  {
    type: PuzzleType.PATH_DRAWING,
    name: '路径绘制',
    icon: '〰',
    defaultSize: { width: 100, height: 100 },
    defaultProperties: {
      waypoints: [],
      tolerance: 30
    },
    description: '需要绘制正确路径的谜题'
  },
  {
    type: PuzzleType.SYMBOL_MATCH,
    name: '符号匹配',
    icon: '🔣',
    defaultSize: { width: 48, height: 48 },
    defaultProperties: {
      symbols: [],
      matchesRequired: 3
    },
    description: '匹配符号的谜题'
  },
  {
    type: PuzzleType.LIGHT_MIRROR,
    name: '光线反射',
    icon: '💡',
    defaultSize: { width: 60, height: 60 },
    defaultProperties: {
      mirrors: [],
      lightSource: { x: 0, y: 0 },
      target: { x: 0, y: 0 }
    },
    description: '调整镜子反射光线到目标'
  },
  {
    type: PuzzleType.COMBINATION,
    name: '组合谜题',
    icon: '🔐',
    defaultSize: { width: 80, height: 120 },
    defaultProperties: {
      subPuzzles: [],
      solvedCount: 0
    },
    description: '需要解决多个子谜题的组合'
  }
];

/** 迷雾工具配置 */
export const MIST_TOOL_CONFIG = {
  brushSizes: [10, 20, 30, 50, 80, 100],
  defaultBrushSize: 30,
  minDensity: 0,
  maxDensity: 1,
  defaultDensity: 0.95
};

/** 导出配置 */
export const EXPORT_CONFIG = {
  jsonIndent: 2,
  supportedFormats: ['json', 'tscn'] as const,
  defaultFormat: 'json' as const
};

/** 快捷键配置 */
export const KEYBOARD_SHORTCUTS = {
  '1': 'select',
  '2': 'terrain',
  '3': 'puzzle',
  '4': 'mist',
  '5': 'eraser',
  'Ctrl+s': 'save',
  'Ctrl+o': 'open',
  'Ctrl+n': 'new',
  'Ctrl+e': 'export',
  'Ctrl+z': 'undo',
  'Ctrl+y': 'redo',
  'Delete': 'delete',
  'Escape': 'deselect'
};
