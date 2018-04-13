const ChatUser = preload("./chat_user.gd")

var __list = {}

func add_user(name):
	if name in __list:
		return
		
	__list[name] = ChatUser.new(name)

func remove_user(name):
	if name in __list:
		__list.erase(name)

func get_user_details(name):
	if name in __list:
		return __list[name]

func get_names():
	return __list.keys()

func size():
	return __list.size()

func clear():
	__list = {}

func has(name):
	return name in __list