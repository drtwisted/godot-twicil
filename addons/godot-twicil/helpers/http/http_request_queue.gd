extends Node
class_name HttpRequestQueue


signal http_response_recieved(content_type, body)
signal http_response_failed(error_code)
signal request_completed(id, result, response_code, headers, body)
signal request_completed_ex(id, result, response_code, http_headers, body)


const REQUEST_ID_NO_ID = '{no_id}'


var _http_request: HTTPRequest
var request_queue = Array()
var busy = false
var current_request_id: String = REQUEST_ID_NO_ID

# hooks
func _ready() -> void:
    __initialize_http_request()

# public
func enqueue_request(id: String, url: String, headers: PoolStringArray=PoolStringArray()) -> void:
    request_queue.append({'id': id, 'url': url, 'headers': headers})

    if not busy:
        __process_request_queue()

# private
func __initialize_http_request() -> void:
    _http_request = HTTPRequest.new()

    add_child(_http_request)

    _http_request.use_threads = true

    _http_request.connect("request_completed", self, "_on_http_request_completed")

# private
func __process_request_queue() -> void:
    if request_queue.empty():
        busy = false

        return

    if busy:
        return

    busy = true

    var request_data := request_queue.pop_front() as Dictionary
    var request_url: String = request_data.get('url')
    var request_headers: PoolStringArray = request_data.get('headers')
    current_request_id = request_data.get('id')

    _http_request.request(request_url, request_headers)


# events
func _on_http_request_completed(result: int, response_code: int, headers: PoolStringArray, body: PoolByteArray) -> void:
    var http_headers := HttpHeaders.new(headers)
    emit_signal("request_completed", current_request_id, result, response_code, headers, body)
    emit_signal("request_completed_ex", current_request_id, result, response_code, http_headers, body)

    if result == HTTPRequest.RESULT_SUCCESS:

        var content_type := http_headers.get('Content-Type') as String

        emit_signal("http_response_recieved", content_type, body)

    else:
        emit_signal("http_response_failed", response_code)

    current_request_id = REQUEST_ID_NO_ID
    busy = false

    __process_request_queue()
