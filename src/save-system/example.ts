/**
 * 迷雾绘者 - 存档系统使用示例
 * Save System Usage Examples
 */

import {
  createSaveManager,
  createIndexedDBSaveManager,
  SaveManager,
  SaveData,
  SaveError,
  SaveErrorType,
  SaveSlotInfo,
  CellType,
  ToolType,
  Direction,
  PaperType,
} from './index';

// ==================== 示例 1: 基础使用 ====================

async function basicUsageExample() {
  console.log('=== 基础使用示例 ===');

  // 创建存档管理器
  const saveManager = createSaveManager({
    maxManualSlots: 5,
    maxAutoSaves: 3,
    enableEncryption: true,
    autoSaveInterval: 5,
  });

  // 模拟游戏状态
  const gameState: SaveData = {
    version: '1.0.0',
    gameVersion: '1.0.0',
    timestamp: Date.now(),
    playTime: 3600, // 1小时
    saveType: 'manual' as const,
    player: {
      id: 'player_001',
      name: '探险者',
      level: 5,
      exp: 1250,
      position: { x: 10, y: 15 },
      layer: 2,
      direction: Direction.DOWN,
      stamina: 80,
      maxStamina: 100,
      equippedTool: {
        type: ToolType.PENCIL,
        name: '探险者铅笔',
        durability: 75,
        maxDurability: 100,
        accuracy: 0.85,
        speed: 1.0,
        erasable: true,
      },
      lightSource: {
        id: 'torch_001',
        name: '火把',
        radiusBonus: 2,
        duration: 300,
        maxDuration: 600,
      },
      inventory: {
        items: [
          { id: 'potion_001', name: '体力药水', type: 'consumable', quantity: 3 },
          { id: 'map_001', name: '地图碎片', type: 'key', quantity: 1 },
        ],
        maxSlots: 20,
      },
      drawnMaps: {
        1: {
          layer: 1,
          cells: {
            '5,5': {
              x: 5, y: 5,
              drawnType: CellType.PATH,
              accuracy: 0.9,
              timestamp: Date.now(),
              toolUsed: ToolType.PENCIL,
            },
          },
          lastVisited: { '5,5': Date.now() },
          paperType: PaperType.NORMAL,
          marks: [],
        },
      },
      unlockedTools: ['pencil', 'quill'],
      discoveredSecrets: ['secret_room_001'],
    },
    world: {
      seed: 'maze_seed_12345',
      currentLayer: 2,
      layers: {
        1: {
          layer: 1,
          maze: {
            width: 31,
            height: 31,
            cells: [], // 实际游戏中这里会有完整迷宫数据
            rooms: [],
            entrance: { x: 1, y: 1 },
            exit: { x: 29, y: 29 },
          },
          visitedCells: ['1,1', '2,1', '3,1'],
          activatedTriggers: ['trigger_001'],
          collectedItems: ['item_001'],
          defeatedEnemies: [],
          modifiedCells: {},
        },
      },
      globalState: {
        flags: { tutorial_completed: true },
        variables: { puzzle_progress: 50 },
        puzzlesSolved: ['puzzle_001'],
        eventsTriggered: ['event_001'],
      },
    },
    settings: {
      masterVolume: 0.8,
      musicVolume: 0.6,
      sfxVolume: 0.9,
      fullscreen: false,
      showFPS: false,
      minimapEnabled: true,
      autoSave: true,
      autoSaveInterval: 5,
      tutorialEnabled: true,
      colorblindMode: false,
      highContrast: false,
      screenShake: true,
    },
    statistics: {
      totalPlayTime: 3600,
      totalDeaths: 2,
      totalSteps: 1250,
      mapsDrawn: 15,
      puzzlesSolved: 3,
      secretsFound: 1,
      itemsCollected: 12,
      layersExplored: 2,
      achievements: ['first_step', 'map_maker'],
      achievementProgress: { explorer: 50 },
    },
  };

  try {
    // 保存到槽位 1
    await saveManager.save(1, gameState);
    console.log('✓ 游戏已保存到槽位 1');

    // 加载存档
    const loadedData = await saveManager.load(1);
    console.log('✓ 从槽位 1 加载游戏');
    console.log(`  玩家等级: ${loadedData.player.level}`);
    console.log(`  当前层数: ${loadedData.world.currentLayer}`);

    // 获取槽位信息
    const slots = await saveManager.getSlotInfos();
    console.log('\n存档槽位信息:');
    slots.forEach((slot: SaveSlotInfo) => {
      if (slot.exists) {
        const date = slot.timestamp ? new Date(slot.timestamp).toLocaleString() : '未知';
        console.log(`  槽位 ${slot.slotId}: 等级 ${slot.playerLevel}, 第 ${slot.currentLayer}层 (${date})`);
      } else {
        console.log(`  槽位 ${slot.slotId}: [空]`);
      }
    });
  } catch (e) {
    console.error('错误:', e);
  }
}

// ==================== 示例 2: 自动存档 ====================

async function autoSaveExample() {
  console.log('\n=== 自动存档示例 ===');

  const saveManager = createSaveManager({
    maxAutoSaves: 3,
    autoSaveInterval: 1, // 1分钟
  });

  // 模拟游戏状态
  let gameState: SaveData = createMockSaveData();

  // 启动自动存档
  saveManager.startAutoSaveTimer(async () => {
    console.log('  [自动存档触发]');
    return gameState;
  });

  console.log('✓ 自动存档已启动（每1分钟）');

  // 模拟手动触发检查点
  await saveManager.triggerCheckpoint(gameState);
  console.log('✓ 检查点存档已创建');

  // 获取最新自动存档
  const latestAutoSave = await saveManager.getLatestAutoSave();
  if (latestAutoSave) {
    console.log(`✓ 最新自动存档时间: ${new Date(latestAutoSave.timestamp).toLocaleString()}`);
  }

  // 停止自动存档
  saveManager.stopAutoSaveTimer();
  console.log('✓ 自动存档已停止');
}

// ==================== 示例 3: 导入/导出 ====================

async function importExportExample() {
  console.log('\n=== 导入/导出示例 ===');

  const saveManager = createSaveManager();
  const gameState = createMockSaveData();

  // 先保存一个存档
  await saveManager.save(1, gameState);

  // 导出存档
  const exportedData = await saveManager.exportSave(1);
  console.log('✓ 存档已导出');
  console.log(`  导出数据长度: ${exportedData.length} 字符`);

  // 模拟：将导出的数据保存到某处
  // localStorage.setItem('backup_save', exportedData);

  // 删除原存档
  await saveManager.delete(1);
  console.log('✓ 原存档已删除');

  // 导入存档
  const importedSlotId = await saveManager.importSave(exportedData);
  console.log(`✓ 存档已导入到槽位 ${importedSlotId}`);

  // 验证导入
  const loaded = await saveManager.load(importedSlotId);
  console.log(`  验证: 玩家等级 ${loaded.player.level}`);
}

// ==================== 示例 4: 错误处理 ====================

async function errorHandlingExample() {
  console.log('\n=== 错误处理示例 ===');

  const saveManager = createSaveManager();

  // 尝试加载不存在的存档
  try {
    await saveManager.load(99);
  } catch (e) {
    if (e instanceof SaveError) {
      console.log(`✓ 捕获到错误: ${e.type}`);
      console.log(`  消息: ${e.message}`);
    }
  }

  // 尝试保存到无效槽位
  try {
    await saveManager.save(999, createMockSaveData());
  } catch (e) {
    if (e instanceof SaveError) {
      console.log(`✓ 捕获到错误: ${e.type}`);
      console.log(`  消息: ${e.message}`);
    }
  }

  // 检查存档是否存在
  const exists = await saveManager.exists(1);
  console.log(`✓ 槽位 1 存档存在: ${exists}`);
}

// ==================== 示例 5: 存储使用情况 ====================

async function storageUsageExample() {
  console.log('\n=== 存储使用情况示例 ===');

  const saveManager = createSaveManager();

  // 保存一些数据
  for (let i = 1; i <= 3; i++) {
    await saveManager.save(i, createMockSaveData());
  }

  // 获取存储使用情况
  const usage = await saveManager.getStorageUsage();
  console.log('存储使用情况:');
  console.log(`  已使用: ${formatBytes(usage.used)}`);
  if (usage.quota) {
    console.log(`  总配额: ${formatBytes(usage.quota)}`);
    console.log(`  使用率: ${((usage.used / usage.quota) * 100).toFixed(2)}%`);
  } else {
    console.log('  总配额: 无限制');
  }
}

// ==================== 辅助函数 ====================

function createMockSaveData(): SaveData {
  return {
    version: '1.0.0',
    gameVersion: '1.0.0',
    timestamp: Date.now(),
    playTime: 0,
    saveType: 'manual' as const,
    player: {
      id: 'player_001',
      name: '探险者',
      level: 1,
      exp: 0,
      position: { x: 1, y: 1 },
      layer: 1,
      direction: Direction.DOWN,
      stamina: 100,
      maxStamina: 100,
      equippedTool: null,
      lightSource: null,
