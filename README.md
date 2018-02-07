# Godot Twitch Chat Interactive Layer
###Description
An abstraction layer for Godot Engine to enable interaction with twitch chat.


###How to use
Simply copy godot-twicil into your project directory. And add godot-twicil node into the scene tree

###API

|Method|Params|Description|
|-|-|-|
|**connect_to_channel**|**channel** -- channel name to connect to; **nickname** -- nickname of account your app will be authorized in chat; **realname** -- not quite sure if it's necessary, but can be the same as *nickname*; **password** -- your *oauth code* obtained from Twitch Developer Dashboard; **client_id** -- your *client_id* obtained from Twitch Developer Dashboard|