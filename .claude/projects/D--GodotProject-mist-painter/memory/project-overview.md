---
name: project-overview
description: 迷雾绘者项目概况和文档结构
type: project
---

# 迷雾绘者 (Mist Painter) 项目概况

## 项目类型
冒险解谜游戏，核心玩法是迷雾绘制和地图记忆

## 技术栈
- 引擎: Godot 4.x
- 语言: GDScript
- 平台: PC, Web

## 当前状态
- 基础系统已实现: GameController, PlayerController, MistPaintingSystem, PuzzleController
- 玩家资源系统已完成: HP/SP/墨水/体力
- HUD界面已实现
- 迷雾绘制功能已修复

## 文档结构
```
docs/
├── GAME_DESIGN.md              # 主设计文档 (v2.0)
├── design/
│   ├── mist-painting-system.md # 迷雾绘制系统
│   ├── maze-generation.md      # 迷宫生成系统
│   ├── player-stats.md         # 玩家资源系统
│   ├── map-memory-system.md    # 地图记忆系统
│   ├── light-system.md         # 光源系统
│   ├── mental-state-system.md  # 心理状态系统
│   ├── class-system.md         # 职业系统
│   ├── difficulty-system.md    # 难度系统
│   ├── expansion-features.md   # 扩展功能
│   ├── progression-system.md   # 进度系统
│   ├── game-loop-design.md     # 游戏循环
│   ├── tech-architecture.md    # 技术架构
│   ├── ui-system-design.md     # UI系统
│   ├── audio-system.md         # 音频系统
│   ├── level-transition-design.md # 关卡过渡
│   ├── achievement-design.md   # 成就系统
│   ├── art/                    # 美术文档
│   └── systems/                # 系统文档
│       └── save-system.md
├── performance/                # 性能优化
│   ├── mist-optimization.md
│   └── performance-test-data.md
└── maze-game-reference/        # 设计参考文档
    ├── 01-core-gameplay.md
    ├── 02-map-drawing.md
    ├── 03-maze-generation.md
    ├── 04-game-balance.md
    ├── 05-art-style.md
    ├── 06-expansion.md
    └── 07-technical-spec.md
```

## 核心设计要点
1. 迷雾绘制是核心机制，消耗墨水
2. 记忆会衰退，需要回访确认
3. 工具有限制（纸张、墨水、光源）
4. 深层迷宫是动态的

**Why:** 保持项目信息一致，避免重复解释
**How to apply:** 每次开始工作时参考此文档结构