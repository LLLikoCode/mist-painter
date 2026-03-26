## Singleton
## 单例模式基类
## 用于创建自动加载的单例节点

class_name Singleton
extends Node

static var _instances: Dictionary = {}

## 获取或创建单例实例
static func get_instance(scene_path: String, script: GDScript) -> Node:
    if _instances.has(scene_path):
        return _instances[scene_path]
    
    var instance = Node.new()
    instance.set_script(script)
    instance.name = script.resource_path.get_file().get_basename()
    
    # 添加到场景树
    Engine.get_main_loop().root.add_child(instance)
    
    _instances[scene_path] = instance
    return instance

## 释放单例实例
static func free_instance(scene_path: String) -> void:
    if _instances.has(scene_path):
        var instance = _instances[scene_path]
        if is_instance_valid(instance):
            instance.queue_free()
        _instances.erase(scene_path)
