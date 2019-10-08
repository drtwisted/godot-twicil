class_name ChatList


var __list := Dictionary()

func add_user(name: String) -> void:
    if name in __list:
        return

    __list[name] = ChatUser.new(name)

func remove_user(name: String) -> void:
    if name in __list:
        __list.erase(name)

func get_user_details(name: String) -> ChatUser:
    if name in __list:
        return __list[name] as ChatUser

    return null

func get_names() -> Array:
    return __list.keys()

func size() -> int:
    return __list.size()

func clear() -> void:
    __list.clear()

func has(name: String) -> bool:
    return name in __list
