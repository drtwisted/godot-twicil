extends Node2D


const NICK = "BOT_NICK"
const CLIENT_ID = "YOUR_CLIENT_ID"
const CHANNEL = "YOUR_CHANNEL"	# Your channel name LOWER CASE
const OAUTH = "BOT_OAUTH"


export(bool) var animate = true
export(float) var animations_time = 1.0


onready var twicil = get_node("TwiCIL")
onready var sprite = get_node("Sprite")
onready var users_list_label = get_node("lbUsersList")
onready var tween = get_node("Tween")

onready var credentials = TwitchCredentials.new()


# private
func __connect_signals():
    twicil.connect("user_appeared", self, "_on_user_appeared")
    twicil.connect("user_disappeared", self, "_on_user_disappeared")
    twicil.connect("message_recieved", self, "_on_message_recieved")
    twicil.connect("emote_recieved", self, "_on_emote_recieved")

func __interpolate_method(obj, method, start_value, end_value, time):
    tween.stop_all()
    tween.remove_all()
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
        sprite, "set_global_position",
        sprite.get_global_position(), Vector2(x, y), animations_time)

func _command_rotate(degrees):
    if not animate:
        sprite.set_rotation_degrees(float(degrees[1]))
        return

    __interpolate_method(
        sprite, "set_rotation_degrees",
        sprite.get_rotation_degrees(), float(degrees[1]), animations_time)

func _command_scale(params):
    var scale_x = float(params[1]) if params.size() > 1 else 1
    var scale_y = float(params[2]) if params.size() > 2 else 1

    if not animate:
        sprite.set_scale(Vector2(scale_x, scale_y))
        return

    __interpolate_method(
        sprite, "set_scale",
        sprite.get_scale(), Vector2(scale_x, scale_y), animations_time)

func _command_reply(params):
    var sender = params[0]

    twicil.send_message("Hello, " + str(sender))

# public
func connect_():
    twicil.connect_to_twitch_chat()
    twicil.connect_to_channel(CHANNEL, CLIENT_ID, OAUTH, NICK)


func send_greating_help():
    var help_text := """
        Hi, Chat! You can use the following commands now:
        move [x] [y] - to move; rotate [degrees] - to rotate;
        scale [no_params] or [x] [y] - to scale (to 1 1 without params)
    """.replace('\n', '')

    twicil.send_message(help_text)

func init_interactive_commands():
    twicil.commands.add("move", self, "_command_move_to", 2)
    twicil.commands.add("rotate", self, "_command_rotate")
    twicil.commands.add("scale", self, "_command_scale", 2, true)

    twicil.commands.add("hi", self, "_command_reply", 0, true)
    twicil.commands.add_aliases("hi", ["hello", "hi,", "hello,"])


# hooks
func _ready():
    __connect_signals()
    init_interactive_commands()
    twicil.set_logging(true)
    connect_()
    send_greating_help()


# events
func _on_user_appeared(name):
    users_list_label.text += str("\n ", name)

func _on_user_disappeared(name):
    var users_list_text = users_list_label.text

    users_list_text.erase(
        users_list_text.find(str("\n ", name)),
        name.length() + 2)

    users_list_label.text = users_list_text

func _on_message_recieved(user_name: String, text: String, emotes: Array) -> void:
    twicil.request_emote_from(emotes, user_name, 0)

func _on_emote_recieved(user_name: String, emote: Reference) -> void:
    if emote.texture:
        sprite.texture = emote.texture
