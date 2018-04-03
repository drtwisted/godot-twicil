# GodotTwiCIL -- Godot Twitch Chat Interaction Layer
![GodotTwiCIL Logo](./godot-twicil-icon.png)
### Description
An abstraction layer for Godot Engine to enable interaction with twitch chat.


### How to use
TODO: Super-simple code snippet

### API

#### Methods
|Method|Params|Description|
|-|-|-|
|**connect_to_twitch_chat**| -- | Establishes connection to Twitch IRC Chat Server|
|**connect_to_channel**|**channel** -- channel name to connect to; **client_id** -- your *client_id* obtained from Twitch Developer Dashboard; **password** -- your *oauth code* obtained from Twitch Developer Dashboard; **nickname** -- nickname of account your app will be authorized in chat; **realname** (optional) -- not quite sure if it's necessary, but can be the same as *nickname*;  | Joins specified chat using provided credentials|
|**set_logging**|**state** -- boolean state| Enable/disable logging communication with server to stdout|
|**connect_to_host**|**host** -- host IP or FDQN; **port** -- host port| Establishes connection to specified host:port|
|**send_command**|**command** -- raw text which is send| Sends specified command/text directly to the server|


#### Signals
|Signal|Params|Description|
|-|-|-|
|**message_recieved**|**sender** -- sender nickname; **text** -- message text.| Emitted on new messages send to chat|
|**raw_response_recieved**|**response** -- raw response from Twitch IRC server| Emitted on any response from Twitch IRC server recieved|

#### Manage interactive commands
|Method|Params|Description|
|-|-|-|
|**add**|**chat_command** -- command text to react to; **target** -- target object on which method_name will be invoked; **method_name** -- method name to be invoked on the target object; **params_count**=1 -- parameters the command expects to be accepted as valid (optional param, default is 1); **variable_params_count**=false -- indicates if command can be called with any params count including none (optional param, default is false -- params count is mandatory). **NOTE:** Params are sent to callback as a list. First list member is ALWAYS sender nickname. See example [godot-twicil-example.gd](https://github.com/drtwisted/godot-twicil/blob/master/godot-twicil-example.gd)| Add command text **chat_command** to trigger **method_name** on **target** object and count command valid if **params_count** ammount of params is specified, or call it in any case if **variable_params_count** is set to *true*|
|**remove**|**chat_command** -- command text reaction is set to| Remove command from list of reactions |

### TODO:
* Manage user states (connected/disconnected/banned users?)
