extends Node

@export
var speed = 1
@onready
var max_speed = speed * 10000

@export
var acceleration = 0.1
@export
var desceleration = 0.8

func _ready():
	JoyInput.bind(owner.controller_id, button_input)

func _physics_process(delta):
	owner.set_velocity(process_velocity(delta))
	owner.move_and_slide()

func process_velocity(delta) -> Vector2:
	var desired_velocity = get_input_direction() * delta * max_speed
	
	if desired_velocity != Vector2.ZERO && owner.get_velocity().length() <= max_speed:
		return owner.get_velocity().lerp(desired_velocity, acceleration)
	else:
		return owner.get_velocity().lerp(desired_velocity, desceleration)

func get_input_direction():
	return JoyInput.get_vector(owner.controller_id, "right", "left", "down", "up")

func button_input(event: InputEvent):
	if event.is_action_pressed("action"):
		JoyInput.start_vibration(owner.controller_id, 0, 0.5, 1)
