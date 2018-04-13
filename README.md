# Godot TwiCIL -- Godot Twitch Chat Interaction Layer
<img src="./godot-twicil-icon.png" height=100px/>


### Description
An abstraction layer for Godot Engine to enable interaction with twitch chat.

A basic explanation is available in this video (1.5x speed is recomended :D)


[![GodotTwiCIL Brief Tutorial](https://i.ytimg.com/vi/tYYCjMOxKEI/hqdefault.jpg)](https://youtu.be/tYYCjMOxKEI)

### How to use
1. Create you Twitch API application [here](https://dev.twitch.tv/dashboard/apps/create)
2. Generate a new OAUTH-Token [here](https://twitchapps.com/tmi/)

Assuming you have added ***TwiCIL*** node to your scene:
```
onready var twicil = get_node("TwiCIL")

var nick = "MySuperGame"
var client_id = "myClient1D"
var oauth = "oauth:my0auTh"
var channel = "channel_name"

func _setup_twicil():
  twicil.connect_to_twitch_chat()
  twicil.connect_to_channel(channel, cleint_id, oauth, nick)
  
  # Enable loggin (disabled by default)
  twicil.set_logging(true)
  
  # Add custom commands to game bot
  twicil.commands.add("hi", self, "_command_say_hi", 0)
  twicil.commands.add("bye", self, "_command_say_bye_to", 1)
  twicil.commands.add("!w", self, "_command_whisper", 0)

  # Add some aliases
  twicil.commands.add_aliases("hi", ["hello", "hi,", "hello,", "bye"])
  
  # Remove command/alias
  twicil.commands.remove("bye")

func _command_say_hi(params):
  var sender = params[0]
  
  twicil.send_message(str("Hello, @", sender))

func _command_say_bye_to(params):
  var sender = params[0]
  var recipient = params[1]
  
  twicil.send_message(str("@", recipient, ", ", sender, " says bye! TwitchUnity"))

func _command_whisper(params):
  var sender = params[0]
  
  twicil.send_whisper(sender, "Boo!")

func _ready():
  _setup_twicil()

```

### API

#### Methods
|Method|Params|Description|
|-|-|-|
|**connect_to_twitch_chat**| -- | Establishes connection to Twitch IRC Chat Server|
|**connect_to_channel**|**channel** -- channel name to connect to; **client_id** -- your *client_id* obtained from Twitch Developer Dashboard; **password** -- your *oauth code* obtained from Twitch Developer Dashboard; **nickname** -- nickname of account your app will be authorized in chat; **realname** (optional) -- not quite sure if it's necessary, but can be the same as *nickname*;  | Joins specified chat using provided credentials|
|**set_logging**|**state** -- boolean state| Enable/disable logging communication with server to stdout|
|**connect_to_host**|**host** -- host IP or FDQN; **port** -- host port| Establishes connection to specified host:port|
|**send_command**|**command** -- raw text which is send| Sends specified command/text directly to the server|
|**send_message**|**text** -- message text| Sends a regular message to the chat|
|**send_whisper**|**recipient** -- has to be a valid user name; **text** -- message text| Whispers (PM) a message to the specified user|


#### Signals
|Signal|Params|Description|
|-|-|-|
|**message_recieved**|**sender** -- sender nickname; **text** -- message text| Emitted on new messages send to chat|
|**raw_response_recieved**|**response** -- raw response from Twitch IRC server| Emitted on any response from Twitch IRC server recieved|
|**user_appeared**|**user** -- user nickname|Emitted on user join notification received from server. NOTE: this has a server delay of several minutes|
|**user_disappeared**|**user** -- user nickname|Emitted on user part notification received from server. NOTE: this has a server delay of several minutes|


#### Manage interactive commands

|Method|Params|Description|
|-|-|-|
|***commands.*** **add**|**chat_command** -- command text to react to; **target** -- target object on which method_name will be invoked; **method_name** -- method name to be invoked on the target object; **params_count**=1 -- parameters the command expects to be accepted as valid (optional param, default is 1); **variable_params_count**=false -- indicates if command can be called with any params count including none (optional param, default is false -- params count is mandatory). **NOTE:** Params are sent to callback as a list. First list member is ALWAYS sender nickname. See example ***godot-twicil-example.gd***)| Add command text **chat_command** to trigger **method_name** on **target** object and count command valid if **params_count** ammount of params is specified, or call it in any case if **variable_params_count** is set to *true*|
|***commands.*** **add_aliases**|**chat_command** -- command text alias(es) is/are set to; **aliases** --  a list of aliases to add to reaction of chat_command | Add aliases to chat_command to list of reactions. |
|***commands.*** **remove**|**chat_command** -- command (or alias) text reaction is set to| Remove command (or alias) from list of reactions |

### TODO:
* ~~Add aliases for chat commands~~
* Manage user states (~~connected~~/~~disconnected~~/banned users?)

