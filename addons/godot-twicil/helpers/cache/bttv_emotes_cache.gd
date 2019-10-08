extends BaseEmotesCache
class_name BttvEmotesCache


signal emote_retrieved(emote)


class BttvEmote:
    var id: String
    var code: String
    var texture: ImageTexture

    func _init(id: String, code: String, image: Image):
        self.id = id
        self.code = code
        self.texture = BaseEmotesCache.BaseEmote.create_texture_from_image(image)


const DEFAULT_URL_PROTOCOL = 'https://'
const CHANNEL_NAME_PLACEHOLDER = '{{channel_name}}'
const EMOTE_ID_PLACEHOLDER = '{{id}}'
const EMOTE_SIZE_PLACEHOLDER = '{{image}}'

# Can be: 1x, 2x, 3x
const DEAFULT_EMOTE_IMAGE_SIZE = '1x'

const GLOBAL_EMOTES_REQUEST_ID = 'global_emotes'
const CHANNEL_EMOTES_REQUEST_ID = 'channel_emotes'
const EMOTES_REQUEST_IDS = [GLOBAL_EMOTES_REQUEST_ID, CHANNEL_EMOTES_REQUEST_ID]

const GLOBAL_EMOTES_URL = 'https://api.betterttv.net/2/emotes/'
const CHANNEL_EMOTES_URL_TEMPLATE = 'https://api.betterttv.net/2/channels/{{channel_name}}/'


# {
#    "code": "id"
# }
# code -- text to replace
# id -- internal bttv emote id
var available_emotes := Dictionary()
var emote_download_url_template: String
var cache := Dictionary()
var available_emotes_parsed_count := 0

# hooks
func _downloaded(downloaded_content: BaseEmotesCache.DownloadedContent) -> void:
    if downloaded_content.id in EMOTES_REQUEST_IDS:
        __parse_available_emotes(downloaded_content)

        available_emotes_parsed_count += 1
        ready_to_deliver_emotes = available_emotes_parsed_count >= EMOTES_REQUEST_IDS.size()

    else:
        var code: String = str(downloaded_content.id)
        var id: String = available_emotes.get(code)
        var image: Image = downloaded_content.get_image_from_data()

        cache[code] = BttvEmote.new(id, code, image)

        emit_signal("emote_retrieved", cache.get(code))

func _get_emote_url(code: String) -> String:
    var id: String = available_emotes.get(code)

    if not id:
        return ''

    var url := emote_download_url_template.replace(
        EMOTE_ID_PLACEHOLDER, id
    ).replace(
        EMOTE_SIZE_PLACEHOLDER, DEAFULT_EMOTE_IMAGE_SIZE
    )

    return url

# public
func init_emotes(channel_name: String) -> void:
    http_request_queue.enqueue_request(GLOBAL_EMOTES_REQUEST_ID, GLOBAL_EMOTES_URL)
    http_request_queue.enqueue_request(
        CHANNEL_EMOTES_REQUEST_ID,
        CHANNEL_EMOTES_URL_TEMPLATE.replace(CHANNEL_NAME_PLACEHOLDER, channel_name)
    )

# public
func get_emote(code: String) -> void:
    if not ready_to_deliver_emotes:
        return

    if cache.has(code):
        emit_signal("emote_retrieved", cache.get(code))

    else:
        __cache_emote(code)

func get_available_emotes_codes() -> Array:
    return available_emotes.keys()

# private



# private
func __parse_available_emotes(download_content: BaseEmotesCache.DownloadedContent) -> void:
    if download_content.type != HttpHeaders.HTTP_CONTENT_TYPE_JSON_UTF8:
        return

    var data = parse_json(download_content.data.get_string_from_utf8())

    emote_download_url_template = data.get('urlTemplate', '').replace('//', DEFAULT_URL_PROTOCOL)

    for emote in data.get('emotes', []):
        available_emotes[emote.get('code')] = emote.get('id')
