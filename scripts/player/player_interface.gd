extends Node

@export
var controller_id : int

func set_color(color : Color):
	$Visual.modulate = color
