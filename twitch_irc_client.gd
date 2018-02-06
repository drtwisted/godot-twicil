extends Node

#const HOST = "irc.twitch.tv"
const HOST = "irc.chat.twitch.tv"
#const HOST = "irc.freenode.net"
#const HOST = "127.0.0.1"
const PORT = 6667
#const PORT = 8000


const NICK = "TwistyBot"
const CLIENT_ID = "vbqsda2v8nryieli4m3r5eh2c125ei"
const REALNAME = "TwistyBot"
#const MASTER = "Dr_TwiSteD"
const CHANNEL = "dr_twisted"
const OAUTH = "oauth:8ycqc3x2jb185d1dlw5r8py0wmfhkl"

const connect_timeout = 3

onready var client = get_node("IrcClient")


var time_passed = 0
#onready var client = preload('irc_client.gd').new()

# Private methods

# Public methods
func connect():
	client.connect_to_host(HOST, PORT)

	client.connect_to_channel(CHANNEL, NICK, REALNAME, OAUTH, CLIENT_ID, HOST)

#	client.send_command('PASS %s' % OAUTH)
#
#	client.send_command('NICK ' +  NICK)
#
#	client.send_command(str('USER ', CLIENT_ID, ' ', HOST, ' bla:', REALNAME))
#	client.send_command('JOIN #' + CHANNEL)
#
#	# TODO: Move to a child class
#	client.send_command("CAP REQ :twitch.tv/tags twitch.tv/commands twitch.tv/membership")
#
#	client.send_command(str('PRIVMSG #', CHANNEL, ' : HI ALL GUYS!'))

#	client.set_process(true)
#	if not client.is_connected():
#		return -1

#	client.connect_to_channel(CHANNEL, NICK, REALNAME, CLIENT_ID, OAUTH)
#	return 0

# Hooks
func _ready():
	connect()
#	set_process(true)

func _process(delta):

	time_passed += delta
	if time_passed < connect_timeout:
		return

	if not client.is_client_connected():
		return

	client.connect_to_channel(CHANNEL, NICK, REALNAME, CLIENT_ID, OAUTH)
	set_process(false)