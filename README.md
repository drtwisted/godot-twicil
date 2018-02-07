# GodotTwiCIL -- Godot Twitch Chat Interaction Layer
![GodotTwiCIL Logo](./godot-twicil-icon.png)
### Description
An abstraction layer for Godot Engine to enable interaction with twitch chat.


### How to use
Simply copy godot-twicil into your project directory. And add godot-twicil node into the scene tree. For more details, please, check the godot-twicil-example.tscn/.gd.

### API

#### Methods
|Method|Params|Description|
|-|-|-|
|**connect_to_twitch_chat**| -- | Establishes connectoin with Twitch IRC Chat Server|
|**connect_to_channel**|**channel** -- channel name to connect to; **client_id** -- your *client_id* obtained from Twitch Developer Dashboard; **password** -- your *oauth code* obtained from Twitch Developer Dashboard; **nickname** -- nickname of account your app will be authorized in chat; **realname** (optional) -- not quite sure if it's necessary, but can be the same as *nickname*;  | Joins specified chat using provided credentials|

#### Signals
|Signal|Params|Description|
|-|-|-|
|**message_recieved**|**sender** -- sender nickname; **text** -- message text.| Emitted on new messages send to chat|
|**raw_response_recieved**|**response** -- raw response from Twitch IRC server| Emitted on any response from Twitch IRC server recieved|

### TODO:
* Manage user states (connected/disconnected/banned users?)
