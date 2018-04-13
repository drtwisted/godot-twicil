static func wrap(server_irc_message):
	var res = preload('irc_chat_message.gd').new('', '')

	res.name = get_sender_name(server_irc_message)
	res.text = server_irc_message.params[1]
	res.text = res.text.substr(1, res.text.length() - 1)

	return res

static func get_sender_name(server_irc_message):
	return server_irc_message.prefix.split('!')[0]