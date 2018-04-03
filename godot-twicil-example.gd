extends Node2D

export(bool) var animate = true
export(float) var animations_time = 1.0

onready var twicil = get_node("TwiCIL")
onready var sprite = get_node("Sprite")
onready var tween = get_node("Tween")

const NICK = "BOT_NICK"
const CLIENT_ID = "YOUR_CLIENT_ID"
const CHANNEL = "YOUR_CHANNEL"	# Your channel name LOWER CASE
const OAUTH = "BOT_OAUTH"

# Private methods
func __interpolate_method(obj, method, start_value, end_value, time):
	tween.stop_all()
	tween.interpolate_method(
		obj, method,
		start_value, end_value, time,
		Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
	tween.start()

func _command_move_to(params):
	var x = float(params[1])
	var y = float(params[2])

	if not animate:
		sprite.set_global_position(Vector2(x, y))
		return

	__interpolate_method(
		sprite, 'set_global_position',
		sprite.get_global_position(), Vector2(x, y), animations_time)

func _command_rotate(degrees):

	if not animate:
		sprite.set_rotation_degrees(float(degrees[1]))
		return

	__interpolate_method(
		sprite, 'set_rotation_degrees',
		sprite.get_rotation_degrees(), float(degrees[1]), animations_time)

func _command_scale(params):
	var scale_x = float(params[1]) if params.size() > 1 else 1
	var scale_y = float(params[2]) if params.size() > 2 else 1

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

func send_greating_help():
	twicil.send_message(
		"Hi, Chat! You can use the following commands now: " +
		"move [x] [y] - to move; rotate [degrees] - to rotate; " +
		"scale [no_params] or [x] [y] - to scale (to 1 1 without params)")

func init_interactive_commands():
	twicil.commands.add("move", self, "_command_move_to", 2)
	twicil.commands.add("rotate", self, "_command_rotate")
	twicil.commands.add("scale", self, "_command_scale", 2, true)

# Hooks
func _ready():
	init_interactive_commands()
	twicil.set_logging(true)
	connect()
	send_greating_help()

