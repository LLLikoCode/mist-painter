# 迷雾绘者 - 谜题编辑器

## 概述

这是一个基于Web的可视化谜题编辑器，用于设计和调试《迷雾绘者》游戏的关卡。编辑器支持地图编辑、谜题配置、迷雾区域绘制，并能导出游戏可读取的关卡数据格式。

## 功能特性

- 🎨 **地图可视化编辑**：放置地形、装饰物
- 🧩 **谜题元素配置**：设置起点、终点、收集物位置
- 🌫️ **迷雾区域绘制**：可视化编辑迷雾覆盖区域
- 📤 **关卡数据导出**：生成游戏可读取的JSON格式
- 🎮 **实时预览**：在编辑器中预览关卡效果

## 技术栈

- TypeScript 5.x
- Phaser 3.70+
- HTML5 Canvas
- 原生ES Modules

## 快速开始

```bash
# 进入编辑器目录
cd tools/level-editor

# 安装依赖
npm install

# 启动开发服务器
npm run dev

# 构建生产版本
npm run build
```

## 使用说明

1. 打开编辑器后，选择"新建关卡"或"打开现有关卡"
2. 使用左侧工具栏选择编辑模式（地形/谜题/迷雾）
3. 在画布上点击放置元素
4. 配置右侧属性面板中的参数
5. 点击"导出"生成关卡JSON文件

## 文件结构

```
level-editor/
├── src/
│   ├── main.ts              # 入口文件
│   ├── editor/
│   │   ├── LevelEditor.ts   # 主编辑器类
│   │   ├── MapEditor.ts     # 地图编辑模块
│   │   ├── PuzzleEditor.ts  # 谜题编辑模块
│   │   └── MistEditor.ts    # 迷雾编辑模块
│   ├── ui/
│   │   ├── Toolbar.ts       # 工具栏
│   │   ├── PropertyPanel.ts # 属性面板
│   │   └── Canvas.ts        # 画布管理
│   ├── export/
│   │   └── LevelExporter.ts # 关卡导出器
│   └── types/
│       └── index.ts         # 类型定义
├── assets/                  # 编辑器资源
├── examples/               # 示例关卡
└── index.html
```

## 关卡数据格式

编辑器导出的关卡数据与游戏系统完全兼容，格式如下：

```json
{
  "level_id": "level_01",
  "level_name": "第一关",
  "grid_size": { "width": 40, "height": 22 },
  "tile_size": 32,
  "layers": {
    "floor": [...],
    "walls": [...],
    "decorations": [...]
  },
  "puzzles": [...],
  "mist_zones": [...],
  "spawn_point": { "x": 100, "y": 360 },
  "goal": { "x": 1100, "y": 360 }
}
```
