## Logger
## 日志工具类
## 提供统一的日志记录功能

class_name Logger
extends RefCounted

# 日志级别
enum LogLevel {
    DEBUG = 0,
    INFO = 1,
    WARNING = 2,
    ERROR = 3,
    FATAL = 4
}

# 当前日志级别
static var current_level: LogLevel = LogLevel.DEBUG

# 是否启用文件日志
static var enable_file_logging: bool = false
static var log_file_path: String = "user://logs/game.log"

# 日志级别名称
static var level_names: Dictionary = {
    LogLevel.DEBUG: "DEBUG",
    LogLevel.INFO: "INFO",
    LogLevel.WARNING: "WARNING",
    LogLevel.ERROR: "ERROR",
    LogLevel.FATAL: "FATAL"
}

## 设置日志级别
static func set_level(level: LogLevel) -> void:
    current_level = level

## 调试日志
static func debug(message: String, context: String = "") -> void:
    _log(LogLevel.DEBUG, message, context)

## 信息日志
static func info(message: String, context: String = "") -> void:
    _log(LogLevel.INFO, message, context)

## 警告日志
static func warning(message: String, context: String = "") -> void:
    _log(LogLevel.WARNING, message, context)

## 错误日志
static func error(message: String, context: String = "") -> void:
    _log(LogLevel.ERROR, message, context)

## 致命错误日志
static func fatal(message: String, context: String = "") -> void:
    _log(LogLevel.FATAL, message, context)

## 内部日志函数
static func _log(level: LogLevel, message: String, context: String) -> void:
    if level < current_level:
        return
    
    var timestamp = Time.get_datetime_string_from_system()
    var level_name = level_names[level]
    var context_str = "[%s] " % context if context != "" else ""
    var formatted_message = "[%s] [%s] %s%s" % [timestamp, level_name, context_str, message]
    
    # 输出到控制台
    match level:
        LogLevel.DEBUG, LogLevel.INFO:
            print(formatted_message)
        LogLevel.WARNING:
            push_warning(formatted_message)
        LogLevel.ERROR, LogLevel.FATAL:
            push_error(formatted_message)
    
    # 输出到文件
    if enable_file_logging:
        _write_to_file(formatted_message)

## 写入文件
static func _write_to_file(message: String) -> void:
    var file = FileAccess.open(log_file_path, FileAccess.WRITE_READ)
    if file:
        file.seek_end()
        file.store_line(message)
        file.close()
