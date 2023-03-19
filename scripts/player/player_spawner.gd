extends Node

@export
var player_container : NodePath

@export
var player_scene : PackedScene

@export
var player_color : Color

var player : Node

func spawn(device_id : int):
	if has_spawned():
		return
	
	player = player_scene.instantiate()
	player.global_position = self.global_position
	player.set_color(player_color)
	player.controller_id = device_id
	get_node(player_container).add_child(player)

func has_spawned() -> bool:
	return player != null
