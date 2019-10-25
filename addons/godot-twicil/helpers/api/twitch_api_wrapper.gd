extends Object
class_name TwitchApiWrapper


signal api_response_recieved(rquest_id, response)
signal api_response_failed(response_code, http_headers)

signal api_user_info(data)


const API_REQUEST_USER_INFO = 'user_info'

const API_URLS = {
    API_REQUEST_USER_INFO: {
        'template': 'https://api.twitch.tv/helix/users?login={{login}}',
        'params': [
            '{{login}}'
        ]
    }
}

var client_id := ''
var oauth := ''
var http_request_queue: HttpRequestQueue


# hooks
func _init(http_request_queue: HttpRequestQueue, client_id: String) -> void:
    self.client_id = client_id
    self.http_request_queue = http_request_queue

    __connect_signals()


# public
func set_credentials(client_id: String, raw_oauth_string: String) -> void:
    self.client_id = client_id
    self.oauth = raw_oauth_string.split(':')[1]

func get_raw_response(request_id: String, url: String):
    var headers: PoolStringArray = [
        'Client-ID: ' + client_id,
        'Authentication: Bearer ' + oauth
    ]

    http_request_queue.enqueue_request(request_id, url, headers)

func get_api_url(url_id: String, params: Array) -> String:
    var url: String
    var url_info: Dictionary = API_URLS.get(url_id, {})
    var url_template: String = url_info.get('template', '')
    var url_params: Array = url_info.get('params', [])

    if params.size() < url_params.size():
        return str('Wrong params count. Expected ', url_params.size(), ' but got ', params.size(), ' instead.')

    url = url_template

    for i in range(url_params.size()):
        url = url.replace(url_params[i], params[i])

    return url

func get_user_info(user_name: String):
    var url: String = get_api_url(API_REQUEST_USER_INFO, [user_name])
    get_raw_response(API_REQUEST_USER_INFO, url)


# private
func __connect_signals() -> void:
    http_request_queue.connect("request_completed_ex", self, "_on_http_request_queue_request_completed")


# events
func _on_http_request_queue_request_completed(id: String, result: int, response_code: int, http_headers: HttpHeaders, body: PoolByteArray) -> void:
    if result == HTTPRequest.RESULT_SUCCESS:
        if http_headers.get('Content-Type') == HttpHeaders.HTTP_CONTENT_TYPE_JSON_UTF8:
            var data = parse_json(body.get_string_from_utf8())

            emit_signal("api_response_recieved", id, data)

            if response_code == 200:
                match id:
                    API_REQUEST_USER_INFO:
                        emit_signal("api_user_info", data)


    emit_signal("api_response_failed", response_code, http_headers)
