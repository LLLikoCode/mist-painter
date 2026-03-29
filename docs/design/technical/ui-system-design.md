# 迷雾绘者 (Mist Painter) - UI系统设计文档

> **版本**: v1.0  
> **创建时间**: 2026-03-20  
> **最后更新**: 2026-03-20  
> **文档类型**: 技术设计文档

---

## 目录

1. [概述](#1-概述)
2. [UI架构设计](#2-ui架构设计)
3. [核心界面设计](#3-核心界面设计)
4. [解谜相关UI](#4-解谜相关ui)
5. [存档相关UI](#5-存档相关ui)
6. [技术实现细节](#6-技术实现细节)
7. [主题资源定义](#7-主题资源定义)
8. [动画系统](#8-动画系统)
9. [文件结构](#9-文件结构)

---

## 1. 概述

### 1.1 设计目标

为"迷雾绘者"冒险解谜游戏设计一套完整的UI系统，遵循以下核心原则：

- **沉浸感**: UI风格与游戏美术风格（手绘水彩+羊皮纸质感）高度统一
- **易用性**: 操作直观，反馈明确，学习成本低
- **响应式**: 适配多种屏幕尺寸和分辨率
- **模块化**: 组件可复用，易于维护和扩展
- **性能**: 优化渲染性能，确保流畅体验

### 1.2 技术选型

- **引擎**: Godot 4.x
- **UI系统**: Control节点系统
- **脚本语言**: GDScript
- **动画**: Godot内置动画系统 + Tween
- **主题**: Theme资源文件 (.tres)

---

## 2. UI架构设计

### 2.1 UI层级结构

```
CanvasLayer (根节点)
├── UILayer (UI管理器)
│   ├── SceneLayer (场景层 - z_index: 0)
│   │   └── MainMenu, GameHUD, PauseMenu, Settings, etc.
│   ├── HUDLayer (HUD层 - z_index: 10)
│   │   └── HealthBar, Inventory, Minimap, QuestTracker
│   ├── PopupLayer (弹窗层 - z_index: 20)
│   │   ├── DialogBox, Notification, Toast
│   │   └── PuzzleInterface, ItemInspect, SaveSlotSelect
│   ├── OverlayLayer (遮罩层 - z_index: 30)
│   │   └── FadeOverlay, LoadingScreen, TransitionEffect
│   └── DebugLayer (调试层 - z_index: 100)
│       └── FPSCounter, DebugInfo
```

### 2.2 UI管理器设计

#### UIManager (单例模式)

```gdscript
class_name UIManager
extends Node

# 单例实例
static var instance: UIManager

# UI层级引用
@onready var scene_layer: CanvasLayer
@onready var hud_layer: CanvasLayer
@onready var popup_layer: CanvasLayer
@onready var overlay_layer: CanvasLayer

# 当前UI状态
enum UIState { MAIN_MENU, GAMEPLAY, PAUSED, SETTINGS, DIALOG, PUZZLE, SAVE_LOAD }
var current_state: UIState = UIState.MAIN_MENU

# 历史栈（用于返回导航）
var navigation_stack: Array[UIState] = []

# 信号
signal state_changed(old_state: UIState, new_state: UIState)
signal screen_opened(screen_name: String)
signal screen_closed(screen_name: String)
```

#### 核心功能

| 功能 | 方法 | 说明 |
|------|------|------|
| 切换场景 | `change_screen(screen_name: String, params: Dictionary = {})` | 切换主界面 |
| 打开弹窗 | `open_popup(popup_name: String, params: Dictionary = {})` | 打开模态弹窗 |
| 关闭弹窗 | `close_popup(popup_name: String = "")` | 关闭指定或最上层弹窗 |
| 显示HUD | `show_hud()` | 显示游戏HUD |
| 隐藏HUD | `hide_hud()` | 隐藏游戏HUD |
| 返回上级 | `go_back()` | 返回上一界面 |
| 获取状态 | `get_current_state()` | 获取当前UI状态 |

### 2.3 屏幕适配方案

#### 响应式布局策略

```gdscript
# 基础分辨率
const BASE_RESOLUTION = Vector2(1920, 1080)
const MIN_RESOLUTION = Vector2(1280, 720)

# 锚点配置
enum AnchorPreset {
    TOP_LEFT, TOP_CENTER, TOP_RIGHT,
    CENTER_LEFT, CENTER, CENTER_RIGHT,
    BOTTOM_LEFT, BOTTOM_CENTER, BOTTOM_RIGHT,
    FULL_RECT, HORIZONTAL_WIDE, VERTICAL_WIDE
}

# 安全区域（避免UI被遮挡）
var safe_area_margin: Vector4 = Vector4(20, 20, 20, 20)  # 左、上、右、下
```

#### 尺寸缩放策略

| 元素类型 | 缩放策略 | 说明 |
|----------|----------|------|
| 文字 | 固定字号 + 最小限制 | 确保可读性 |
| 按钮 | 相对尺寸 + 最小尺寸 | 保证点击区域 |
| 图标 | 固定尺寸 | 保持清晰度 |
| 面板 | 百分比 + 最大限制 | 适应不同屏幕 |
| 间距 | 相对值 | 保持比例 |

---

## 3. 核心界面设计

### 3.1 主菜单界面 (MainMenu)

#### 布局结构

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│                    [游戏Logo/标题]                          │
│                      迷雾绘者                               │
│                    Mist Painter                             │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                                                     │   │
│  │              [开始游戏]  Start Game                  │   │
│  │                                                     │   │
│  │              [继续游戏]  Continue                    │   │  ← 无存档时禁用
│  │                                                     │   │
│  │              [设置]      Settings                   │   │
│  │                                                     │   │
│  │              [退出]      Exit                       │   │
│  │                                                     │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│                    [版本号] v1.0.0                          │
└─────────────────────────────────────────────────────────────┘
```

#### 交互设计

| 按钮 | 功能 | 快捷键 |
|------|------|--------|
| 开始游戏 | 新建游戏，进入开场/教程 | Enter/Space |
| 继续游戏 | 加载最近存档 | C |
| 设置 | 打开设置界面 | S |
| 退出 | 退出游戏 | Esc |

#### 视觉风格

- **背景**: 动态羊皮纸纹理 + 微弱粒子效果
- **Logo**: 手写风格字体，墨水晕染效果
- **按钮**: 羊皮纸质感，手绘边框，悬停高亮
- **装饰**: 四角复古花纹

### 3.2 游戏内HUD (GameHUD)

#### 布局结构

```
┌─────────────────────────────────────────────────────────────┐
│ [生命值] ████████████░░░░  80%      │  [任务] 寻找古老地图  │
│                                     │  [进度] 1/3          │
│ [体力]  ████████░░░░░░░░  60%       │                      │
│                                     │  ┌──────────────┐    │
│ [光源]  🔥 剩余 5:30                │  │   小地图     │    │
│                                     │  │   [区域]     │    │
│                                     │  └──────────────┘    │
├─────────────────────────────────────────────────────────────┤
│ [道具栏]                                                    │
│ [1] [2] [3] [4] [5]                                         │
│  🔦  🗝️  🗺️  💊  📜                                         │
│                                                             │
│ [工具] ✏️  [耐久] ████░░░░░   [图层] 2/4   [纸张] 3/5      │
└─────────────────────────────────────────────────────────────┘
```

#### HUD组件清单

| 组件 | 节点类型 | 位置 | 功能 |
|------|----------|------|------|
| HealthBar | TextureProgressBar | 左上角 | 生命值显示 |
| StaminaBar | TextureProgressBar | 左上(下) | 体力值显示 |
| LightTimer | Label + TextureRect | 左上(下) | 光源剩余时间 |
| QuestTracker | Panel + Labels | 右上角 | 当前任务显示 |
| Minimap | SubViewportContainer | 右上(下) | 小地图 |
| InventoryBar | HBoxContainer | 底部 | 道具栏 |
| ToolInfo | HBoxContainer | 底部(左) | 当前工具信息 |
| ResourceInfo | HBoxContainer | 底部(右) | 资源数量 |

### 3.3 暂停菜单 (PauseMenu)

#### 布局结构

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│                      [暂停]  PAUSED                         │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                                                     │   │
│  │              [继续游戏]  Resume                     │   │
│  │                                                     │   │
│  │              [设置]      Settings                   │   │
│  │                                                     │   │
│  │              [返回主菜单] Main Menu                 │   │
│  │                                                     │   │
│  │              [退出游戏]  Exit Game                  │   │
│  │                                                     │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

#### 交互设计

- **呼出**: Esc键或游戏手柄Start键
- **背景**: 半透明遮罩 + 模糊效果
- **时间**: 暂停游戏时间（可选）

### 3.4 设置界面 (Settings)

#### 布局结构

```
┌─────────────────────────────────────────────────────────────┐
│ [设置]  SETTINGS                              [X] 关闭      │
├──────────┬──────────────────────────────────────────────────┤
│          │                                                  │
│ [通用]   │  [音量设置]                                       │
│ [音频] ◄─┤  ┌────────────────────────────────────────────┐  │
│ [画质]   │  │  主音量    [████████░░] 80%              │  │
│ [控制]   │  │  背景音乐  [████████░░] 80%              │  │
│ [语言]   │  │  音效      [██████░░░░] 60%              │  │
│          │  │  语音      [████████░░] 80%              │  │
│          │  └────────────────────────────────────────────┘  │
│          │                                                  │
│          │  [应用]  [取消]  [恢复默认]                       │
│          │                                                  │
└──────────┴──────────────────────────────────────────────────┘
```

#### 设置分类

| 分类 | 设置项 | 控件类型 |
|------|--------|----------|
| 通用 | 全屏/窗口、分辨率、垂直同步 | 开关、下拉框 |
| 音频 | 主音量、BGM、SFX、语音 | 滑动条 |
| 画质 | 画质等级、阴影、特效、抗锯齿 | 下拉框、开关 |
| 控制 | 键位映射、鼠标灵敏度、震动 | 按键绑定、滑动条 |
| 语言 | 界面语言、字幕、字幕大小 | 下拉框、开关 |

---

## 4. 解谜相关UI

### 4.1 谜题交互界面 (PuzzleInterface)

#### 布局结构

```
┌─────────────────────────────────────────────────────────────┐
│ [谜题名称]  古代机关门                          [?] [X]     │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│                    [谜题交互区域]                           │
│                                                             │
│              ┌─────────────────────────┐                    │
│              │                         │                    │
│              │      [谜题内容]         │                    │
│              │      转盘/拼图/密码     │                    │
│              │                         │                    │
│              └─────────────────────────┘                    │
│                                                             │
│  [提示] 观察墙上的符文，它们似乎对应着...                    │
│                                                             │
│              [重置]  [提交]  [退出]                         │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

#### 组件说明

| 组件 | 说明 |
|------|------|
| 谜题区域 | 根据谜题类型动态加载不同组件 |
| 提示文本 | 可展开/收起，提供解谜线索 |
| 重置按钮 | 重置谜题到初始状态 |
| 提交按钮 | 验证答案 |
| 退出按钮 | 关闭谜题界面 |

### 4.2 物品检查界面 (ItemInspect)

#### 布局结构

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│  ┌─────────────────┐    ┌───────────────────────────────┐  │
│  │                 │    │ [物品名称]                    │  │
│  │                 │    │ 古老的青铜钥匙                │  │
│  │   [物品3D       │    │                               │  │
│  │    展示/        │    │ [描述]                        │  │
│  │    大图]        │    │ 一把锈迹斑斑的青铜钥匙，上面  │  │
│  │                 │    │ 刻着奇怪的符号。似乎能打开    │  │
│  │                 │    │ 某个古老的门...               │  │
│  │                 │    │                               │  │
│  │                 │    │ [属性]                        │  │
│  │                 │    │ • 类型: 关键道具              │  │
│  │                 │    │ • 重量: 0.1kg                 │  │
│  │                 │    │ • 耐久: --                    │  │
│  └─────────────────┘    └───────────────────────────────┘  │
│                                                             │
│                      [关闭]                                 │
└─────────────────────────────────────────────────────────────┘
```

### 4.3 线索收集提示 (ClueNotification)

#### 设计

```
┌─────────────────────────────────────┐
│  📜 新线索获得                      │
│  ━━━━━━━━━━━━━━━━━━━━━━━            │
│  "墙上的符文似乎暗示着..."          │
│                                     │
│  [查看详情]  [忽略]                 │
└─────────────────────────────────────┘
```

- **显示位置**: 屏幕右上角滑入
- **自动消失**: 5秒后自动淡出
- **交互**: 点击查看详情，点击其他地方忽略

### 4.4 解谜成功/失败反馈

#### 成功反馈

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│                                                             │
│              ✨ 解谜成功 ✨                                 │
│                                                             │
│           ━━━━━━━━━━━━━━━━━━━━━━━━                         │
│                                                             │
│              机关门缓缓打开...                              │
│                                                             │
│              [获得物品: 古老卷轴]                           │
│                                                             │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

#### 失败反馈

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│                                                             │
│              ✗ 解谜失败                                     │
│                                                             │
│           ━━━━━━━━━━━━━━━━━━━━━━━━                         │
│                                                             │
│              机关没有反应，似乎哪里不对...                  │
│                                                             │
│              [剩余尝试: 2]                                  │
│                                                             │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 5. 存档相关UI

### 5.1 存档槽位选择界面 (SaveSlotSelect)

#### 布局结构

```
┌─────────────────────────────────────────────────────────────┐
│ [选择存档]  Select Save Slot                  [X] 关闭      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  [存档 1]                                           │   │
│  │  ┌─────┐  第3层 - 古代回廊                          │   │
│  │  │ 📷  │  游戏时间: 2:34:15                         │   │
│  │  │ 截图│  存档时间: 2026-03-20 14:30                │   │
│  │  └─────┘  [载入]  [删除]                            │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  [存档 2]  [空槽位]                                 │   │
│  │  ┌─────┐  开始新游戏                                │   │
│  │  │  +  │                                           │   │
│  │  │     │  [新建存档]                                 │   │
│  │  └─────┘                                            │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  [存档 3]  [空槽位]                                 │   │
│  │  ┌─────┐  开始新游戏                                │   │
│  │  │  +  │                                           │   │
│  │  │     │  [新建存档]                                 │   │
│  │  └─────┘                                            │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

#### 功能说明

| 功能 | 说明 |
|------|------|
| 存档预览 | 显示截图、位置、游戏时间、存档时间 |
| 载入存档 | 加载选中的存档 |
| 新建存档 | 在空槽位创建新存档 |
| 删除存档 | 删除选中的存档（需确认） |

### 5.2 存档确认对话框 (SaveConfirmDialog)

```
┌─────────────────────────────────────────┐
│  确认存档                               │
│  ━━━━━━━━━━━━━━━━━━━━━━━                │
│                                         │
│  当前存档将被覆盖:                      │
│                                         │
│  第3层 - 古代回廊                       │
│  游戏时间: 2:34:15                      │
│                                         │
│  是否继续？                             │
│                                         │
│        [取消]  [确认覆盖]               │
└─────────────────────────────────────────┘
```

### 5.3 自动存档提示 (AutoSaveToast)

```
┌──────────────────────────┐
│  💾 自动存档完成         │
└──────────────────────────┘
```

- **显示位置**: 屏幕底部中央
- **显示时长**: 2秒
- **动画**: 滑入 → 停留 → 滑出

---

## 6. 技术实现细节

### 6.1 自定义UI组件

#### PaperButton (羊皮纸按钮)

```gdscript
class_name PaperButton
extends Button

@export var paper_style: int = 0  # 0=浅色, 1=深色, 2=金色
@export var has_decorations: bool = true
@export var animation_speed: float = 0.15

@onready var background: NinePatchRect
@onready var corner_tl: TextureRect
@onready var corner_tr: TextureRect
@onready var corner_bl: TextureRect
@onready var corner_br: TextureRect
@onready var hover_effect: ColorRect

func _ready():
    setup_visuals()
    connect_signals()

func setup_visuals():
    # 设置羊皮纸背景
    # 设置装饰角
    # 设置悬停效果
    pass

func _on_mouse_entered():
    # 播放悬停动画
    var tween = create_tween()
    tween.tween_property(self, "scale", Vector2(1.05, 1.05), animation_speed)
    tween.parallel().tween_property(hover_effect, "modulate:a", 0.3, animation_speed)

func _on_mouse_exited():
    # 播放离开动画
    var tween = create_tween()
    tween.tween_property(self, "scale", Vector2(1.0, 1.0), animation_speed)
    tween.parallel().tween_property(hover_effect, "modulate:a", 0.0, animation_speed)
```

#### PaperSlider (羊皮纸滑动条)

```gdscript
class_name PaperSlider
extends HSlider

@export var track_texture: Texture2D
@export var handle_texture: Texture2D
@export var fill_texture: Texture2D

@onready var track: NinePatchRect
@onready var fill: NinePatchRect
@onready var handle: TextureRect

func _ready():
    setup_visuals()

func _on_value_changed(value: float):
    update_fill()
    update_handle_position()
```

#### PaperDropdown (羊皮纸下拉框)

```gdscript
class_name PaperDropdown
extends OptionButton

@export var paper_style: int = 0
@export var max_visible_items: int = 5

@onready var popup: PopupMenu

func _ready():
    setup_popup()
    connect_signals()

func setup_popup():
    # 自定义下拉菜单样式
    pass
```

### 6.2 屏幕基类

#### BaseScreen

```gdscript
class_name BaseScreen
extends Control

@export var screen_name: String = ""
@export var can_return: bool = true
@export var pause_game: bool = false

var is_open: bool = false
var open_animation: String = "fade_in"
var close_animation: String = "fade_out"

func _ready():
    visible = false
    setup_animations()

func open(params: Dictionary = {}):
    if is_open:
        return
    is_open = true
    visible = true
    
    if pause_game:
        get_tree().paused = true
    
    play_open_animation()
    on_open(params)

func close():
    if not is_open:
        return
    
    play_close_animation()
    await animation_finished
    
    is_open = false
    visible = false
    
    if pause_game:
        get_tree().paused = false
    
    on_close()

func on_open(params: Dictionary):
    # 子类重写
    pass

func on_close():
    # 子类重写
    pass

func play_open_animation():
    # 播放打开动画
    pass

func play_close_animation():
    # 播放关闭动画
    pass
```

---

## 7. 主题资源定义

### 7.1 主题文件结构

```
assets/themes/
├── default_theme.tres          # 默认主题
├── paper_theme.tres            # 羊皮纸主题（主主题）
├── dark_theme.tres             # 深色主题（可选）
└── fonts/
    ├── source_han_serif.ttf    # 思源宋体
    ├── source_han_sans.ttf     # 思源黑体
    ├── cinzel_regular.ttf      # Cinzel
    └── lato_regular.ttf        # Lato
```

### 7.2 主题颜色定义

```gdscript
# paper_theme.tres

# 羊皮纸色系
const COLOR_PAPER_LIGHT = Color("#f5f0e1")
const COLOR_PAPER_MEDIUM = Color("#e8dcc4")
const COLOR_PAPER_DARK = Color("#d4c4a8")
const COLOR_PAPER_AGED = Color("#c9b896")

# 墨水色系
const COLOR_INK_BLACK = Color("#1a1a1a")
const COLOR_INK_DARK = Color("#2d2d2d")
const COLOR_INK_FADED = Color("#5a5a5a")
const COLOR_INK_BROWN = Color("#3d2817")

# 强调色
const COLOR_ACCENT_GOLD = Color("#c9a227")
const COLOR_ACCENT_RED = Color("#8b3a3a")
const COLOR_ACCENT_GREEN = Color("#4a7c59")
const COLOR_ACCENT_BLUE = Color("#4a6fa5")

# 功能色
const COLOR_SUCCESS = COLOR_ACCENT_GREEN
const COLOR_WARNING = COLOR_ACCENT_GOLD
const COLOR_ERROR = COLOR_ACCENT_RED
const COLOR_INFO = COLOR_ACCENT_BLUE
```

### 7.3 字体定义

```gdscript
# 字体大小
const FONT_SIZE_TITLE = 36
const FONT_SIZE_HEADER = 28
const FONT_SIZE_SUBHEADER = 22
const FONT_SIZE_BODY = 16
const FONT_SIZE_SMALL = 14
const FONT_SIZE_TINY = 12

# 字体样式
const FONT_TITLE = preload("res://assets/fonts/source_han_serif.ttf")
const FONT_BODY = preload("res://assets/fonts/source_han_sans.ttf")
const FONT_EN_TITLE = preload("res://assets/fonts/cinzel_regular.ttf")
const FONT_EN_BODY = preload("res://assets/fonts/lato_regular.ttf")
```

### 7.4 组件样式定义

```gdscript
# Button样式
var button_normal = StyleBoxTexture.new()
button_normal.texture = preload("res://assets/images/ui/button_normal.png")
button_normal.patch_margin_left = 10
button_normal.patch_margin_top = 10
button_normal.patch_margin_right = 10
button_normal.patch_margin_bottom = 10

var button_hover = StyleBoxTexture.new()
button_hover.texture = preload("res://assets/images/ui/button_hover.png")
# ... 边距设置

var button_pressed = StyleBoxTexture.new()
button_pressed.texture = preload("res://assets/images/ui/button_pressed.png")
# ... 边距设置

var button_disabled = StyleBoxTexture.new()
button_disabled.texture = preload("res://assets/images/ui/button_disabled.png")
# ... 边距设置

# Panel样式
var panel_style = StyleBoxTexture.new()
panel_style.texture = preload("res://assets/images/ui/panel_bg.png")
# ... 边距设置

# Slider样式
var slider_grabber = StyleBoxTexture.new()
slider_grabber.texture = preload("res://assets/images/ui/slider_handle.png")

var slider_style = StyleBoxTexture.new()
slider_style.texture = preload("res://assets/images/ui/slider_bg.png")
```

---

## 8. 动画系统

### 8.1 动画类型定义

```gdscript
enum UIAnimationType {
    FADE_IN,          # 淡入
    FADE_OUT,         # 淡出
    SLIDE_IN_LEFT,    # 从左滑入
    SLIDE_IN_RIGHT,   # 从右滑入
    SLIDE_IN_TOP,     # 从上滑入
    SLIDE_IN_BOTTOM,  # 从下滑入
    SLIDE_OUT_LEFT,   # 向左滑出
    SLIDE_OUT_RIGHT,  # 向右滑出
    SLIDE_OUT_TOP,    # 向上滑出
    SLIDE_OUT_BOTTOM, # 向下滑出
    SCALE_IN,         # 缩放进入
    SCALE_OUT,        # 缩放退出
    INK_SPREAD,       # 墨水扩散
    PAPER_FLIP,       # 纸张翻转
}
```

### 8.2 动画配置

```gdscript
# 动画时长（秒）
const ANIMATION_DURATION = {
    "instant": 0.0,
    "fast": 0.15,
    "normal": 0.3,
    "slow": 0.5,
    "dramatic": 0.8
}

# 缓动函数
const EASE_TYPE = {
    "linear": Tween.TRANS_LINEAR,
    "ease_in": Tween.TRANS_EASE_IN,
    "ease_out": Tween.TRANS_EASE_OUT,
    "ease_in_out": Tween.TRANS_EASE_IN_OUT,
    "back_in": Tween.TRANS_BACK_IN,
    "back_out": Tween.TRANS_BACK_OUT,
    "bounce_out": Tween.TRANS_BOUNCE_OUT
}
```

### 8.3 UI动画管理器

```gdscript
class_name UIAnimationManager
extends Node

static var instance: UIAnimationManager

func _ready():
    instance = self

func animate(ui_element: Control, animation_type: int, 
             duration: float = 0.3, ease_type: int = Tween.TRANS_EASE_OUT):
    var tween = create_tween()
    tween.set_trans(ease_type)
    tween.set_ease(Tween.EASE_OUT)
    
    match animation_type:
        UIAnimationType.FADE_IN:
            ui_element.modulate.a = 0
            tween.tween_property(ui_element, "modulate:a", 1.0, duration)
        
        UIAnimationType.FADE_OUT:
            tween.tween_property(ui_element, "modulate:a", 0.0, duration)
        
        UIAnimationType.SLIDE_IN_LEFT:
            var target_pos = ui_element.position
            ui_element.position.x -= ui_element.size.x
            tween.tween_property(ui_element, "position:x", target_pos.x, duration)
        
        UIAnimationType.SCALE_IN:
            ui_element.scale = Vector2.ZERO
            tween.tween_property(ui_element, "scale", Vector2.ONE, duration)
        
        # ... 其他动画类型
    
    return tween

func play_ink_spread_transition(callback: Callable = Callable()):
    # 实现墨水扩散转场效果
    pass
```

---

## 9. 文件结构

### 9.1 完整文件结构

```
mist-painter/
├── project.godot
├── assets/
│   ├── themes/
│   │   ├── paper_theme.tres
│   │   └── fonts/
│   │       ├── source_han_serif.ttf
│   │       ├── source_han_sans.ttf
│   │       ├── cinzel_regular.ttf
│   │       └── lato_regular.ttf
│   └── images/
│       └── ui/
│           ├── paper_bg.png
│           ├── paper_texture.png
│           ├── button_normal.png
│           ├── button_hover.png
│           ├── button_pressed.png
│           ├── button_disabled.png
│           ├── panel_bg.png
│           ├── slider_bg.png
│           ├── slider_handle.png
│           ├── progress_bar_bg.png
│           ├── progress_bar_fill.png
│           └── icons/
│               └── (图标资源)
├── scenes/
│   └── ui/
│       ├── main_menu.tscn
│       ├── game_hud.tscn
│       ├── pause_menu.tscn
│       ├── settings_menu.tscn
│       ├── save_slot_select.tscn
│       ├── puzzle_interface.tscn
│       ├── item_inspect.tscn
│       └── dialog_box.tscn
└── src/
    └── ui/
        ├── UIManager.gd
        ├── UIAnimationManager.gd
        ├── components/
        │   ├── PaperButton.gd
        │   ├── PaperSlider.gd
        │   ├── PaperDropdown.gd
        │   ├── PaperPanel.gd
        │   ├── PaperProgressBar.gd
        │   └── NotificationToast.gd
        ├── screens/
        │   ├── BaseScreen.gd
        │   ├── MainMenu.gd
        │   ├── GameHUD.gd
        │   ├── PauseMenu.gd
        │   ├── SettingsMenu.gd
        │   ├── SaveSlotSelect.gd
        │   ├── PuzzleInterface.gd
        │   └── ItemInspect.gd
        └── managers/
            ├── HUDManager.gd
            ├── PopupManager.gd
            └── TransitionManager.gd
```

---

## 附录

### A. 快捷键映射

| 功能 | 键盘 | 手柄 |
|------|------|------|
| 打开菜单 | Esc | Start |
| 确认 | Enter/Space | A |
| 取消 | Esc/Backspace | B |
| 导航 | WASD/方向键 | 左摇杆/D-Pad |
| 快捷道具 | 1-5 | 方向键 |
| 地图 | M | Select |
| 日志 | L | LB |
| 背包 | I | RB |

### B. 分辨率适配表

| 分辨率 | 缩放比例 | 备注 |
|--------|----------|------|
| 3840×2160 (4K) | 2.0x | 高DPI |
| 2560×1440 (2K) | 1.33x | 推荐 |
| 1920×1080 (FHD) | 1.0x | 基准 |
| 1280×720 (HD) | 0.67x | 最低支持 |

---

*"好的UI应该让玩家忘记它的存在，只专注于游戏本身。"*

**文档结束**
