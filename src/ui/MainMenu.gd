## MainMenu
## 主菜单控制器

class_name MainMenu
extends Control

func _ready():
    print("MainMenu initialized")
    
    # 设置游戏状态
    AutoLoad.game_state.change_state(GameStateManager.GameState.MAIN_MENU)
    
    # 检查是否有存档
    _check_save_data()

## 检查存档数据
func _check_save_data() -> void:
    var continue_button = $MenuContainer/ContinueButton
    if continue_button:
        # TODO: 检查是否有存档
        # 如果没有存档，禁用继续游戏按钮
        continue_button.disabled = true
        continue_button.modulate.a = 0.5

## 开始新游戏
func _on_start_button_pressed() -> void:
    print("Start button pressed")
    
    # 重置游戏状态
    AutoLoad.game_state.set_current_level(0)
    AutoLoad.game_state.reset_stats()
    
    # 切换到游戏场景
    AutoLoad.scene_manager.change_scene_by_name("game")

## 继续游戏
func _on_continue_button_pressed() -> void:
    print("Continue button pressed")
    
    # TODO: 加载存档
    # 1. 读取存档数据
    # 2. 恢复游戏状态
    # 3. 切换到游戏场景
    
    AutoLoad.scene_manager.change_scene_by_name("game")

## 打开设置
func _on_settings_button_pressed() -> void:
    print("Settings button pressed")
    
    # TODO: 打开设置菜单
    # 可以实例化设置场景或切换到设置场景

## 退出游戏
func _on_exit_button_pressed() -> void:
    print("Exit button pressed")
    get_tree().quit()
