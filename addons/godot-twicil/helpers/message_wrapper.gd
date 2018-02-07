static func wrap(server_irc_message):
	var res = preload('irc_chat_message.gd').new('', '')

	res.name = server_irc_message.prefix.split('!')[0]
	res.text = server_irc_message.params[1]
	res.text = res.text.substr(1, res.text.length() - 1)

	return res