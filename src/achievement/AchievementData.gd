## AchievementData
## 成就数据定义
## 定义成就的数据结构和相关常量

class_name AchievementData
extends RefCounted

# ============================================
# 成就类型枚举
# ============================================

enum AchievementType {
    PROGRESS,       # 进度类（如收集10个物品）
    ONE_TIME,       # 一次性（如首次完成某事）
    CUMULATIVE,     # 累积类（如累计游玩100小时）
    HIDDEN          # 隐藏成就（描述隐藏，解锁后显示）
}

# ============================================
# 成就稀有度枚举
# ============================================

enum AchievementRarity {
    COMMON,         # 普通（白色）
    UNCOMMON,       # 稀有（绿色）
    RARE,           # 罕见（蓝色）
    EPIC,           # 史诗（紫色）
    LEGENDARY       # 传说（橙色）
}

# ============================================
# 成就数据类
# ============================================

class Achievement extends RefCounted:
    ## 成就唯一标识符
    var id: String = ""
    
    ## 成就名称
    var name: String = ""
    
    ## 成就描述
    var description: String = ""
    
    ## 隐藏成就未解锁时的替代描述
    var hidden_description: String = "???"
    
    ## 成就图标路径（未解锁）
    var icon_locked_path: String = ""
    
    ## 成就图标路径（已解锁）
    var icon_unlocked_path: String = ""
    
    ## 成就类型
    var type: AchievementType = AchievementType.ONE_TIME
    
    ## 成就稀有度
    var rarity: AchievementRarity = AchievementRarity.COMMON
    
    ## 解锁条件（用于程序化检查）
    var condition_type: String = ""
    
    ## 解锁条件参数
    var condition_params: Dictionary = {}
    
    ## 目标进度值（用于进度类成就）
    var target_progress: int = 1
    
    ## 奖励（游戏内货币、道具等）
    var rewards: Dictionary = {}
    
    ## 是否隐藏成就
    var is_hidden: bool = false
    
    ## 是否已解锁
    var is_unlocked: bool = false
    
    ## 解锁时间戳
    var unlocked_at: String = ""
    
    ## 当前进度（用于进度类成就）
    var current_progress: int = 0
    
    ## 成就点数
    var points: int = 10
    
    ## 构造函数
    func _init(data: Dictionary = {}):
        if data.is_empty():
            return
        
        id = data.get("id", "")
        name = data.get("name", "")
        description = data.get("description", "")
        hidden_description = data.get("hidden_description", "???")
        icon_locked_path = data.get("icon_locked_path", "")
        icon_unlocked_path = data.get("icon_unlocked_path", "")
        type = data.get("type", AchievementType.ONE_TIME)
        rarity = data.get("rarity", AchievementRarity.COMMON)
        condition_type = data.get("condition_type", "")
        condition_params = data.get("condition_params", {})
        target_progress = data.get("target_progress", 1)
        rewards = data.get("rewards", {})
        is_hidden = data.get("is_hidden", false)
        is_unlocked = data.get("is_unlocked", false)
        unlocked_at = data.get("unlocked_at", "")
        current_progress = data.get("current_progress", 0)
        points = data.get("points", 10)
    
    ## 转换为字典（用于序列化）
    func to_dictionary() -> Dictionary:
        return {
            "id": id,
            "name": name,
            "description": description,
            "hidden_description": hidden_description,
            "icon_locked_path": icon_locked_path,
            "icon_unlocked_path": icon_unlocked_path,
            "type": type,
            "rarity": rarity,
            "condition_type": condition_type,
            "condition_params": condition_params,
            "target_progress": target_progress,
            "rewards": rewards,
            "is_hidden": is_hidden,
            "is_unlocked": is_unlocked,
            "unlocked_at": unlocked_at,
            "current_progress": current_progress,
            "points": points
        }
    
    ## 获取显示描述
    func get_display_description() -> String:
        if is_hidden and not is_unlocked:
            return hidden_description
        return description
    
    ## 获取显示图标路径
    func get_display_icon_path() -> String:
        if is_unlocked:
            return icon_unlocked_path if not icon_unlocked_path.is_empty() else icon_locked_path
        return icon_locked_path
    
    ## 获取进度百分比（0.0 - 1.0）
    func get_progress_percent() -> float:
        if target_progress <= 0:
            return 1.0 if is_unlocked else 0.0
        return clamp(float(current_progress) / float(target_progress), 0.0, 1.0)
    
    ## 检查是否可解锁
    func can_unlock() -> bool:
        if is_unlocked:
            return false
        
        match type:
            AchievementType.PROGRESS, AchievementType.CUMULATIVE:
                return current_progress >= target_progress
            AchievementType.ONE_TIME, AchievementType.HIDDEN:
                return true
        
        return false
    
    ## 解锁成就
    func unlock() -> void:
        if is_unlocked:
            return
        
        is_unlocked = true
        unlocked_at = Time.get_datetime_string_from_system()
        current_progress = target_progress
    
    ## 更新进度
    func update_progress(amount: int = 1) -> bool:
        if is_unlocked:
            return false
        
        match type:
            AchievementType.PROGRESS, AchievementType.CUMULATIVE:
                current_progress = min(current_progress + amount, target_progress)
                return can_unlock()
        
        return false
    
    ## 设置进度
    func set_progress(value: int) -> bool:
        if is_unlocked:
            return false
        
        match type:
            AchievementType.PROGRESS, AchievementType.CUMULATIVE:
                current_progress = clamp(value, 0, target_progress)
                return can_unlock()
        
        return false
    
    ## 获取稀有度颜色
    func get_rarity_color() -> Color:
        match rarity:
            AchievementRarity.COMMON:
                return Color(0.9, 0.9, 0.9)  # 白色
            AchievementRarity.UNCOMMON:
                return Color(0.2, 0.8, 0.2)  # 绿色
            AchievementRarity.RARE:
                return Color(0.2, 0.5, 1.0)  # 蓝色
            AchievementRarity.EPIC:
                return Color(0.6, 0.2, 0.8)  # 紫色
            AchievementRarity.LEGENDARY:
                return Color(1.0, 0.5, 0.0)  # 橙色
        return Color.WHITE
    
    ## 获取稀有度名称
    func get_rarity_name() -> String:
        match rarity:
            AchievementRarity.COMMON:
                return "普通"
            AchievementRarity.UNCOMMON:
                return "稀有"
            AchievementRarity.RARE:
                return "罕见"
            AchievementRarity.EPIC:
                return "史诗"
            AchievementRarity.LEGENDARY:
                return "传说"
        return "未知"

# ============================================
# 成就统计类
# ============================================

class AchievementStats extends RefCounted:
    ## 总成就数
    var total_count: int = 0
    
    ## 已解锁成就数
    var unlocked_count: int = 0
    
    ## 总成就点数
    var total_points: int = 0
    
    ## 已获得成就点数
    var earned_points: int = 0
    
    ## 隐藏成就数
    var hidden_count: int = 0
    
    ## 已解锁隐藏成就数
    var hidden_unlocked_count: int = 0
    
    ## 计算完成百分比
    func get_completion_percent() -> float:
        if total_count <= 0:
            return 0.0
        return float(unlocked_count) / float(total_count) * 100.0
    
    ## 转换为字典
    func to_dictionary() -> Dictionary:
        return {
            "total_count": total_count,
            "unlocked_count": unlocked_count,
            "total_points": total_points,
            "earned_points": earned_points,
            "hidden_count": hidden_count,
            "hidden_unlocked_count": hidden_unlocked_count,
            "completion_percent": get_completion_percent()
        }

# ============================================
# 静态工具方法
# ============================================

## 从JSON文件加载成就定义
