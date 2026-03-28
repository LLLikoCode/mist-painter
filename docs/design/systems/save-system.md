# 迷雾绘者 - 存档系统设计文档

## 1. 概述

### 1.1 设计目标
- 提供稳定可靠的存档/读档功能
- 支持多存档槽位管理
- 支持自动存档与手动存档
- 确保存档数据安全（加密与校验）
- 跨平台兼容（Windows/Mac/Linux）

### 1.2 技术选型
- **引擎**: Godot 4.x
- **脚本语言**: GDScript
- **存档格式**: 二进制 + XOR加密 + CRC32校验
- **存储路径**: 用户数据目录 (`user://saves/`)

---

## 2. 数据结构设计

### 2.1 核心存档数据结构

```gdscript
class SaveData
├── metadata: SaveMetadata      # 存档元数据
├── player: PlayerData          # 玩家数据
├── progress: ProgressData      # 游戏进度
├── inventory: InventoryData    # 物品栏
├── settings: SettingsData      # 游戏设置
└── checkpoints: Dictionary     # 检查点数据
```

### 2.2 详细字段定义

#### SaveMetadata - 存档元数据
| 字段 | 类型 | 说明 |
|------|------|------|
| version | int | 存档版本号（用于兼容性处理） |
| save_time | int | 存档时间戳（Unix时间） |
| play_time | float | 累计游戏时长（秒） |
| current_level | String | 当前关卡名称/ID |
| current_scene | String | 当前场景路径 |
| slot_index | int | 存档槽位索引 |
| is_auto_save | bool | 是否为自动存档 |

#### PlayerData - 玩家数据
| 字段 | 类型 | 说明 |
|------|------|------|
| position | Vector2 | 玩家位置 |
| health | int | 当前生命值 |
| max_health | int | 最大生命值 |
| abilities | Array[String] | 已解锁能力 |
| stats | Dictionary | 玩家统计数据 |

#### ProgressData - 游戏进度
| 字段 | 类型 | 说明 |
|------|------|------|
| unlocked_levels | Array[String] | 已解锁关卡 |
| completed_puzzles | Array[String] | 已完成谜题 |
| story_flags | Dictionary | 剧情标志位 |
| collectibles | Dictionary | 收集品状态 |

#### InventoryData - 物品栏
| 字段 | 类型 | 说明 |
|------|------|------|
| items | Array[Dictionary] | 物品列表 |
| active_item | String | 当前激活物品 |
| capacity | int | 背包容量 |

#### SettingsData - 游戏设置
| 字段 | 类型 | 说明 |
|------|------|------|
| audio_volume | Dictionary | 音量设置 |
| video_settings | Dictionary | 视频设置 |
| control_bindings | Dictionary | 按键绑定 |

---

## 3. 存档文件格式

### 3.1 文件结构

```
[文件头 Header]     - 8 bytes
[元数据 Metadata]   - 变长（JSON序列化后压缩）
[存档数据 Data]     - 变长（二进制序列化）
[校验和 Checksum]   - 4 bytes (CRC32)
```

### 3.2 文件头格式 (8 bytes)

```
Bytes 0-3: 魔数 "MPSV" (Mist Painter Save)
Byte 4:    主版本号
Byte 5:    次版本号
Byte 6:    加密标志 (0=未加密, 1=XOR加密)
Byte 7:    保留字节
```

### 3.3 加密方案

- **算法**: XOR加密 + 简单混淆
- **密钥**: 基于游戏特定常量 + 存档时间戳
- **目的**: 防止普通玩家随意修改存档，非高强度安全

### 3.4 文件命名规范

```
save_001.dat    - 手动存档槽位1
save_002.dat    - 手动存档槽位2
save_003.dat    - 手动存档槽位3
auto_save.dat   - 自动存档
backup.dat      - 备份存档
```

---

## 4. 存储路径规划

### 4.1 目录结构

```
user://
├── saves/
│   ├── save_001.dat      # 存档槽位1
│   ├── save_002.dat      # 存档槽位2
│   ├── save_003.dat      # 存档槽位3
│   ├── auto_save.dat     # 自动存档
│   ├── backup.dat        # 备份存档
│   └── meta.json         # 存档元信息索引
└── config/
    └── settings.dat      # 独立设置存档
```

### 4.2 跨平台路径

| 平台 | 实际路径 |
|------|----------|
| Windows | `%APPDATA%/Godot/app_userdata/[项目名]/saves/` |
| macOS | `~/Library/Application Support/Godot/app_userdata/[项目名]/saves/` |
| Linux | `~/.local/share/godot/app_userdata/[项目名]/saves/` |

---

## 5. 存档管理器接口

### 5.1 核心方法

```gdscript
class SaveManager

# 存档操作
static func save_game(slot_index: int, is_auto: bool = false) -> bool
static func load_game(slot_index: int) -> SaveData
static func delete_save(slot_index: int) -> bool
static func has_save(slot_index: int) -> bool

# 自动存档
static func auto_save() -> bool
static func get_auto_save_data() -> SaveData

# 存档信息
static func get_save_info(slot_index: int) -> Dictionary
static func list_all_saves() -> Array[Dictionary]
static func get_empty_slot() -> int

# 导入/导出
static func export_save(slot_index: int, path: String) -> bool
static func import_save(path: String, slot_index: int) -> bool

# 备份与恢复
static func create_backup() -> bool
static func restore_from_backup() -> bool
```

### 5.2 信号系统

```gdscript
signal save_completed(slot_index: int, success: bool)
signal load_completed(slot_index: int, data: SaveData)
signal auto_save_triggered()
signal save_corrupted(slot_index: int)
```

---

## 6. 自动存档机制

### 6.1 触发条件

| 场景 | 延迟 | 说明 |
|------|------|------|
| 进入新关卡 | 立即 | 确保进度不丢失 |
| 完成关键事件 | 2秒 | 避免频繁存档 |
| 玩家手动触发 | 立即 | 菜单中的自动存档选项 |
| 定时存档 | 5分钟 | 后台自动保存 |

### 6.2 自动存档限制

- 最多保留1个自动存档
- 自动存档可被手动存档覆盖
- 自动存档显示特殊标识

---

## 7. 错误处理与恢复

### 7.1 异常情况

| 异常 | 处理方式 |
|------|----------|
| 存档文件损坏 | 尝试从备份恢复，否则删除重建 |
| 磁盘空间不足 | 提示用户清理空间 |
| 版本不兼容 | 尝试迁移，失败则提示 |
| 读档失败 | 返回错误码，保持当前状态 |

### 7.2 备份策略

- 每次覆盖存档前自动创建备份
- 保留最近1个备份
- 备份文件独立存储

---

## 8. 版本兼容性

### 8.1 存档版本管理

```gdscript
const CURRENT_VERSION = 1

# 版本迁移表
const MIGRATIONS = {
    1: "_migrate_v1_to_v2",
    2: "_migrate_v2_to_v3"
}
```

### 8.2 迁移策略

1. 读取存档时检查版本号
2. 如果版本低于当前版本，依次执行迁移函数
3. 迁移成功后更新版本号
4. 无法迁移时提示用户

---

## 9. 性能优化

### 9.1 写入优化

- 使用异步文件写入（Godot的FileAccess）
- 大数据分块序列化
- 避免频繁存档（防抖处理）

### 9.2 读取优化

- 元数据单独缓存
- 延迟加载大型数据（如关卡状态）
- 存档列表使用索引文件

---

## 10. 使用示例

### 10.1 基本存档/读档

```gdscript
# 保存到槽位1
if SaveManager.save_game(1):
    print("存档成功")

# 从槽位1读取
var save_data = SaveManager.load_game(1)
if save_data:
    print("当前关卡: ", save_data.metadata.current_level)
```

### 10.2 自动存档

```gdscript
# 在关卡切换时自动存档
func _on_level_changed(new_level: String):
    SaveManager.auto_save()

# 定时自动存档
var auto_save_timer: Timer

func _ready():
    auto_save_timer = Timer.new()
    auto_save_timer.wait_time = 300  # 5分钟
    auto_save_timer.timeout.connect(SaveManager.auto_save)
    add_child(auto_save_timer)
    auto_save_timer.start()
```

### 10.3 存档槽位UI

```gdscript
# 获取所有存档信息用于显示
func update_save_slots():
    for i in range(1, 4):
        var info = SaveManager.get_save_info(i)
        if info.is_empty:
            slot_buttons[i].text = "空槽位"
        else:
            slot_buttons[i].text = "%s\n%s" % [
                info.current_level,
                Time.get_datetime_string_from_unix_time(info.save_time)
            ]
```

---

## 11. 待办事项

- [ ] 实现存档压缩（考虑使用 Godot 的 Compression 类）
- [ ] 添加 Steam 云存档支持
- [ ] 实现存档截图功能
- [ ] 添加存档描述/备注功能
- [ ] 支持更多存档槽位（可配置）

---

**文档版本**: 1.0  
**创建日期**: 2026-03-21  
**作者**: 调月莉音
