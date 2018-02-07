tool
extends EditorPlugin

func _enter_tree():
    add_custom_type("TwiCIL", "Node", preload("godot_twicil.gd"), preload("./sprites/twicil-icon.png"))

func _exit_tree():
    remove_custom_type("TwiCIL")
