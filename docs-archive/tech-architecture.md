# 迷雾绘者 (Mist Painter) - 技术架构设计文档

> **版本**: v1.0  
> **创建时间**: 2026-03-20  
> **最后更新**: 2026-03-20  
> **文档类型**: 技术架构设计  
> **任务ID**: TASK-013

---

## 目录

1. [技术选型](#1-技术选型)
2. [项目结构规划](#2-项目结构规划)
3. [核心系统架构](#3-核心系统架构)
4. [模块划分](#4-模块划分)
5. [数据流设计](#5-数据流设计)
6. [性能优化策略](#6-性能优化策略)
7. [开发工作流](#7-开发工作流)
8. [附录](#8-附录)

---

## 1. 技术选型

### 1.1 游戏引擎: Godot 4.x

**选择理由**:

| 维度 | Godot 4.x 优势 |
|------|---------------|
| **开源免费** | MIT许可证，无商业授权费用 |
| **轻量高效** | 引擎本体<100MB，启动迅速 |
| **2D优先** | 原生2D支持，非3D引擎的2D兼容模式 |
| **GDScript** | Python风格，学习曲线平缓 |
| **节点系统** | 直观的场景树结构，适合组件化设计 |
| **跨平台** | Windows/Mac/Linux/Web/移动端全支持 |
| **美术风格适配** | 优秀的2D渲染管线，支持自定义着色器 |

**版本选择**: Godot 4.2+ (Stable)

### 1.2 编程语言: GDScript

**选择理由**:
1. 与引擎深度集成，无需额外编译
2. 热重载支持，开发迭代快
3. 静态类型支持（4.x版本）
4. 团队学习成本低

### 1.3 版本控制: Git + GitHub/GitLab

**分支策略**: Git Flow 简化版
```
main → develop → feature/*
```

**提交规范**: `<type>(<scope>): <subject>`

### 1.4 依赖管理

- Godot内置资源系统
- addons/目录管理插件

---

## 2. 项目结构规划

### 2.1 目录结构

```
mist-painter/
├── project.godot              # 项目配置
├── icon.svg                   # 项目图标
├── .git/                      # Git版本控制
├── .github/                   # GitHub配置
├── docs/                      # 文档目录
├── src/                       # 源代码
│   ├── autoload/              # 自动加载单例
│   ├── core/                  # 核心系统
│   ├── gameplay/              # 游戏逻辑
│   ├── ui/                    # UI系统
│   ├── audio/                 # 音频系统
│   ├── save/                  # 存档系统
│   └── utils/                 # 工具模块
├── assets/                    # 资源目录
├── scenes/                    # 场景文件
├── tests/                     # 测试目录
├── addons/                    # 插件目录
├── build/                     # 构建输出
└── tools/                     # 开发工具
```

### 2.2 场景组织方式

**场景树结构**:
```
Main
├── Managers (GameManager, SceneManager, AudioManager, SaveManager)
├── World (Background, Map, Entities, Foreground, Lighting)
├── UI (CanvasLayer: HUD, Menus, Dialogs)
└── Transitions (CanvasLayer: ScreenTransition)
```

### 2.3 资源管理策略

- 2D像素资源：Filter: Nearest
- 预加载小资源，异步加载大资源

---

## 3. 核心系统架构

### 3.1 游戏状态管理 (GameManager)

```gdscript
# src/autoload/game_manager.gd
extends Node

enum GameState { BOOTSTRAP, MAIN_MENU, LOADING, GAMEPLAY, PAUSED, GAME_OVER }
var current_state: GameState = GameState.BOOTSTRAP
signal state_changed(new_state: GameState, old_state: GameState)

func change_state(new_state: GameState) -> void:
    if current_state == new_state: return
    var old = current_state
    current_state = new_state
    state_changed.emit(new_state, old)
```

### 3.2 场景管理系统 (SceneManager)

```gdscript
# src/core/scene_manager.gd
extends Node

signal scene_loaded(scene_name: String)
signal transition_finished

var current_scene: Node = null

func change_scene(path: String, transition: bool = true) -> void:
    if transition: await _play_transition_out()
    _unload_current_scene()
    await _load_scene(path)
    if transition: await _play_transition_in()
    scene_loaded.emit(path)
```

### 3.3 事件系统 (EventBus)

```gdscript
# src/autoload/event_bus.gd
extends Node

# 游戏事件
signal game_started; signal game_paused; signal game_resumed
# 玩家事件
signal player_moved(pos: Vector2); signal player_interacted(target: Node)
# 地图事件
signal map_explored(pos: Vector2, radius: float); signal fog_updated(data: Dictionary)
# 谜题事件
signal puzzle_started(id: String); signal puzzle_solved(id: String)
# UI事件
signal ui_opened(name: String); signal dialog_requested(text: String, speaker: String)
# 存档事件
signal game_saved(slot: int); signal game_loaded(slot: int)
```

### 3.4 配置管理系统 (ConfigManager)

```gdscript
# src/core/config_manager.gd
extends Node
const CONFIG_PATH = "user://config.cfg"
var config: ConfigFile = ConfigFile.new()

func _ready(): load_config()
func load_config():
    if FileAccess.file_exists(CONFIG_PATH): config.load(CONFIG_PATH)
    else: _create_default_config()
func save_config(): config.save(CONFIG_PATH)
func get_value(section: String, key: String, default = null): return config.get_value(section, key, default)
func set_value(section: String, key: String, value): config.set_value(section, key, value); save_config()
```

---

## 4. 模块划分

### 4.1 核心模块 (Core)

| 文件 | 职责 |
|------|------|
| state_machine.gd | 通用状态机实现 |
| scene_manager.gd | 场景切换管理 |
| config_manager.gd | 配置读写管理 |
| resource_manager.gd | 资源加载/缓存 |

### 4.2 游戏逻辑模块 (Gameplay)

| 目录 | 内容 |
|------|------|
| player/ | 玩家控制器、移动、交互 |
| map/ | 地图生成、瓦片管理 |
| puzzle/ | 谜题逻辑、验证系统 |
| inventory/ | 背包系统、物品管理 |
| fog/ | 迷雾系统、视野计算 |

### 4.3 UI模块 (UI)

| 目录 | 内容 |
|------|------|
| components/ | 可复用UI组件（按钮、滑块等） |
| screens/ | 完整界面（主菜单、设置等） |
| hud/ | HUD元素（状态栏、小地图等） |
| themes/ | UI主题资源 |

### 4.4 音频模块 (Audio)

```gdscript
# src/audio/audio_manager.gd
extends Node

@export var music_bus: String = "Music"
@export var sfx_bus: String = "SFX"

func play_music(track: AudioStream, fade_duration: float = 1.0):
func play_sfx(sound: AudioStream, pitch_variation: float = 0.0):
func set_bus_volume(bus: String, volume: float):
```

### 4.5 存档模块 (Save)

```gdscript
# src/save/save_system.gd
extends Node
const SAVE_DIR = "user://saves/"
const MAX_SLOTS = 3

func save_game(slot: int, data: Dictionary) -> bool:
func load_game(slot: int) -> Dictionary:
func delete_save(slot: int) -> bool:
func get_save_info(slot: int) -> Dictionary:
```

### 4.6 工具模块 (Utils)

| 文件 | 职责 |
|------|------|
| helpers.gd | 通用辅助函数 |
| constants.gd | 游戏常量定义 |
| logger.gd | 日志系统 |

---

## 5. 数据流设计

### 5.1 组件间通信机制

```
┌─────────────┐     EventBus      ┌─────────────┐
│   Player    │ ←──────────────→ │   Map       │
└─────────────┘                  └─────────────┘
       ↓                              ↓
       └────────→ EventBus ←──────────┘
                     ↓
              ┌─────────────┐
              │   UI/HUD    │
              └─────────────┘
```

**通信方式**:
1. **信号(Signals)**: 直接父子节点通信
2. **EventBus**: 全局事件，解耦系统
3. **依赖注入**: 通过初始化传递引用

### 5.2 数据持久化策略

**存档数据结构**:
```gdscript
# SaveGameData
{
    "version": "1.0.0",
    "timestamp": "2026-03-20T18:00:00",
    "play_time": 3600,
    "player": {
        "position": {"x": 100, "y": 200},
        "inventory": [...],
        "stats": {...}
    },
    "map": {
        "explored_tiles": [...],
        "fog_data": [...]
    },
    "puzzles": {
        "completed": [...],
        "progress": {...}
    },
    "settings": {
        "difficulty": "normal"
    }
}
```

**存储格式**: JSON（可读性好）+ 可选压缩

### 5.3 配置数据管理

**分层配置**:
```
默认配置 → 用户配置 → 运行时覆盖
    ↓           ↓
  代码内嵌    user://config.cfg
```

---

## 6. 性能优化策略

### 6.1 资源加载优化

| 策略 | 实现方式 |
|------|----------|
| 预加载 | 使用preload()加载关键资源 |
| 异步加载 | ResourceLoader.load_threaded_request() |
| 资源池 | 复用频繁创建/销毁的对象 |
| 懒加载 | 按需加载非关键资源 |

### 6.2 内存管理

| 策略 | 说明 |
|------|------|
| 对象池 | 敌人、特效等使用对象池 |
| 纹理压缩 | 使用适当格式压缩纹理 |
| 资源释放 | 及时释放不再使用的资源 |
| 引用计数 | 注意循环引用问题 |

### 6.3 渲染优化

| 策略 | 实现 |
|------|------|
| 合批渲染 | 相同材质的节点合并绘制 |
| 视锥剔除 | 只渲染视野内的对象 |
| LOD系统 | 远距离使用低精度资源 |
| 动态光照限制 | 限制同时活跃的光源数量 |

---

## 7. 开发工作流

### 7.1 Git工作流

```bash
# 开始新功能
git checkout develop
git pull origin develop
git checkout -b feature/player-movement

# 开发完成后
git add .
git commit -m "feat(player): 实现玩家移动系统"
git push origin feature/player-movement

# 创建PR合并到develop
```

### 7.2 项目初始化脚本

```bash
#!/bin/bash
# tools/scripts/init_project.sh

echo "初始化迷雾绘者项目..."

# 创建目录结构
mkdir -p src/{autoload,core,gameplay/{player,map,puzzle,inventory,fog},ui/{components,screens,hud,themes},audio,save,utils}
mkdir -p assets/{graphics/{characters,environment,ui,effects,shaders},audio/{bgm,sfx,ambient},fonts,translations}
mkdir -p scenes/{managers,levels,ui,transitions}
mkdir -p tests/{unit,integration}
mkdir -p tools/{scripts,templates}

echo "✓ 目录结构创建完成"
```

### 7.3 CI/CD配置

```yaml
# .github/workflows/godot-ci.yml
name: Godot CI
on: [push, pull_request]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Build
        uses:abarichello/godot-ci@master
        with:
          export: linux
```

---

## 8. 附录

### 8.1 命名规范

| 类型 | 规范 | 示例 |
|------|------|------|
| 文件/目录 | snake_case | `player_controller.gd` |
| 类名 | PascalCase | `PlayerController` |
| 变量 | snake_case | `player_speed` |
| 常量 | UPPER_SNAKE_CASE | `MAX_HEALTH` |
| 信号 | snake_case | `health_changed` |
| 节点 | PascalCase | `PlayerSprite` |

### 8.2 Godot项目配置

```ini
# project.godot 关键配置
[application]
config/name="迷雾绘者"
config/description="冒险解谜游戏"
run/main_scene="res://scenes/bootstrap.tscn"
config/features=PackedStringArray("4.2", "Mobile")

[autoload]
GameManager="*res://src/autoload/game_manager.gd"
EventBus="*res://src/autoload/event_bus.gd"
AudioManager="*res://src/autoload/audio_manager.gd"
SaveManager="*res://src/autoload/save_manager.gd"
ConfigManager="*res://src/core/config_manager.gd"

[display]
window/size/viewport_width=1920
window/size/viewport_height=1080
window/stretch/mode="canvas_items"
window/stretch/aspect="expand"

[rendering]
textures/canvas_textures/default_texture_filter=0  # Nearest
renderer/rendering_method="mobile"
```

### 8.3 参考资料

- [Godot 4 文档](https://docs.godotengine.org/)
- [GDScript 风格指南](https://docs.godotengine.org/tutorials/scripting/gdscript/gdscript_styleguide.html)
- [Godot 最佳实践](https://docs.godotengine.org/tutorials/best_practices/)

---

*文档结束*