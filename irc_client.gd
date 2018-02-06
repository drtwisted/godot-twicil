extends Node

signal connected
signal disconnected
signal new_message(msg)

var _host
var _port

var force_disconnect = false

var input_thread = Thread.new()

onready var __stream_peer = StreamPeerTCP.new()

# Public methods
func connect(host, port):
	_host = host
	_port = port
	__stream_peer.connect(_host, _port)

func disconnect():
	force_disconnect = true

func connect_to_channel(channel, nickname, realname, client_id, password =''):
#	if password != '':
#		send_command('PASS ' + password)

	send_command('PASS %s' % password)

	send_command('NICK ' +  nickname)

	send_command(str('USER ', client_id, ' ', _host, ' bla:', realname))
	send_command('JOIN #' + channel)

	# TODO: Move to a child class
	send_command("CAP REQ :twitch.tv/tags twitch.tv/commands twitch.tv/membership")

	send_command(str('PRIVMSG: #', channel, ': HI ALL GUYS!'))
#	_start_input_processing()
	__process_input()

func send_command(command):
	pass

func is_client_connected():
	return __stream_peer.is_connected()

# Private methods
func __send_command(command, debug=true):
	var chunck_size = 8
	var chuncks_count = command.length() / chunck_size
	var appendix_length = command.length() % chunck_size

	if debug:
		prints('Sending command: ', command)
#		prints('converted: ', (command + '\r\n').to_utf8())

#	__stream_peer.put_data((command).to_utf8())

	for i in range(chuncks_count):
		__stream_peer.put_data((command.substr(i * chunck_size, chunck_size)).to_utf8())

	if appendix_length > 0:
		__stream_peer.put_data(
			(command.substr(chunck_size * chuncks_count, appendix_length)).to_utf8())

	__stream_peer.put_data(('\r\n').to_utf8())

func _start_input_processing():
	input_thread.start(self, '__process_input')

func __process_input():
	var bytes_available = __stream_peer.get_available_bytes()
	if not (__stream_peer.is_connected() and bytes_available > 0):
		return

	print(__stream_peer.get_string(bytes_available))

#	emit_signal("disconnected")

# Hooks
func _process(delta):
	__process_input()