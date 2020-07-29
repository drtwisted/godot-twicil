class_name TwitchMessage

enum EmoteType {TWITCH, BTTV, FFZ}

const emote_id_methods = {
    EmoteType.BTTV: '__get_bttv_emote_id',
    EmoteType.FFZ: '__get_ffz_emote_id'
}


var chat_message: IrcChatMessage
#[
#    {
#        'code': 'emote_code',
#        'id': 'emote_id',
#        'type': 0    # EmoteType enum,
#         'attrs': {'id':'123456-fake-id', 'subscriber':'1'}
#    },
#    ...
#]
#
var emotes: Array
var attrs = {}


func _init(server_irc_message: TwitchIrcServerMessage, bttv_emotes: Dictionary, ffz_emotes, message_attrs: Dictionary):
    chat_message = MessageWrapper.wrap(server_irc_message)
    attrs = message_attrs

    emotes.clear()

    __parse_twitch_emotes(server_irc_message.message_prefix)
    __parse_bttv_emotes(bttv_emotes)
    __parse_ffz_emotes(ffz_emotes)


# private
func __parse_twitch_emotes(message_prefix: String):
    var prefix_params := message_prefix.split(';', false)
    var emotes_param: String

    for param in prefix_params:
        if (param as String).begins_with('emotes'):
            var emotes_prefix_param: Array = (param as String).split('=', false, 1)

            if emotes_prefix_param.size() <= 1:
                return

            emotes_param = emotes_prefix_param[1]

            for emote in emotes_param.split('/', false):
                var emote_data: Array = emote.split(':', false)
                var id := int(emote_data[0])

                var positions: Array = emote_data[1].split(',', false)[0].split('-', false)

                var start := int(positions[0])
                var end := int(positions[1])

                var code: String = chat_message.text.substr(start, end - start + 1)

                emotes.append({
                    'id': id,
                    'code': code,
                    'type': EmoteType.TWITCH
                })

static func __get_bttv_emote_id(available_emotes: Dictionary, emote_code: String):
    return available_emotes.get(emote_code)

static func __get_ffz_emote_id(available_emotes: Dictionary, emote_code: String):
    return available_emotes.get(emote_code, {}).get('id')

func __parse_emotes(available_emotes: Dictionary, type: int) -> void:
    var message: String = ' ' + chat_message.text + ' '

    for emote_code in available_emotes:
        var parse_emote_code: String = ' ' + emote_code + ' '

        if message.find(parse_emote_code) >= 0:
            emotes.append({
                'id': callv(emote_id_methods.get(type), [available_emotes, emote_code]),
                'code': emote_code,
                'type': type
            })

func __parse_bttv_emotes(available_emotes: Dictionary) -> void:
    __parse_emotes(available_emotes, EmoteType.BTTV)

func __parse_ffz_emotes(available_emotes: Dictionary) -> void:
    __parse_emotes(available_emotes, EmoteType.FFZ)
