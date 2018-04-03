class FuncRefEx extends FuncRef:
	func _init(instance, method):
		.set_instance(instance)
		.set_function(method)

class InteractiveCommand:
	var func_ref
	var params_count
	var variable_params_count

	func _init(func_ref, params_count, variable_params_count=false):
		self.func_ref = func_ref
		self.params_count = params_count
		self.variable_params_count = variable_params_count

	func call_command(params):
		func_ref.call_func(params)

var interactive_commands = {}

# Public methods
func add(
	chat_command, target, method_name, params_count=1, variable_params_count=false):
	interactive_commands[chat_command] = InteractiveCommand.new(
		FuncRefEx.new(target, method_name), params_count, variable_params_count)

func remove(chat_command):
	if interactive_commands.has(chat_command):
		interactive_commands.erase(chat_command)

# Events
func _on_message_recieved(sender, text):
	var input_cmd = text.split(' ')

	for cmd in interactive_commands:
		if input_cmd[0] == cmd:

			if not interactive_commands[cmd].variable_params_count \
			and input_cmd.size() - 1 < interactive_commands[cmd].params_count:
				# TODO: React to invalid command params in chat
				return

			var params = [sender]
			var params_count = clamp(
				input_cmd.size() - 1, 0, interactive_commands[cmd].params_count)

			if params_count >= 1:
				for i in range(params_count):
					params.append(input_cmd[i + 1])

			interactive_commands[cmd].call_command(params)