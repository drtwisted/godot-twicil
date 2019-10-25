class_name MessageWrapper


static func wrap(server_irc_message: TwitchIrcServerMessage) -> IrcChatMessage:
    var res = IrcChatMessage.new('', '')

    res.name = get_sender_name(server_irc_message)
    res.text = server_irc_message.params[1]
    res.text = res.text.substr(1, res.text.length() - 1)

    return res

static func get_sender_name(server_irc_message: TwitchIrcServerMessage) -> String:
    return server_irc_message.prefix.split('!')[0]
