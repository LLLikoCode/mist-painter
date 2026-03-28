import type { LevelData, ExportOptions, PuzzleData, TileData } from '../types';
import { PuzzleType } from '../types';

/**
 * 关卡导出器
 * 负责将关卡数据导出为游戏可读取的格式
 */
export class LevelExporter {
  
  /**
   * 导出为JSON格式
   */
  exportToJSON(levelData: LevelData, options: ExportOptions): string {
    const exportData = this.prepareExportData(levelData, options);
    
    if (options.minify) {
      return JSON.stringify(exportData);
    }
    
    return JSON.stringify(exportData, null, 2);
  }
  
  /**
   * 导出为Godot场景格式(.tscn)
   */
  exportToTSCN(levelData: LevelData): string {
    const lines: string[] = [];
    
    // 文件头
    lines.push('[gd_scene load_steps=10 format=3 uid="uid://level_' + levelData.metadata.id + '"]');
    lines.push('');
    
    // 外部资源引用
    lines.push('[ext_resource type="Script" path="res://src/gameplay/PuzzleController.gd" id="1_puzzle_controller"]');
    lines.push('[ext_resource type="Script" path="res://src/gameplay/GameController.gd" id="2_game_controller"]');
    lines.push('');
    
    // 子资源定义
    lines.push('[sub_resource type="RectangleShape2D" id="PressurePlateShape"]');
    lines.push('size = Vector2(48, 48)');
    lines.push('');
    
    lines.push('[sub_resource type="RectangleShape2D" id="SwitchShape"]');
    lines.push('size = Vector2(40, 40)');
    lines.push('');
    
    lines.push('[sub_resource type="RectangleShape2D" id="DoorShape"]');
    lines.push('size = Vector2(80, 120)');
    lines.push('');
    
    lines.push('[sub_resource type="CircleShape2D" id="GoalShape"]');
    lines.push('radius = 40.0');
    lines.push('');
    
    // 场景根节点
    lines.push('[node name="' + this.sanitizeName(levelData.metadata.name) + '" type="Node2D"]');
    lines.push('');
    
    // TileMap
    lines.push('[node name="TileMap" type="TileMap" parent=".]');
    lines.push('format = 2');
    lines.push('');
    
    // 地板层
    lines.push('[node name="Floor" type="TileMapLayer" parent="TileMap"]');
    lines.push('');
    
    // 墙壁层
    lines.push('[node name="Walls" type="TileMapLayer" parent="TileMap"]');
    lines.push('');
    
    // 装饰层
    lines.push('[node name="Decorations" type="TileMapLayer" parent="TileMap"]');
    lines.push('');
    
    // 谜题节点
    lines.push('[node name="Puzzles" type="Node2D" parent=".]');
    lines.push('');
    
    // 导出谜题
    for (let i = 0; i < levelData.puzzles.length; i++) {
      const puzzle = levelData.puzzles[i];
      const nodeName = 'Puzzle' + (i + 1);
      
      lines.push(...this.exportPuzzleToTSCN(puzzle, nodeName, i + 1));
      lines.push('');
    }
    
    // 终点区域
    lines.push('[node name="Goal" type="Area2D" parent=".]');
    lines.push('position = Vector2(' + levelData.goal.position.x + ', ' + levelData.goal.position.y + ')');
    lines.push('');
    
    lines.push('[node name="CollisionShape2D" type="CollisionShape2D" parent="Goal"]');
    lines.push('shape = SubResource("GoalShape")');
    lines.push('');
    
    lines.push('[node name="Visual" type="ColorRect" parent="Goal"]');
    lines.push('offset_left = -30.0');
    lines.push('offset_top = -30.0');
    lines.push('offset_right = 30.0');
    lines.push('offset_bottom = 30.0');
    lines.push('color = Color(0.2, 0.8, 0.4, 0.5)');
    lines.push('');
    
    // 出生点
    lines.push('[node name="SpawnPoint" type="Marker2D" parent=".]');
    lines.push('position = Vector2(' + levelData.spawnPoint.x + ', ' + levelData.spawnPoint.y + ')');
    lines.push('');
    
    // 相机边界
    lines.push('[node name="CameraBounds" type="ReferenceRect" parent=".]');
    lines.push('offset_right = ' + (levelData.gridSize.width * levelData.tileSize) + '.0');
    lines.push('offset_bottom = ' + (levelData.gridSize.height * levelData.tileSize) + '.0');
    lines.push('');
    
    // 迷雾清除区域
    lines.push('[node name="MistClearZones" type="Node2D" parent=".]');
    lines.push('');
    
    for (let i = 0; i < levelData.mist.zones.length; i++) {
      const zone = levelData.mist.zones[i];
      if (zone.type === 'clear') {
        lines.push('[node name="ClearZone' + (i + 1) + '" type="Marker2D" parent="MistClearZones"]');
        lines.push('position = Vector2(' + zone.position.x + ', ' + zone.position.y + ')');
        lines.push('');
      }
    }
    
    return lines.join('\n');
  }
  
  /**
   * 导出单个谜题为TSCN格式
   */
  private exportPuzzleToTSCN(puzzle: PuzzleData, nodeName: string, index: number): string[] {
    const lines: string[] = [];
    
    lines.push('[node name="' + nodeName + '" type="Node2D" parent="Puzzles"]');
    lines.push('position = Vector2(' + puzzle.position.x + ', ' + puzzle.position.y + ')');
    lines.push('script = ExtResource("1_puzzle_controller")');
    lines.push('puzzle_id = "' + puzzle.id + '"');
    lines.push('puzzle_name = "' + puzzle.name + '"');
    
    // 谜题类型映射
    const typeMap: Record<string, number> = {
      'switch': 0,
      'sequence': 1,
      'path_drawing': 2,
      'symbol_match': 3,
      'light_mirror': 4,
      'pressure_plate': 5,
      'combination': 6
    };
    
    lines.push('puzzle_type = ' + (typeMap[puzzle.type] ?? 0));
    
    if (puzzle.hint) {
      lines.push('hint_text = "' + puzzle.hint + '"');
    }
    
    lines.push('');
    
    // 交互区域
    lines.push('[node name="InteractionArea" type="Area2D" parent="Puzzles/' + nodeName + '"]');
    lines.push('');
    
    let shapeId = 'SwitchShape';
    if (puzzle.type === PuzzleType.PRESSURE_PLATE) shapeId = 'PressurePlateShape';
    if (puzzle.type === PuzzleType.COMBINATION) shapeId = 'DoorShape';
    
    lines.push('[node name="CollisionShape2D" type="CollisionShape2D" parent="Puzzles/' + nodeName + '/InteractionArea"]');
    lines.push('shape = SubResource("' + shapeId + '")');
    lines.push('');
    
    // 视觉节点
    lines.push('[node name="Visual" type="Node2D" parent="Puzzles/' + nodeName + '"]');
    lines.push('');
    
    // 提示标签
    lines.push('[node name="HintLabel" type="Label" parent="Puzzles/' + nodeName + '"]');
    lines.push('visible = false');
    lines.push('offset_left = -40.0');
    lines.push('offset_top = -40.0');
    lines.push('offset_right = 40.0');
    lines.push('offset_bottom = -20.0');
    lines.push('text = "' + puzzle.name + '"');
    lines.push('horizontal_alignment = 1');
    
    return lines;
  }
  
  /**
   * 准备导出数据
   */
  private prepareExportData(levelData: LevelData, options: ExportOptions): unknown {
    const data: Record<string, unknown> = {
      level_id: levelData.metadata.id,
      level_name: levelData.metadata.name,
      grid_size: levelData.gridSize,
      tile_size: levelData.tileSize,
      layers: {
        floor: levelData.layers.floor.map(t => this.serializeTile(t)),
        walls: levelData.layers.walls.map(t => this.serializeTile(t)),
        decorations: levelData.layers.decorations.map(t => this.serializeTile(t))
      },
      puzzles: levelData.puzzles.map(p => this.serializePuzzle(p)),
      mist: {
        default_density: levelData.mist.defaultDensity,
        zones: levelData.mist.zones
      },
      spawn_point: levelData.spawnPoint,
      goal: levelData.goal
    };
    
    if (options.includeMetadata) {
      data.metadata = {
        description: levelData.metadata.description,
        author: levelData.metadata.author,
        created_at: levelData.metadata.createdAt,
        updated_at: new Date().toISOString(),
        version: levelData.metadata.version
      };
    }
    
    if (levelData.cameraBounds) {
      data.camera_bounds = levelData.cameraBounds;
    }
    
    return data;
  }
  
  /**
   * 序列化图块
   */
  private serializeTile(tile: TileData): Record<string, unknown> {
    return {
      type: tile.type,
      x: tile.x,
      y: tile.y,
      variant: tile.variant,
      rotation: tile.rotation
    };
  }
  
  /**
   * 序列化谜题
   */
  private serializePuzzle(puzzle: PuzzleData): Record<string, unknown> {
    return {
      id: puzzle.id,
      type: puzzle.type,
      name: puzzle.name,
      position: puzzle.position,
      size: puzzle.size,
      properties: puzzle.properties,
      hint: puzzle.hint,
      required_puzzles: puzzle.requiredPuzzles
    };
  }
  
  /**
   * 清理名称（用于TSCN）
   */
  private sanitizeName(name: string): string {
    return name.replace(/[^a-zA-Z0-9_]/g, '_');
  }
}