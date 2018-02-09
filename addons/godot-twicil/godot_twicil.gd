extends './helpers/irc_client_ex.gd'

signal raw_response_recieved(response)
signal message_recieved(sender, text)

enum Commands {PING, PRIVMSG}

const TWITCH_IRC_CHAT_HOST = 'irc.chat.twitch.tv'
const TWITCH_IRC_CHAT_PORT = 6667

const CONNECT_WAIT_TIMEOUT = 1
const COMMAND_WAIT_TIMEOUT = 1.5

const MessageWrapper = preload('./helpers/message_wrapper.gd')
const TwitchIrcServerMessage = preload('./helpers/twitch_irc_server_message.gd')

onready var tools = preload('./helpers/tools.gd').new()

var commands = {
	Commands.PING: 'PING',
	Commands.PRIVMSG: 'PRIVMSG'
}

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

# Private methods
func __connect_signals():
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

		if single_response.command == commands[Commands.PING]:
			.send_command(str('PONG ', single_response.params[0]))
		elif single_response.command == commands[Commands.PRIVMSG]:
			var chat_message = MessageWrapper.wrap(single_response)
			# prints(chat_message.name, '::', chat_message.text)

			emit_signal("message_recieved", chat_message.name, chat_message.text)
