extends Node

signal response_recieved(response)

export(float) var CONNECT_WAIT_TIMEOUT = 1
export(float) var COMMAND_WAIT_TIMEOUT = 0.3

onready var __stream_peer = StreamPeerTCP.new()
onready var queue = preload('queue.gd').new()
#onready var processing_thread = Thread.new()

var processing = false

var _host
var _port

var __time_passed = 0
var __last_command_time = 0

var __log = false

# Public methods
func set_logging(state):
	__log = state

func connect_to_host(host, port):
	_host = host
	_port = port

	prints('Connected')

	__stream_peer.connect(_host, _port)

func send_command(command):
	queue.append(command)

func abort_processing():
	processing = false

# Private methods
func _log(text):
	if __log:
		prints('[%s] %s' % [__get_time_str(), text])

func __get_time_str():
	var time = OS.get_time()
	return str(time.hour, ':', time.minute, ':', time.second)

func __send_command(command):
	var chunck_size = 8
	var chuncks_count = command.length() / chunck_size
	var appendix_length = command.length() % chunck_size

	_log('<< %s' % command)

	for i in range(chuncks_count):
		__stream_peer.put_data((command.substr(i * chunck_size, chunck_size)).to_utf8())

	if appendix_length > 0:
		__stream_peer.put_data((command.substr(
			chunck_size * chuncks_count, appendix_length)).to_utf8())

	__stream_peer.put_data(('\r\n').to_utf8())

func __process():
	while processing:
		__process_commands()
		__process_input()

func __process_commands():
	if queue.is_empty() or \
	__time_passed - __last_command_time < COMMAND_WAIT_TIMEOUT:
		return

	__send_command(queue.pop_next())

	__last_command_time = __time_passed

func __process_input():
	var bytes_available = __stream_peer.get_available_bytes()

	if not (__stream_peer.is_connected() and bytes_available > 0):
		return

	var data = __stream_peer.get_utf8_string(bytes_available)

	_log('>> %s' % data)

	emit_signal('response_recieved', data)

func __parse_server_message(data):
	pass

# Hooks
func _ready():
	set_process(true)
#	processing_thread.start(self, "__process")

func _process(delta):
	__time_passed += delta

	processing = __time_passed > CONNECT_WAIT_TIMEOUT

	if not processing:
		return


	__process_commands()

	__process_input()