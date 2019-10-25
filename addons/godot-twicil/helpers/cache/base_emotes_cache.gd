extends Node
class_name BaseEmotesCache

signal downloaded(content)

var http_request_queue: HttpRequestQueue
var ready_to_deliver_emotes := false

class DownloadedContent:
    const CONTENT_TYPE_IMAGE_PNG = 'image/png'
    const CONTENT_TYPE_IMAGE_JPEG = 'image/jpeg'


    var id: String
    var type: String
    var data: PoolByteArray
    var image: Image


    func _init(id: String, type: String, data: PoolByteArray):
        self.id = id
        self.type = type
        self.data = data

    func get_image_from_data() -> Image:
        var image: Image = Image.new()

        if self.type == CONTENT_TYPE_IMAGE_PNG:
            image.load_png_from_buffer(data)

        elif self.type == CONTENT_TYPE_IMAGE_JPEG:
            image.load_jpg_from_buffer(data)

        return image


class BaseEmote:
    const TEXTURE_NO_FLAGS = 0

    static func create_texture_from_image(image: Image) -> ImageTexture:
        var image_texture := ImageTexture.new()
        image_texture.create_from_image(image)
        image_texture.flags -= ImageTexture.FLAG_FILTER + ImageTexture.FLAG_REPEAT

        return image_texture


# hooks
func _ready() -> void:
    __initialize()
    __initialize_http_request_queue()
    __connect_signals()

func _downloaded(downloaded_content: BaseEmotesCache.DownloadedContent) -> void:
    """
    Override to define behaviour on emote content downloaded.
    """
    pass

func _get_emote_url(code: String) -> String:
    """
    Override to prepare the emote retrieval URL by code.
    """
    return ''

# private
func __initialize() -> void:
    """
    Override for initialization, instead of _ready.
    """
    pass

func __connect_signals() -> void:
    http_request_queue.connect("request_completed", self, "_on_http_request_queue_request_complete")

func __initialize_http_request_queue() -> void:
    http_request_queue = HttpRequestQueue.new()

    add_child(http_request_queue)

func __cache_emote(code) -> void:
    var url: String = _get_emote_url(code)

    __download(code, url)

func __download(id: String, url: String) -> void:
    http_request_queue.enqueue_request(id, url)


# events
func _on_http_request_queue_request_complete(id: String, result: int, response_code: int, headers: PoolStringArray, body: PoolByteArray) -> void:
    var downloaded_content := DownloadedContent.new(id, '', body)

    if result == HTTPRequest.RESULT_SUCCESS:
        var pretty_headers := HttpHeaders.new(headers)
        var content_type := pretty_headers.headers.get('Content-Type') as String

        downloaded_content.type = content_type

    # TODO: Convert the image by it's conntent type right away!

    _downloaded(downloaded_content)
