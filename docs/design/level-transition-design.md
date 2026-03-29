# 迷雾绘者 - 关卡过渡动画设计文档

> **版本**: v1.0  
> **创建时间**: 2026-03-28  
> **文档类型**: 设计与实现文档  
> **任务ID**: TASK-021

---

## 目录

1. [设计概述](#1-设计概述)
2. [视觉风格](#2-视觉风格)
3. [过渡动画类型](#3-过渡动画类型)
4. [技术实现](#4-技术实现)
5. [性能优化](#5-性能优化)
6. [集成指南](#6-集成指南)

---

## 1. 设计概述

### 1.1 设计目标

- **沉浸感**: 过渡动画需与游戏羊皮纸/墨水美学保持一致
- **流畅性**: 确保60fps流畅运行，不卡顿
- **信息传达**: 清晰传达关卡状态变化（开始/完成/失败）
- **性能**: 不影响游戏核心性能

### 1.2 核心设计原则

```
风格关键词:
├── 墨水晕染 (Ink Bleed) - 主要过渡效果
├── 羊皮纸质感 (Parchment Texture)
├── 手绘感 (Hand-drawn Feel)
└── 神秘氛围 (Mysterious Atmosphere)
```

---

## 2. 视觉风格

### 2.1 色彩方案

基于美术风格指南，过渡动画使用以下色彩：

| 用途 | 颜色 | 色值 | 说明 |
|------|------|------|------|
| 墨水扩散 | 墨黑 | `#1a1a1a` | 主要过渡遮罩 |
| 羊皮纸底色 | 羊皮纸浅 | `#f5f0e1` | 文字背景 |
| 成功强调 | 金 | `#c9a227` | 关卡完成 |
| 失败强调 | 红 | `#8b3a3a` | 关卡失败 |
| 普通强调 | 墨褐 | `#3d2817` | 普通过渡 |

### 2.2 动画曲线

```gdscript
# 缓动函数配置
const EASE_INK_BLEED = Tween.TRANS_EXPO    # 墨水快速扩散
const EASE_PAPER_SLIDE = Tween.TRANS_QUAD  # 纸张平滑滑动
const EASE_TEXT_FADE = Tween.TRANS_LINEAR  # 文字线性淡入
const EASE_ELASTIC = Tween.TRANS_ELASTIC   # 弹性效果（强调）
```

---

## 3. 过渡动画类型

### 3.1 关卡开始过渡 (Level Start)

**触发时机**: 进入新关卡时

**动画流程**:
```
1. 墨水从中心点向外晕染 (300ms)
2. 显示关卡信息文字 (羊皮纸质感背景) (400ms)
3. 文字淡入 + 轻微缩放 (500ms)
4. 墨水向中心收缩消失 (400ms)
5. 游戏画面完全显示
```

**视觉效果**:
- 中心点: 墨水从玩家位置或屏幕中心开始扩散
- 文字: 复古字体，羊皮纸卷轴展开效果
- 总时长: ~1600ms

### 3.2 关卡完成过渡 (Level Complete)

**触发时机**: 成功完成关卡目标时

**动画流程**:
```
1. 金色粒子从底部升起 (200ms)
2. "关卡完成"文字从上方滑入 (400ms)
3. 显示关卡统计信息 (600ms)
4. 羊皮纸卷轴收起效果 (400ms)
5. 淡入下一场景
```

**视觉效果**:
- 主色调: 金色 `#c9a227`
- 粒子效果: 金色光点向上飘散
- 文字: "关卡完成" + 统计信息
- 总时长: ~1600ms

### 3.3 关卡失败过渡 (Level Failed)

**触发时机**: 玩家失败（生命值归零等）时

**动画流程**:
```
1. 红色墨水从边缘向中心渗透 (300ms)
2. 屏幕轻微震动 (200ms)
3. "失败"文字显示，带裂纹效果 (500ms)
4. 显示重试选项 (400ms)
5. 等待玩家输入
```

**视觉效果**:
- 主色调: 暗红色 `#8b3a3a`
- 震动: 轻微屏幕抖动
- 文字: "失败" + 原因说明
- 总时长: ~1400ms（等待输入）

### 3.4 场景切换过渡 (Scene Transition)

**触发时机**: 场景间切换（如主菜单到游戏）

**动画流程**:
```
1. 墨水从一侧横扫至另一侧 (400ms)
2. 场景切换
3. 墨水从另一侧收回 (400ms)
```

**视觉效果**:
- 墨水横扫: 类似画笔刷过效果
- 总时长: ~800ms

---

## 4. 技术实现

### 4.1 文件结构

```
mist-painter/
├── src/
│   └── transitions/
│       ├── LevelTransitionManager.gd    # 主管理器
│       ├── BaseTransition.gd            # 基础过渡类
│       ├── InkBleedTransition.gd        # 墨水晕染效果
│       ├── PaperScrollTransition.gd     # 羊皮纸卷轴效果
│       └── ParticleEffects.gd           # 粒子效果
├── scenes/
│   └── transitions/
│       ├── level_transition.tscn        # 过渡场景
│       └── transition_assets/           # 过渡资源
│           ├── ink_mask.png
│           └── paper_texture.png
└── docs/
    └── LEVEL_TRANSITION_DESIGN.md       # 本文档
```

### 4.2 类设计

#### LevelTransitionManager (单例)

```gdscript
class_name LevelTransitionManager
extends Node

# 过渡类型枚举
enum TransitionType {
    LEVEL_START,      # 关卡开始
    LEVEL_COMPLETE,   # 关卡完成
    LEVEL_FAILED,     # 关卡失败
    SCENE_CHANGE,     # 场景切换
    GAME_OVER         # 游戏结束
}

# 信号
signal transition_started(type: TransitionType)
signal transition_finished(type: TransitionType)
signal transition_progress(progress: float)

# 核心方法
func play_transition(type: TransitionType, data: Dictionary = {}) -> void
func skip_current_transition() -> void
func is_transitioning() -> bool
```

#### BaseTransition (抽象基类)

```gdscript
class_name BaseTransition
extends Control

@export var duration_in: float = 0.5
@export var duration_out: float = 0.4
@export var duration_hold: float = 1.0

var is_playing: bool = false

func play_in() -> void   # 播放进入动画
func play_out() -> void  # 播放退出动画
func skip() -> void      # 跳过动画
```

---

## 5. 性能优化

### 5.1 渲染优化

| 优化项 | 实现方式 | 预期效果 |
|--------|----------|----------|
| 对象池 | 复用粒子节点 | 减少GC压力 |
| 遮罩缓存 | 预渲染墨水遮罩 | 减少实时计算 |
| 分层渲染 | UI与游戏分离 | 避免全屏重绘 |
| LOD | 远距离降低粒子密度 | 保持帧率 |

### 5.2 内存优化

```gdscript
# 资源预加载策略
const PRELOAD_TRANSITIONS = true
const MAX_CACHED_TRANSITIONS = 3

# 纹理压缩
const INK_MASK_SIZE = 512  # 而非1024
const PAPER_TEXTURE_SIZE = 256
```

### 5.3 目标性能指标

- **帧率**: 稳定60fps
- **内存占用**: < 50MB（过渡系统）
- **加载时间**: < 100ms（预加载）
- **动画流畅度**: 无掉帧、无卡顿

---

## 6. 集成指南

### 6.1 基础使用

```gdscript
# 在关卡开始时播放过渡
LevelTransitionManager.instance.play_transition(
    LevelTransitionManager.TransitionType.LEVEL_START,
    {
        "level_name": "第1层：遗迹入口",
        "level_number": 1
    }
)

# 监听完成事件
LevelTransitionManager.instance.transition_finished.connect(
    func(type): 
        if type == LevelTransitionManager.TransitionType.LEVEL_START:
            print("关卡开始动画完成，游戏继续")
)
```

### 6.2 与现有系统集成

#### 与 SceneManager 集成

```gdscript
# 在 scene_manager.gd 中
func change_scene(scene_path: String, transition: bool = true) -> void:
    if transition:
        await LevelTransitionManager.instance.play_transition(
            LevelTransitionManager.TransitionType.SCENE_CHANGE
        )
    # ... 原有场景切换逻辑
```

#### 与 EventBus 集成

```gdscript
# 事件总线已定义的信号
signal level_loaded(level_id: String)
signal level_completed(level_id: String)

# 在 LevelTransitionManager 中连接
EventBus.level_completed.connect(
    func(level_id):
        play_transition(TransitionType.LEVEL_COMPLETE, {"level_id": level_id})
)
```

### 6.3 自定义过渡

```gdscript
# 创建自定义过渡效果
class_name CustomTransition
extends BaseTransition

func play_in() -> void:
    # 自定义进入动画
    var tween = create_tween()
    # ... 动画逻辑
    await tween.finished
    transition_in_finished.emit()

func play_out() -> void:
    # 自定义退出动画
    var tween = create_tween()
    # ... 动画逻辑
    await tween.finished
    transition_out_finished.emit()
```

---

## 附录

### A. 动画时间参考

| 动画类型 | 进入时长 | 保持时长 | 退出时长 | 总时长 |
|----------|----------|----------|----------|--------|
| 关卡开始 | 300ms | 800ms | 400ms | 1500ms |
| 关卡完成 | 400ms | 600ms | 400ms | 1400ms |
| 关卡失败 | 300ms | - | 400ms | 700ms+ |
| 场景切换 | 400ms | 0ms | 400ms | 800ms |

### B. 版本历史

| 版本 | 日期 | 更新内容 |
|------|------|----------|
| v1.0 | 2026-03-28 | 初始版本，完整过渡动画设计 |

---

*"好的过渡动画让玩家在场景切换中保持沉浸感。"*

**文档结束**
