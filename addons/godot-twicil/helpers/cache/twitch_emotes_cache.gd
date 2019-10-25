extends BaseEmotesCache
class_name TwitchEmotesCache


signal emote_retrieved(emote)


class TwitchEmote:
    var id: int
    var code: String
    var texture: ImageTexture

    func _init(id: int, code: String, image: Image):
        self.id = id
        self.code = code
        self.texture = BaseEmotesCache.BaseEmote.create_texture_from_image(image)


const EMOTE_URL_TEMPLATE = 'https://static-cdn.jtvnw.net/emoticons/v1/{emote_id}/1.0'

# { id: Emote
#    ...
# }
var cache := Dictionary()


# hooks
func _ready():
    ._ready()

    ready_to_deliver_emotes = true


# public
func get_emote(id: int):
    if not ready_to_deliver_emotes:
        return

    if cache.has(id):
        emit_signal("emote_retrieved", cache.get(id))

    else:
        __cache_emote(str(id))


# hooks
func _get_emote_url(code) -> String:
    var string_id := str(code)
    var url := EMOTE_URL_TEMPLATE.replace('{emote_id}', string_id)

    return url

func _downloaded(downloaded_content: BaseEmotesCache.DownloadedContent) -> void:
    var id_ := int(downloaded_content.id)
    var image: Image = downloaded_content.get_image_from_data()

    cache[id_] = TwitchEmote.new(id_, '', image)

    emit_signal("emote_retrieved", cache.get(id_))
