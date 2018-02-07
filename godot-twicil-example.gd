extends Node2D

export(bool) var animate = true
export(float) var animations_time = 1.0

class FuncRefEx extends FuncRef:
	func _init(instance, method):
		.set_instance(instance)
		.set_function(method)

class InteractiveCommand:
	var func_ref
	var params_count

	func _init(func_ref, params_count):
		self.func_ref = func_ref
		self.params_count = params_count

	func call_command(params):
		func_ref.call_func(params)

onready var twicil = get_node("TwiCIL")
onready var sprite = get_node("Sprite")
onready var tween = get_node("Tween")

const NICK = "YOUR_NICK"
const CLIENT_ID = "YOUR_CLIENT_ID"
const CHANNEL = "your_channel"	# Your channel name IN LOWER CASE
const OAUTH = "oauth:YOUR_OAUTH"

var interactive_commands = {
	'move': InteractiveCommand.new(
		FuncRefEx.new(self, '_command_move_to'), 2),
	'rotate': InteractiveCommand.new(
		FuncRefEx.new(self, '_command_rotate'), 1),
	'scale': InteractiveCommand.new(
		FuncRefEx.new(self, '_command_scale'), 2)
}

# Private methods
func __interpolate_method(obj, method, start_value, end_value, time):
	tween.stop_all()
	tween.interpolate_method(
		obj, method,
		start_value, end_value, time,
		Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
	tween.start()


func _command_move_to(params):
	var x = float(params[0])
	var y = float(params[1])

	if not animate:
		sprite.set_global_pos(Vector2(x, y))
		return

	__interpolate_method(
		sprite, 'set_global_pos',
		sprite.get_global_pos(), Vector2(x, y), animations_time)


func _command_rotate(degrees):

	if not animate:
		sprite.set_rotd(float(degrees[0]))
		return

	__interpolate_method(
		sprite, 'set_rotd',
		sprite.get_rotd(), float(degrees[0]), animations_time)


func _command_scale(params):
	var scale_x = float(params[0])
	var scale_y = float(params[1])

	if not animate:
		sprite.set_scale(Vector2(scale_x, scale_y))
		return

	__interpolate_method(
		sprite, 'set_scale',
		sprite.get_scale(), Vector2(scale_x, scale_y), animations_time)


# Public methods
func connect():
	twicil.connect_to_twitch_chat()
	twicil.connect_to_channel(CHANNEL, CLIENT_ID, OAUTH, NICK)

# Hooks
func _ready():
	twicil.connect("message_recieved", self, "_on_message_recieved")
	twicil.set_logging(true)
	connect()

# Events
func _on_message_recieved(sender, text):
	var input_cmd = text.split(' ')

	for cmd in interactive_commands:
		if input_cmd[0] == cmd:

			if input_cmd.size() - 1 < interactive_commands[cmd].params_count:
				# TODO: React to invalid command params in chat
				return

			var params = []
			for i in range(interactive_commands[cmd].params_count):
				params.append(input_cmd[i + 1])

			interactive_commands[cmd].call_command(params)
