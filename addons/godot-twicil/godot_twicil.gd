extends './helpers/irc_client_ex.gd'

signal raw_response_recieved(response)
signal user_appeared(user)
signal user_disappeared(user)
signal message_recieved(sender, text)

enum IRCCommands {PING, PRIVMSG, JOIN, PART, NAMES}

const TWITCH_IRC_CHAT_HOST = 'irc.chat.twitch.tv'
const TWITCH_IRC_CHAT_PORT = 6667

const CONNECT_WAIT_TIMEOUT = 1
const COMMAND_WAIT_TIMEOUT = 1.5

const MessageWrapper = preload('./helpers/message_wrapper.gd')
const TwitchIrcServerMessage = preload('./helpers/twitch_irc_server_message.gd')

onready var tools = preload('./helpers/tools.gd').new()
onready var commands = preload('./helpers/interactive_commands.gd').new()
onready var chat_list = preload('./helpers/chat_list.gd').new()

var irc_commands = {
	IRCCommands.PING: 'PING',
	IRCCommands.PRIVMSG: 'PRIVMSG',
	IRCCommands.JOIN: 'JOIN',
	IRCCommands.PART: 'PART',
	IRCCommands.NAMES: '/NAMES'
}

var curr_channel = ""

# Public methods
func connect_to_twitch_chat():
	.connect_to_host(TWITCH_IRC_CHAT_HOST, TWITCH_IRC_CHAT_PORT)

func connect_to_channel(channel, client_id, password, nickname, realname=''):
	_connect_to(
		channel, nickname, nickname if realname == '' else realname,
		password, client_id)

func _connect_to(channel, nickname, realname, password, client_id):
	.send_command('PASS %s' % password)

	.send_command('NICK ' +  nickname)

	.send_command(str('USER ', client_id, ' ', _host, ' bla:', realname))
	.send_command('JOIN #' + channel)

	.send_command("CAP REQ :twitch.tv/tags twitch.tv/commands twitch.tv/membership")

	curr_channel = channel

func send_message(text):
	.send_command(str('PRIVMSG #', curr_channel, ' :', text))

func send_whisper(recepient, text):
	send_message(str('/w ', recepient, ' ', text))

# Private methods
func __connect_signals():
	connect("message_recieved", commands, "_on_message_recieved")
	connect("response_recieved", self, "_on_response_recieved")

func __parse(string):
	var args = []
	var twitch_prefix = ''
	var prefix = ''
	var trailing = []
	var command

	if string == null:
		return []

	if string.substr(0, 1) == '@':
		var temp = tools.split_string(string.substr(1, string.length() - 1), ' ', 1)
		twitch_prefix = temp[0]
		string = temp[1]

	if string.substr(0, 1) == ':':
		var temp = tools.split_string(string.substr(1, string.length() - 1), ' ', 1)
		prefix = temp[0]
		string = temp[1]

	if string.find(' :') != -1:
		var temp = tools.split_string(string, ' :', 1)
		string = temp[0]
		trailing = temp[1]

		args = tools.split_string(string, [' ', '\t', '\n'])

		args.append(trailing)
	else:
		args = tools.split_string(string, [' ', '\t', '\n'])

	command = args[0]
	args.pop_front()

	return TwitchIrcServerMessage.new(twitch_prefix, prefix, command, args)

# Hooks
func _ready():
	__connect_signals()

# Events
func _on_response_recieved(response):

	emit_signal("raw_response_recieved", response)

	for single_response in response.split('\n', false):
		single_response = __parse(single_response.strip_edges(false))
		
		# Ping-Pong with server to let it know we're alive
		if single_response.command == irc_commands[IRCCommands.PING]:
			.send_command(str('PONG ', single_response.params[0]))
		
		# Message received
		elif single_response.command == irc_commands[IRCCommands.PRIVMSG]:
			var chat_message = MessageWrapper.wrap(single_response)
			emit_signal("message_recieved", chat_message.name, chat_message.text)
		
		elif single_response.command == irc_commands[IRCCommands.JOIN]:
			var user_name = MessageWrapper.get_sender_name(single_response)
			chat_list.add_user(user_name)
			._log(str(user_name, " has joined chat"))
			emit_signal("user_appeared", user_name)
			
		elif single_response.command == irc_commands[IRCCommands.PART]:
			var user_name = MessageWrapper.get_sender_name(single_response)
			chat_list.remove_user(user_name)
			._log(str(user_name, " has left chat"))
			emit_signal("user_disappeared", user_name)
