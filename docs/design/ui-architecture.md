# 迷雾绘者 (Mist Painter) - UI架构设计文档

> **版本**: v1.0  
> **创建时间**: 2026-03-21  
> **最后更新**: 2026-03-21  
> **文档类型**: 技术架构设计文档

---

## 1. 架构概述

### 1.1 设计目标

迷雾绘者UI系统的设计目标：

1. **一致性**: 所有UI元素遵循统一的美术风格和交互规范
2. **可扩展性**: 支持新界面和组件的快速开发
3. **可维护性**: 清晰的代码结构和职责分离
4. **多平台支持**: 适配键盘、鼠标、手柄等多种输入方式
5. **本地化支持**: 支持多语言切换

### 1.2 架构模式

采用 **组件化架构 + 状态管理** 模式：

```
┌─────────────────────────────────────────────────────────────┐
│                      UI Layer (CanvasLayer)                  │
├─────────────────────────────────────────────────────────────┤
│  Screens (Views)          Components (Widgets)              │
│  ├── MainMenu             ├── UIButton                      │
│  ├── HUD                  ├── UISlider                      │
│  ├── PauseMenu            ├── UILabel                       │
│  ├── SettingsMenu         ├── UIPanel                     │
│  └── Dialog               └── ...                           │
├─────────────────────────────────────────────────────────────┤
│                      UIManager (单例)                        │
│  ├── ThemeManager         - 主题管理                        │
│  ├── LocalizationManager  - 本地化管理                    │
│  ├── NavigationManager    - 导航管理                        │
│  └── AnimationManager     - 动画管理                        │
├─────────────────────────────────────────────────────────────┤
│                      Core Systems                            │
│  ├── GameStateManager     - 游戏状态                        │
│  ├── ConfigManager        - 配置管理                        │
│  └── EventBus             - 事件总线                        │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. 核心模块设计

### 2.1 UIManager - UI中央控制器

**职责**:
- 管理所有UI屏幕的生命周期
- 处理屏幕切换和过渡动画
- 提供全局UI功能（Toast、Dialog）
- 协调各子管理器工作

**设计模式**: 单例模式

```gdscript
class_name UIManager
extends Node

static var instance: UIManager = null

# 屏幕枚举
enum UIScreen {
    NONE, MAIN_MENU, HUD, PAUSE_MENU,
    SETTINGS_MENU, DIALOG, LOADING, GAME_OVER, LEVEL_COMPLETE
}

# 核心方法
func open_screen(screen: UIScreen, transition: bool = true)
func close_screen(screen: UIScreen, transition: bool = true)
func show_toast(message: String, duration: float = 3.0)
func show_dialog(title: String, message: String, ...)
```

### 2.2 ThemeManager - 主题管理器

**职责**:
- 管理UI主题配置（颜色、字体、尺寸）
- 支持主题切换
- 提供主题资源生成

**主题结构**:
```gdscript
var theme = {
    "name": "parchment",  # 羊皮纸主题
    "colors": {
        "primary": Color(0.788, 0.635, 0.153),      # 金色 #c9a227
        "secondary": Color(0.239, 0.157, 0.090),    # 墨褐 #3d2817
        "background": Color(0.961, 0.941, 0.882),   # 羊皮纸浅 #f5f0e1
        "surface": Color(0.910, 0.863, 0.769),      # 羊皮纸中 #e8dcc4
        "text": Color(0.102, 0.102, 0.102),         # 墨黑 #1a1a1a
        "text_secondary": Color(0.353, 0.353, 0.353), # 墨淡 #5a5a5a
        "accent": Color(0.290, 0.486, 0.349),       # 绿 #4a7c59
        "error": Color(0.545, 0.227, 0.227),        # 红 #8b3a3a
        "shadow": Color(0, 0, 0, 0.3)
    },
    "sizes": {
        "border_radius_small": 4,
        "border_radius_medium": 8,
        "border_radius_large": 12,
        "spacing_small": 8,
        "spacing_medium": 16,
        "spacing_large": 24
    },
    "fonts": {
        "heading_size": 36,
        "body_size": 18,
        "caption_size": 14
    }
}
```

### 2.3 NavigationManager - 导航管理器

**职责**:
- 处理焦点导航（键盘/手柄）
- 检测输入设备变化
- 管理焦点栈

**导航模式**:
```gdscript
enum NavigationMode {
    MOUSE,      # 鼠标导航
    KEYBOARD,   # 键盘导航
    GAMEPAD     # 手柄导航
}
```

**输入映射**:
| 操作 | 键盘 | 手柄 |
|------|------|------|
| 向上导航 | W / ↑ | 左摇杆上 / DPad上 |
| 向下导航 | S / ↓ | 左摇杆下 / DPad下 |
| 确认 | Enter / Space | A键 |
| 取消 | Esc / Backspace | B键 |
| 暂停 | Esc | Start键 |

### 2.4 AnimationManager - 动画管理器

**职责**:
- 管理UI动画和过渡效果
- 提供常用动画封装
- 动画生命周期管理

**动画类型**:
```gdscript
enum AnimationType {
    FADE_IN, FADE_OUT,
    SLIDE_IN_LEFT, SLIDE_IN_RIGHT, SLIDE_IN_UP, SLIDE_IN_DOWN,
    SLIDE_OUT_LEFT, SLIDE_OUT_RIGHT, SLIDE_OUT_UP, SLIDE_OUT_DOWN,
    SCALE_IN, SCALE_OUT,
    BOUNCE_IN, BOUNCE_OUT,
    SHAKE, PULSE
}
```

**动画规范**:
| 动画类型 | 时长 | 缓动函数 |
|----------|------|----------|
| 界面切换 | 300ms | EASE_OUT |
| 按钮悬停 | 150ms | EASE_OUT |
| 按钮点击 | 100ms | EASE_OUT |
| 数值变化 | 300ms | EASE_OUT |

---

## 3. 组件库设计

### 3.1 组件层次结构

```
Control (Godot基类)
├── UIButton (自定义按钮)
├── UISlider (自定义滑块)
├── UILabel (自定义标签)
├── UIPanel (自定义面板)
├── UIProgressBar (进度条)
├── UIContainer (容器基类)
│   ├── UIVBoxContainer (垂直布局)
│   └── UIHBoxContainer (水平布局)
└── UIAnimation (动画工具)
```

### 3.2 UIButton - 按钮组件

**功能特性**:
- 多种按钮类型（Primary、Secondary、Accent、Danger、Ghost）
- 多种尺寸（Small、Medium、Large）
- 悬停、点击、焦点状态动画
- 羊皮纸风格样式

**状态样式**:
```
正常状态: 羊皮纸背景 + 墨褐边框
悬停状态: 背景变亮 + 边框高亮 + 轻微放大(105%)
点击状态: 轻微缩小(95%) + 内阴影
禁用状态: 灰度 + 透明度50%
焦点状态: 金色边框高亮
```

### 3.3 UISlider - 滑块组件

**功能特性**:
- 数值显示（百分比/数值/自定义格式）
- 步进调节
- 羊皮纸风格滑块轨道和手柄
- 实时数值标签

**样式规范**:
```
轨道: 羊皮纸深色背景 + 圆角
填充: 金色渐变
手柄: 圆形 + 阴影 + 悬停放大
```

### 3.4 UILabel - 标签组件

**功能特性**:
- 多种文本样式（标题、正文、注释）
- 自动换行
- 富文本支持（可选）
- 描边/阴影效果

**文本样式**:
| 类型 | 字号 | 颜色 | 用途 |
|------|------|------|------|
| Heading | 36px | 墨黑 | 界面标题 |
| Title | 28px | 墨黑 | 面板标题 |
| Body | 18px | 墨黑 | 正文文本 |
| Caption | 14px | 墨淡 | 注释说明 |

### 3.5 UIPanel - 面板组件

**功能特性**:
- 羊皮纸纹理背景
- 手绘风格边框
- 圆角支持
- 阴影效果
- 标题栏（可选）

**样式规范**:
```
背景: 羊皮纸中色 #e8dcc4
边框: 墨褐色 #3d2817, 2px宽度
圆角: 8px
阴影: 偏移(2, 2), 模糊8px, 透明度30%
```

---

## 4. 美术风格集成

### 4.1 色彩系统

基于美术风格指南的UI色彩：

```gdscript
# 主色调（羊皮纸色系）
const PAPER_LIGHT = Color(0.961, 0.941, 0.882)   # #f5f0e1
const PAPER_MEDIUM = Color(0.910, 0.863, 0.769)  # #e8dcc4
const PAPER_DARK = Color(0.831, 0.769, 0.659)    # #d4c4a8
const PAPER_AGED = Color(0.788, 0.722, 0.588)    # #c9b896

# 辅助色（墨水色系）
const INK_BLACK = Color(0.102, 0.102, 0.102)     # #1a1a1a
const INK_DARK = Color(0.176, 0.176, 0.176)      # #2d2d2d
const INK_FADED = Color(0.353, 0.353, 0.353)     # #5a5a5a
const INK_BROWN = Color(0.239, 0.157, 0.090)     # #3d2817

# 强调色
const ACCENT_GOLD = Color(0.788, 0.635, 0.153)   # #c9a227
const ACCENT_RED = Color(0.545, 0.227, 0.227)    # #8b3a3a
const ACCENT_GREEN = Color(0.290, 0.486, 0.349)  # #4a7c59
const ACCENT_BLUE = Color(0.290, 0.435, 0.647)   # #4a6fa5
```

### 4.2 字体系统

**中文字体**:
- 标题: 思源宋体 (Source Han Serif)
- 正文: 思源黑体 (Source Han Sans)

**英文字体**:
- 标题: Cinzel (古典衬线)
- 正文: Lato (无衬线)

### 4.3 动画风格

**转场动画**:
- 类型: 墨水晕染效果
- 时长: 500ms
- 缓动: ease-in-out

**UI动画**:
- 按钮反馈: 150ms, ease-out
- 界面切换: 300ms, ease-out
- 数值变化: 300ms, ease-out

---

## 5. 文件结构

```
src/ui/
├── UIManager.gd              # UI中央管理器
├── UITheme.gd                # 主题系统常量
├── UIAnimation.gd            # 动画工具类
├── ThemeManager.gd           # 主题管理器
├── NavigationManager.gd      # 导航管理器
├── AnimationManager.gd       # 动画管理器
├── LocalizationManager.gd    # 本地化管理器
├── components/               # UI组件
│   ├── UIButton.gd           # 按钮组件
│   ├── UISlider.gd           # 滑块组件
│   ├── UILabel.gd            # 标签组件
│   ├── UIPanel.gd            # 面板组件
│   ├── UIProgressBar.gd      # 进度条组件
│   ├── HealthBar.gd          # 生命值条
│   ├── MistBar.gd            # 迷雾值条
│   ├── DialogBox.gd          # 对话框
│   └── ToastNotification.gd  # 通知提示
└── screens/                  # UI屏幕
    ├── MainMenu.tscn
    ├── HUD.tscn
    ├── PauseMenu.tscn
    └── SettingsMenu.tscn
```

---

## 6. 使用示例

### 6.1 创建按钮

```gdscript
var button = UIButton.new()
button.text = "开始游戏"
button.button_type = UIButton.ButtonType.PRIMARY
button.button_size = UIButton.ButtonSize.LARGE
button.pressed.connect(_on_start_game)
container.add_child(button)
```

### 6.2 创建滑块

```gdscript
var slider = UISlider.new()
slider.min_value = 0
slider.max_value = 100
slider.display_mode = UISlider.DisplayMode.PERCENTAGE
slider.value_changed.connect(_on_volume_changed)
container.add_child(slider)
```

### 6.3 创建面板

```gdscript
var panel = UIPanel.new()
panel.title = "设置"
panel.show_title = true
panel.custom_minimum_size = Vector2(400, 300)
ui_layer.add_child(panel)
```

---

## 7. 性能考虑

### 7.1 优化策略

1. **对象池**: 频繁使用的UI元素（如Toast）使用对象池
2. **延迟加载**: 非关键UI屏幕延迟加载
3. **动画优化**: 使用Tween而非AnimationPlayer，减少节点开销
4. **批量更新**: 主题切换时批量更新所有UI元素

### 7.2 内存管理

- 屏幕关闭时释放资源（可选）
- 使用`queue_free()`正确释放节点
- 断开不再使用的信号连接

---

## 8. 扩展指南

### 8.1 添加新组件

1. 继承合适的基类（Control/Button等）
2. 实现`_ready()`初始化样式
3. 添加动画支持
4. 在ThemeManager中添加相关样式配置

### 8.2 添加新主题

1. 在ThemeManager中注册新主题
2. 定义完整的颜色、尺寸、字体配置
3. 提供主题切换接口

---

## 9. 版本历史

| 版本 | 日期 | 更新内容 |
|------|------|----------|
| v1.0 | 2026-03-21 | 初始版本，完整UI架构设计 |

---

*文档结束*