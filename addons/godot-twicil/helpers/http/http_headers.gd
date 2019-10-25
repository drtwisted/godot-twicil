extends Object
class_name HttpHeaders

const HTTP_CONTENT_TYPE_JSON_UTF8 = 'application/json; charset=utf-8'
const HTTP_CONTENT_TYPE_JSON = 'application/json'


var headers: Dictionary

func _init(raw_headers: PoolStringArray):
    for raw_header in raw_headers:
        var header_parts := (raw_header as String).split(':', true, 1) as Array
        var header_name := (header_parts[0] as String).lstrip(' ').rstrip(' ')
        var header_value := (header_parts[1] as String).lstrip(' ').rstrip(' ')

        headers[header_name] = header_value

func get(key: String, ignore_case: bool=true) -> String:
    for header_key in headers:
        if header_key.to_lower() == key.to_lower():
            return headers.get(header_key)

    return '{no such header}'

static func to_pool_string_array(headers: Dictionary) -> PoolStringArray:
    var raw_headers: PoolStringArray

    for header in headers:
        var header_value: String = headers.get(header)

        raw_headers.append(header + ': ' + header_value)

    return raw_headers