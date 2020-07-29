extends IrcClientSecure
class_name TwiCIL

signal raw_response_recieved(response)
signal user_appeared(user)
signal user_disappeared(user)
signal message_recieved(sender, text, emotes, attr)

signal emote_recieved(user, emote_reference)

signal texture_recieved(texture)

enum IRCCommands {PING, PONG, PRIVMSG, JOIN, PART, NAMES}

const TWITCH_IRC_CHAT_HOST = 'wss://irc-ws.chat.twitch.tv'
const TWITCH_IRC_CHAT_PORT = 443

#const CONNECT_WAIT_TIMEOUT = 1
#const COMMAND_WAIT_TIMEOUT = 1.5


onready var tools = HelperTools.new()
onready var commands = InteractiveCommands.new()
onready var chat_list = ChatList.new()


var twitch_emotes_cache: TwitchEmotesCache
var bttv_emotes_cache: BttvEmotesCache
var ffz_emotes_cache: FfzEmotesCache

var twitch_api_wrapper: TwitchApiWrapper

var irc_commands = {
    IRCCommands.PING: 'PING',
    IRCCommands.PONG: 'PONG',
    IRCCommands.PRIVMSG: 'PRIVMSG',
    IRCCommands.JOIN: 'JOIN',
    IRCCommands.PART: 'PART',
    IRCCommands.NAMES: '/NAMES'
}

var curr_channel = ""

#{
#     "emote_id": ["user_name#1", "user_name#2", ...]
#    ...
#}
var user_emotes_queue := Dictionary()


# Public methods
func connect_to_twitch_chat():
	.connect_to_host(TWITCH_IRC_CHAT_HOST, TWITCH_IRC_CHAT_PORT)

func connect_to_channel(channel, client_id, password, nickname, realname=''):
	_connect_to(
		channel,
		nickname,
		nickname if realname == '' else realname,
		password,
		client_id
	)

	bttv_emotes_cache.init_emotes(curr_channel)

	twitch_api_wrapper.set_credentials(client_id, password)

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

func request_twitch_emote(user_name: String, id: int) -> void:
	if not user_emotes_queue.has(id):
		user_emotes_queue[id] = []

	user_emotes_queue[id].append(user_name)

	twitch_emotes_cache.get_emote(id)

func request_bttv_emote(user_name: String, code: String) -> void:
	var id: String = bttv_emotes_cache.available_emotes.get(code)

	if not user_emotes_queue.has(id):
		user_emotes_queue[id] = []

	user_emotes_queue[id].append(user_name)

	bttv_emotes_cache.get_emote(code)

func request_ffz_emote(user_name: String, code: String) -> void:
	var id: String = ffz_emotes_cache.available_emotes.get(code, {}).get('id', '')

	if not user_emotes_queue.has(id):
		user_emotes_queue[id] = []

	user_emotes_queue[id].append(user_name)

	ffz_emotes_cache.get_emote(code)

func request_emote_from(emotes: Array, user_name: String, index: int) -> void:
	if emotes.empty():
		return

	var emote = emotes[index]

	if emote.get('type') == TwitchMessage.EmoteType.TWITCH:
		var emote_id := int(emote.get('id'))
		request_twitch_emote(user_name, emote_id)

	elif emote.get('type') == TwitchMessage.EmoteType.BTTV:
		var emote_code := emote.get('code') as String
		request_bttv_emote(user_name, emote_code)

	elif emote.get('type') == TwitchMessage.EmoteType.FFZ:
		var emote_code := emote.get('code') as String
		request_ffz_emote(user_name, emote_code)

# Private methods
func __init_emotes_caches() -> void:
	twitch_emotes_cache = TwitchEmotesCache.new()
	add_child(twitch_emotes_cache)

	bttv_emotes_cache = BttvEmotesCache.new()
	add_child(bttv_emotes_cache)

	ffz_emotes_cache = FfzEmotesCache.new()
	add_child(ffz_emotes_cache)

func __init_twitch_api() -> void:
	twitch_api_wrapper = TwitchApiWrapper.new(http_request_queue, '')

func __connect_signals():
	connect("message_recieved", commands, "_on_message_recieved")
	connect("response_recieved", self, "_on_response_recieved")
	connect("http_response_recieved", self, "_on_http_response_recieved")

	twitch_emotes_cache.connect("emote_retrieved", self, "_on_emote_retrieved")
	bttv_emotes_cache.connect("emote_retrieved", self, "_on_emote_retrieved")
	ffz_emotes_cache.connect("emote_retrieved", self, "_on_emote_retrieved")

	twitch_api_wrapper.connect("api_user_info", self, "_on_twitch_api_api_user_info")

func __parse(string: String) -> TwitchIrcServerMessage:
	var args = []
	var twitch_prefix = ''
	var prefix = ''
	var trailing = []
	var command

	if string == null:
		return TwitchIrcServerMessage.new('', '','', [])

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

func __parse_attrs(message_prefix):
	var attrs = {}
	var raw_attrs = message_prefix.split(";")
	for raw_attr in raw_attrs:
		var key_value = raw_attr.split("=")
		var key = key_value[0]
		var value = null
		if key_value.size() > 1:
			value = key_value[1]
		attrs[key] = value
	return attrs

# Hooks
func _ready():
	__init_twitch_api()
	__init_emotes_caches()
	__connect_signals()


# Events
func _on_response_recieved(response):
	emit_signal("raw_response_recieved", response)

	for single_response in response.split('\n', false):
		single_response = __parse(single_response.strip_edges(false))

		# Ping-Pong with server to let it know we're alive
		if single_response.command == irc_commands[IRCCommands.PING]:
			.send_command(str(irc_commands[IRCCommands.PONG], ' ', single_response.params[0]))

		# Message received
		elif single_response.command == irc_commands[IRCCommands.PRIVMSG]:
			var attrs = __parse_attrs(single_response.message_prefix)
			var twitch_message: TwitchMessage = TwitchMessage.new(
				single_response,
				bttv_emotes_cache.available_emotes,
				ffz_emotes_cache.available_emotes,
				attrs
			)

			emit_signal(
				"message_recieved",
				twitch_message.chat_message.name,
				twitch_message.chat_message.text,
				twitch_message.emotes,
				twitch_message.attrs
			)

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

func _on_emote_retrieved(emote_reference: Reference) -> void:
	var emote_id: String = emote_reference.id
	var user: String = (user_emotes_queue.get(emote_id, []) as Array).pop_front()

	emit_signal("emote_recieved", user, emote_reference)

func _on_twitch_api_api_user_info(data):
	var user_id := str(data.get('data', [{}])[0].get('id', 0))

	ffz_emotes_cache.init_emotes(user_id)
