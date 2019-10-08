extends Node
class_name IrcClientSecure

signal response_recieved(response)
signal http_response_recieved(type, response)
signal http_response_failed(error_code)

export(float) var CONNECT_WAIT_TIMEOUT = 2.0
export(float) var COMMAND_WAIT_TIMEOUT = 0.3

onready var __websocket_client = WebSocketClient.new()
onready var command_queue := Array()


var http_request_queue: HttpRequestQueue
var __websocket_peer: WebSocketPeer

var processing = false

var _host: String
var _port: int

var __time_passed := 0.0
var __last_command_time := 0.0
var connection_status: int = -1

var __log := false


# public
func set_logging(state: bool) -> void:
    __log = state

func connect_to_host(host: String, port: int) -> bool:
    _host = host
    _port = port

    __websocket_client.set_verify_ssl_enabled(false)

    var result: int = __websocket_client.connect_to_url(str(_host, ':', _port))

    __websocket_peer = __websocket_client.get_peer(1)
    __websocket_peer.set_write_mode(WebSocketPeer.WRITE_MODE_TEXT)

    set_process(true)

    return result == OK

func send_command(command: String) -> void:
    command_queue.append(command)


# private
func _log(text: String) -> void:
    if __log:
        prints('[%s] %s' % [__get_time_str(), text])

func __get_time_str() -> String:
    var time = OS.get_time()
    return str(time.hour, ':', time.minute, ':', time.second)

func __send_command(command: String) -> int:
    var result: int = __websocket_peer.put_packet(command.to_utf8())

    return result

func __process_commands() -> void:
    var next_command_time: bool = __time_passed - __last_command_time >= COMMAND_WAIT_TIMEOUT

    if command_queue.empty() or not next_command_time:
        return

    __send_command(command_queue.pop_front() as String)

    __last_command_time = __time_passed

func __process_incoming_data() -> void:
    var available_packets_count := __websocket_peer.get_available_packet_count()

    var recieved_string: String = ''
    while available_packets_count > 0:
        var packet = __websocket_peer.get_packet()
        recieved_string += packet.get_string_from_utf8()

        available_packets_count -= 1

    if recieved_string:
        _log('>> %s' % recieved_string)

    emit_signal('response_recieved', recieved_string)

func __parse_server_message(data):
    pass

func __initialize_http_request_queue() -> void:
    http_request_queue = HttpRequestQueue.new()
    add_child(http_request_queue)


# hooks
func _ready() -> void:
    set_process(false)

    __initialize_http_request_queue()

func _process(delta: float) -> void:
    __time_passed += delta

    if __websocket_client.get_connection_status() != connection_status:
        connection_status = __websocket_client.get_connection_status()

        if connection_status == WebSocketClient.CONNECTION_CONNECTING:
            _log('Connecting to server...')

        if connection_status == WebSocketClient.CONNECTION_CONNECTED:
            _log('Connected.')

        if connection_status == WebSocketClient.CONNECTION_DISCONNECTED:
            _log('Disconnected.')

    var is_connecting: bool = connection_status == WebSocketClient.CONNECTION_CONNECTING
    var is_connected: bool = connection_status == WebSocketClient.CONNECTION_CONNECTED

    if is_connecting or is_connected:
        __websocket_client.poll()

        var is_peer_connected: bool = __websocket_peer.is_connected_to_host()

        if is_peer_connected and __time_passed > CONNECT_WAIT_TIMEOUT:
            __process_commands()

            __process_incoming_data()


# events
func _on_http_response_recieved(content_type: String, data: PoolByteArray) -> void:
    emit_signal("http_response_recieved", content_type, data)

func _on_http_response_failed(error_code: int) -> void:
    emit_signal("http_response_failed", error_code)
