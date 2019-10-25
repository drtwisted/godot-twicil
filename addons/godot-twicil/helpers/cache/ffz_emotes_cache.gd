extends BaseEmotesCache
class_name FfzEmotesCache


signal emote_retrieved(emote)


class FfzEmote:
    var id: String
    var code: String
    var texture: ImageTexture

    func _init(id: String, code: String, image: Image):
        self.id = id
        self.code = code
        self.texture = BaseEmotesCache.BaseEmote.create_texture_from_image(image)


const DEFAULT_URL_PROTOCOL = 'https://'
const USER_ID_PLACEHOLDER = '{{user_id}}'
const EMOTE_ID_PLACEHOLDER = '{{id}}'
const EMOTE_SIZE_PLACEHOLDER = '{{image}}'

# Can be: 1x, 2x, 3x
const DEAFULT_EMOTE_IMAGE_SIZE = '1x'

const GLOBAL_EMOTES_REQUEST_ID = 'global_emotes'
const CHANNEL_EMOTES_REQUEST_ID = 'channel_emotes'
const EMOTES_REQUEST_IDS = [GLOBAL_EMOTES_REQUEST_ID, CHANNEL_EMOTES_REQUEST_ID]

const GLOBAL_EMOTES_URL = 'https://api.frankerfacez.com/v1/set/global'
const CHANNEL_EMOTES_URL_TEMPLATE = 'https://api.frankerfacez.com/v1/room/id/{{user_id}}'


# {
#    "code": {
#        "id": "",
#        "url": ""
#     }
# }
# code -- text to replace
# id -- internal ffz emote id
# url -- direct image url
var available_emotes := Dictionary()
var cache := Dictionary()
var available_emotes_parsed_count := 0
var user_id: String

# hooks
func _downloaded(downloaded_content: BaseEmotesCache.DownloadedContent) -> void:
    if downloaded_content.id in EMOTES_REQUEST_IDS:
        __parse_available_emotes(downloaded_content)

        available_emotes_parsed_count += 1
        ready_to_deliver_emotes = available_emotes_parsed_count >= EMOTES_REQUEST_IDS.size()

    else:
        var code: String = str(downloaded_content.id)
        var id: String = available_emotes.get(code, {}).get('id')
        var image: Image = downloaded_content.get_image_from_data()

        cache[code] = FfzEmote.new(id, code, image)

        emit_signal("emote_retrieved", cache.get(code))

func _get_emote_url(code: String) -> String:
    var url: String = available_emotes.get(code, {}).get('url', '')

    return url

# public
func init_emotes(user_id: String, force: bool=false) -> void:
    if self.user_id == null or self.user_id != user_id or force:
        user_id = user_id
        http_request_queue.enqueue_request(GLOBAL_EMOTES_REQUEST_ID, GLOBAL_EMOTES_URL)
        http_request_queue.enqueue_request(
            CHANNEL_EMOTES_REQUEST_ID,
            CHANNEL_EMOTES_URL_TEMPLATE.replace(USER_ID_PLACEHOLDER, user_id)
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
func __parse_available_emotes(download_content: BaseEmotesCache.DownloadedContent) -> void:
    if download_content.type != HttpHeaders.HTTP_CONTENT_TYPE_JSON:
        return

    var data = parse_json(download_content.data.get_string_from_utf8())
    var sets := data.get('sets') as Dictionary

    for set in sets.values():
        var emotes := set.get('emoticons') as Array

        for emote in emotes:
            var emote_url: String = emote.get('urls', {}).get('1', '').replace(
                '//', DEFAULT_URL_PROTOCOL
            )

            var id := str(emote.get('id'), '')

            available_emotes[emote.get('name')] = {
                'id': id,
                'url': emote_url
            }
