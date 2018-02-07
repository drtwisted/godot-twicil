extends Node

const NICK = "YOUR_NICKNAME"
const CLIENT_ID = "YOUR_NICKNAME"
const CHANNEL = "dr_twisted"	# Your channel name IN LOWER CASE
const OAUTH = "oauth:your_oauth"

onready var client = get_node("IrcClient")
onready var chat = get_node("Chat")

# Private methods

# Public methods
func connect():
	client.connect_to_twitch_chat()
	client.connect_to_channel(CHANNEL, CLIENT_ID, OAUTH, NICK)

# Hooks
func _ready():
	client.connect("message_recieved", self, "_on_message_recieved")
	connect()

# Events
func _on_message_recieved(sender, text):
	chat.add_text(str(sender, '> ', text, '\n'))