## LocalizationManager
## 本地化管理器
## 负责管理多语言文本和字体

class_name LocalizationManager
extends Node

# 当前语言
var current_language: String = "zh_CN"

# 语言数据
var translations: Dictionary = {}
var available_languages: Dictionary = {}

# 信号
signal language_changed(language: String)
signal translation_loaded(language: String)

# 语言配置
const LANGUAGE_CONFIG = {
    "zh_CN": {"name": "简体中文", "code": "zh_CN", "font": "res://assets/ui/fonts/NotoSansSC-Regular.ttf"},
    "zh_TW": {"name": "繁體中文", "code": "zh_TW", "font": "res://assets/ui/fonts/NotoSansTC-Regular.ttf"},
    "en": {"name": "English", "code": "en", "font": "res://assets/ui/fonts/NotoSans-Regular.ttf"},
    "ja": {"name": "日本語", "code": "ja", "font": "res://assets/ui/fonts/NotoSansJP-Regular.ttf"}
}

# 默认翻译（简体中文）
const DEFAULT_TRANSLATIONS = {
    # 通用
    "common.confirm": "确定",
    "common.cancel": "取消",
    "common.yes": "是",
    "common.no": "否",
    "common.back": "返回",
    "common.close": "关闭",
    "common.save": "保存",
    "common.load": "加载",
    "common.apply": "应用",
    "common.reset": "恢复默认",
    
    # 主菜单
    "menu.title": "迷雾绘者",
    "menu.subtitle": "Mist Painter",
    "menu.start_game": "开始游戏",
    "menu.continue": "继续游戏",
    "menu.settings": "设置",
    "menu.quit": "退出游戏",
    "menu.version": "版本 {version}",
    
    # 暂停菜单
    "pause.title": "游戏暂停",
    "pause.resume": "继续游戏",
    "pause.restart": "重新开始",
    "pause.settings": "设置",
    "pause.main_menu": "返回主菜单",
    "pause.quit": "退出游戏",
    
    # HUD
    "hud.health": "生命值",
    "hud.mist": "迷雾值",
    "hud.level": "关卡 {level}",
    "hud.map": "地图",
    "hud.inventory": "物品栏",
    
    # 设置分类
    "settings.display": "显示",
    "settings.audio": "音频",
    "settings.controls": "控制",
    "settings.game": "游戏",
    "settings.accessibility": "辅助功能",
    
    # 显示设置
    "settings.display_mode": "显示模式",
    "settings.display_mode.windowed": "窗口化",
    "settings.display_mode.fullscreen": "全屏",
    "settings.display_mode.borderless": "无边框窗口",
    "settings.resolution": "分辨率",
    "settings.vsync": "垂直同步",
    "settings.fps_limit": "帧率限制",
    "settings.show_fps": "显示FPS",
    
    # 音频设置
    "settings.master_volume": "主音量",
    "settings.music_volume": "音乐音量",
    "settings.sfx_volume": "音效音量",
    "settings.mute": "静音",
    
    # 游戏设置
    "settings.language": "语言",
    "settings.difficulty": "难度",
    "settings.difficulty.easy": "简单",
    "settings.difficulty.normal": "普通",
    "settings.difficulty.hard": "困难",
    "settings.hints": "显示提示",
    
    # 控制设置
    "settings.mouse_sensitivity": "鼠标灵敏度",
    "settings.invert_y": "反转Y轴",
    "settings.vibration": "手柄震动",
    
    # 辅助功能
    "settings.subtitles": "字幕",
    "settings.colorblind_mode": "色盲模式",
    "settings.colorblind_mode.none": "关闭",
    "settings.colorblind_mode.protanopia": "红色盲",
    "settings.colorblind_mode.deuteranopia": "绿色盲",
    "settings.colorblind_mode.tritanopia": "蓝色盲",
    "settings.text_size": "文本大小",
    
    # 对话框
    "dialog.confirm_title": "确认",
    "dialog.confirm_quit": "确定要退出游戏吗？",
    "dialog.confirm_restart": "确定要重新开始吗？当前进度将丢失。",
    "dialog.confirm_main_menu": "确定要返回主菜单吗？未保存的进度将丢失。",
    
    # 加载
    "loading.loading": "加载中...",
    "loading.saving": "保存中...",
    "loading.please_wait": "请稍候",
    
    # 错误提示
    "error.save_failed": "保存失败",
    "error.load_failed": "加载失败",
    "error.file_not_found": "文件未找到"
}

func _ready():
    # 注册可用语言
    _register_languages()
    
    # 加载默认翻译
    _load_default_translations()
    
    # 从配置加载语言设置
    _load_language_from_config()
    
    print("LocalizationManager initialized, current language: %s" % current_language)

func _register_languages() -> void:
    for lang_code in LANGUAGE_CONFIG.keys():
        available_languages[lang_code] = LANGUAGE_CONFIG[lang_code]

func _load_default_translations() -> void:
    translations["zh_CN"] = DEFAULT_TRANSLATIONS.duplicate()

func _load_language_from_config() -> void:
    if AutoLoad.config_manager:
        var saved_lang = AutoLoad.config_manager.get_setting("game_language", "zh_CN")
        if available_languages.has(saved_lang):
            current_language = saved_lang

## 设置当前语言
func set_language(language_code: String) -> bool:
    if not available_languages.has(language_code):
        push_error("Language not supported: %s" % language_code)
        return false
    
    if language_code == current_language:
        return true
    
    # 加载语言文件（如果尚未加载）
    if not translations.has(language_code):
        _load_translation_file(language_code)
    
    current_language = language_code
    
    # 保存到配置
    if AutoLoad.config_manager:
        AutoLoad.config_manager.set_setting("game_language", language_code)
    
    language_changed.emit(language_code)
    print("Language changed to: %s" % language_code)
    return true

## 获取当前语言代码
func get_current_language() -> String:
    return current_language

## 获取当前语言名称
func get_current_language_name() -> String:
    if available_languages.has(current_language):
        return available_languages[current_language]["name"]
    return current_language

## 获取文本翻译
func get_text(key: String, params: Dictionary = {}) -> String:
    var text = key
    
    # 先尝试当前语言的翻译
    if translations.has(current_language) and translations[current_language].has(key):
        text = translations[current_language][key]
    # 回退到默认语言
    elif translations.has("zh_CN") and translations["zh_CN"].has(key):
        text = translations["zh_CN"][key]
    
    # 替换参数
    for param_key in params.keys():
        text = text.replace("{" + param_key + "}", str(params[param_key]))
    
    return text

## 快捷翻译方法
func tr(key: String, params: Dictionary = {}) -> String:
    return get_text(key, params)

## 获取可用语言列表
func get_available_languages() -> Dictionary:
    return available_languages.duplicate()

## 加载翻译文件
func _load_translation_file(language_code: String) -> bool:
    var file_path = "res://assets/ui/localization/%s.json" % language_code
    
    if not FileAccess.file_exists(file_path):
        # 如果是默认语言，使用内置翻译
        if language_code == "zh_CN":
            translations[language_code] = DEFAULT_TRANSLATIONS.duplicate()
            return true
        return false
    
    var file = FileAccess.open(file_path, FileAccess.READ)
    if file == null:
        return false
    
    var json_text = file.get_as_text()
    file.close()
    
    var json = JSON.new()
    var error = json.parse(json_text)
    if error != OK:
        push_error("Failed to parse translation file: %s" % file_path)
        return false
    
    var data = json.get_data()
    if data is Dictionary:
        translations[language_code] = data
        translation_loaded.emit(language_code)
        return true
    
    return false

## 添加翻译条目
func add_translation(key: String, text: String, language_code: String = "") -> void:
    if language_code == "":
        language_code = current_language
    
    if not translations.has(language_code):
        translations[language_code] = {}
    
    translations[language_code][key] = text

## 批量添加翻译
func add_translations(translations_dict: Dictionary, language_code: String = "") -> void:
    if language_code == "":
        language_code = current_language
    
    if not translations.has(language_code):
        translations[language_code] = {}
    
    for key in translations_dict.keys():
        translations[language_code][key] = translations_dict[key]

## 获取字体路径
func get_font_path(language_code: String = "") -> String:
    if language_code == "":
        language_code = current_language
    
    if available_languages.has(language_code):
        return available_languages[language_code]["font"]
    
    return available_languages["zh_CN"]["font"]

## 检查是否支持RTL（从右到左）语言
func is_rtl_language(language_code: String = "") -> bool:
    # 当前不支持RTL语言
    return false

## 导出翻译模板
func export_translation_template(file_path: String) -> bool:
    var file = FileAccess.open(file_path, FileAccess.WRITE)
    if file == null:
        return false
    
    var template = {
        "_language": "template",
        "_version": "1.0"
    }
    
    # 复制所有键
    for key in DEFAULT_TRANSLATIONS.keys():
        template[key] = DEFAULT_TRANSLATIONS[key]
    
    var json_text = JSON.stringify(template, "\t", true)
    file.store_string(json_text)
    file.close()
    
    return true
