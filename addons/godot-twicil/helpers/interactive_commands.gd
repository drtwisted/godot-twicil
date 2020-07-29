class_name InteractiveCommands


class FuncRefEx extends FuncRef:
	func _init(instance: Object, method: String):
		.set_instance(instance)
		.set_function(method)

class InteractiveCommand:
	var func_ref: FuncRef
	var params_count: int
	var variable_params_count: int

	func _init(func_ref: FuncRef, params_count: int, variable_params_count: bool=false):
		self.func_ref = func_ref
		self.params_count = params_count
		self.variable_params_count = variable_params_count

	func call_command(params: Array) -> void:
		func_ref.call_func(params)

var interactive_commands = {}

# Public methods
func add(
	chat_command: String,
	target: Object,
	method_name: String,
	params_count: int=1,
	variable_params_count: bool=false
) -> void:
	interactive_commands[chat_command] = InteractiveCommand.new(
		FuncRefEx.new(target, method_name) as FuncRef, params_count, variable_params_count)

func add_aliases(chat_command: String, new_aliases: Array) -> void:
	if interactive_commands.has(chat_command):
		for new_alias in new_aliases:
			interactive_commands[new_alias] = interactive_commands[chat_command]

func remove(chat_command: String) -> void:
	if interactive_commands.has(chat_command):
		interactive_commands[chat_command]
		interactive_commands.erase(chat_command)

# Events
func _on_message_recieved(sender: String, text: String, emotes: Array, attrs: Dictionary) -> void:
	var input_cmd: Array = text.split(' ')

	for cmd in interactive_commands:
		if input_cmd[0] == cmd:

			if not interactive_commands[cmd].variable_params_count \
			and input_cmd.size() - 1 < interactive_commands[cmd].params_count:
				# TODO: React to invalid command params in chat
				return

			var params: Array = [sender]
			var params_count: int = clamp(
				input_cmd.size() - 1,
				0,
				interactive_commands[cmd].params_count
			)

			if params_count >= 1:
				for i in range(params_count):
					params.append(input_cmd[i + 1])

			params.append(attrs)

			interactive_commands[cmd].call_command(params)
