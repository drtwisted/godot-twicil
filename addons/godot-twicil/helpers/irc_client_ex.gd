extends Node
class_name IrcClientEx

signal response_recieved(response)
signal http_response_recieved(type, response)
signal http_response_failed(error_code)

export(float) var CONNECT_WAIT_TIMEOUT = 1
export(float) var COMMAND_WAIT_TIMEOUT = 0.3

onready var __stream_peer = StreamPeerTCP.new()
onready var queue := Queue.new()


var http_request_queue: HttpRequestQueue

#onready var processing_thread = Thread.new()

var processing = false

var _host: String
var _port: int

var __time_passed := 0.0
var __last_command_time := 0.0

var __log := false


# public
func set_logging(state: bool) -> void:
    __log = state

func connect_to_host(host: String, port: int) -> bool:
    _host = host
    _port = port

    return __stream_peer.connect_to_host(_host, _port) == OK

func send_command(command: String) -> void:
    queue.append(command)

func abort_processing() -> void:
    processing = false


# private
func _log(text: String) -> void:
    if __log:
        prints('[%s] %s' % [__get_time_str(), text])

func __get_time_str() -> String:
    var time = OS.get_time()
    return str(time.hour, ':', time.minute, ':', time.second)

func __send_command(command: String) -> void:
    var command_chunck_bytes := PoolByteArray()
    var chunck_size := 8
    var chuncks_count: int = command.length() / chunck_size
    var appendix_length: int = command.length() % chunck_size

    _log('<< %s' % command)


    for i in range(chuncks_count):
        command_chunck_bytes = command.substr(i * chunck_size, chunck_size).to_utf8()
        __stream_peer.put_data(command_chunck_bytes)

    if appendix_length > 0:
        command_chunck_bytes = command.substr(chunck_size * chuncks_count, appendix_length).to_utf8()
        __stream_peer.put_data(command_chunck_bytes)

    command_chunck_bytes = ('\r\n').to_utf8()
    __stream_peer.put_data(command_chunck_bytes)

func __process() -> void:
    while processing:
        __process_commands()
        __process_input()

func __process_commands() -> void:
    if queue.is_empty() or \
    __time_passed - __last_command_time < COMMAND_WAIT_TIMEOUT:
        return

    __send_command(queue.pop_next() as String)

    __last_command_time = __time_passed

func __process_input() -> void:
    var bytes_available: int = __stream_peer.get_available_bytes()

    if not (__stream_peer.is_connected_to_host() and bytes_available > 0):
        return

    var data := __stream_peer.get_utf8_string(bytes_available) as String

    _log('>> %s' % data)

    emit_signal('response_recieved', data)

func __parse_server_message(data):
    pass

func __initialize_http_request_queue() -> void:
    http_request_queue = HttpRequestQueue.new()
    add_child(http_request_queue)

#    http_request_queue.connect("http_response_recieved", self, "_on_http_response_recieved")


# hooks
func _ready() -> void:
    set_process(true)

    __initialize_http_request_queue()

#	processing_thread.start(self, "__process")

func _process(delta: float) -> void:
    __time_passed += delta

    processing = __time_passed > CONNECT_WAIT_TIMEOUT

    if not processing:
        return

    __process_commands()

    __process_input()


# events
func _on_http_response_recieved(content_type: String, data: PoolByteArray) -> void:
    emit_signal("http_response_recieved", content_type, data)

func _on_http_response_failed(error_code: int) -> void:
    emit_signal("http_response_failed", error_code)
