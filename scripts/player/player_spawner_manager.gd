extends Node

var devices : Array = []

func _input(event):
	if event.is_action_pressed("spawn"):
		if devices.has(event.get_device()):
			return
		
		devices.append(event.get_device())
		for spawner in get_children():
			if not spawner.has_spawned():
				spawner.spawn(event.get_device())
				return
