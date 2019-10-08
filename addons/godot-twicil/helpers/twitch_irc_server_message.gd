class_name TwitchIrcServerMessage


var message_prefix: String
var prefix: String
var command: String
var params: Array

func _init(message_prefix: String, prefix: String, command: String, params: Array):
    self.message_prefix = message_prefix
    self.prefix = prefix
    self.command = command
    self.params = params
