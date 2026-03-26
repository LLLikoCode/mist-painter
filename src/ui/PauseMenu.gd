## PauseMenu
## 暂停菜单控制器

class_name PauseMenu
extends Control

func _ready():
    print("PauseMenu initialized")

## 继续游戏
func _on_resume_button_pressed() -> void:
    print("Resume button pressed")
    
    # 通知游戏控制器继续游戏
    var game_controller = get_tree().current_scene
    if game_controller and game_controller.has_method("resume_game"):
        game_controller.resume_game()

## 重新开始
func _on_restart_button_pressed() -> void:
    print("Restart button pressed")
    
    var game_controller = get_tree().current_scene
    if game_controller and game_controller.has_method("restart_level"):
        game_controller.restart_level()

## 打开设置
func _on_settings_button_pressed() -> void:
    print("Settings button pressed")
    
    # TODO: 打开设置菜单

## 返回主菜单
func _on_main_menu_button_pressed() -> void:
    print("Main menu button pressed")
    
    var game_controller = get_tree().current_scene
    if game_controller and game_controller.has_method("return_to_main_menu"):
        game_controller.return_to_main_menu()

## 退出游戏
func _on_quit_button_pressed() -> void:
    print("Quit button pressed")
    get_tree().quit()
