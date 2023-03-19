extends Node

signal joypad_connected(device_id)
signal new_joypad_connected(device_id)
signal joypad_reconnected(device_id)
signal joypad_disconnected(device_id)

@export
var filter_ui_actions : bool = true

var call_map : Dictionary
var action_map : Dictionary
var event_map : Dictionary

var event_values : Dictionary
var just_pressed_devices: Array
var just_pressed_actions : Dictionary
var just_released_devices: Array
var just_released_actions : Dictionary

# Public
func bind(device_id: int, callable: Callable):
	if has_joypad(device_id) and not call_map[device_id].has(callable):
		call_map[device_id].append(callable)

func get_action_strength(device_id: int, action: String) -> float:
	if not action_map.has(action):
		return 0.0

	var events = event_values[device_id][action]
	var current_strength : float = 0.0
	for event in events:
		current_strength += event_values[device_id][action][event]
	return clamp(current_strength, 0, 1)
	
func get_axis(device_id: int, positive_action: String, negative_action: String) -> float:
	return get_action_strength(device_id, positive_action) - get_action_strength(device_id, negative_action)

func get_vector(device_id: int, positive_x: String, negative_x: String, positive_y: String, negative_y: String) -> Vector2:
	var vec = Vector2(get_axis(device_id, positive_x, negative_x), get_axis(device_id, positive_y, negative_y))
	var deadzone = 0.25 * \
		( action_map[positive_x].deadzone \
		+ action_map[negative_x].deadzone \
		+ action_map[positive_y].deadzone \
		+ action_map[negative_y].deadzone )
	var length = vec.length()
	
	if length < deadzone:
		return Vector2.ZERO
	elif length > 1.0:
		return vec / length
	else:
		return vec * inverse_lerp(deadzone, 1.0, length) / length

func is_action_pressed(device_id: int, action: String) -> bool:
	if not action_map.has(action):
		return false

	var events = event_values[device_id][action]
	for event in events:
		if event != 0.0:
			return true
	return false

func is_action_just_pressed(device_id: int, action: String) -> bool:
	if not action_map.has(action):
		return false

	return just_pressed_actions[device_id].has(action)

func is_action_just_released(device_id: int, action: String) -> bool:
	if not action_map.has(action):
		return false

	return just_released_actions[device_id].has(action)

func start_vibration(device_id: int, weak_magnitude: float, strong_magnitude: float, duration: float = 0.0):
	Input.start_joy_vibration(device_id, weak_magnitude, strong_magnitude, duration)

func stop_vibration(device_id: int):
	Input.stop_joy_vibration(device_id)

func is_vibrating(device_id: int) -> bool:
	return get_vibration_duration(device_id) > 0.0

func get_vibration_strength(device_id: int) -> Vector2:
	return Input.get_joy_vibration_strength(device_id)

func get_vibration_duration(device_id: int) -> float:
	return Input.get_joy_vibration_duration(device_id)

# Engine
func _ready():
	find_actions()
	find_joypads()
	Input.joy_connection_changed.connect(joypad_connection_changed)

func _process(_delta):
	for device in just_pressed_devices:
		just_pressed_actions[device].clear()
		just_pressed_devices.erase(device)
	for device in just_released_devices:
		just_released_actions[device].clear()
		just_released_devices.erase(device)

func _unhandled_input(event: InputEvent):
	if not has_joypad(event.get_device()):
		return
	
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		var device_id: int = event.get_device()
		
		var action: String = ""
		var action_event: InputEvent
		for stored_event in event_map.keys():
			if stored_event.is_match(event, true):
				action = event_map[stored_event]
				action_event = stored_event
		
		if action_event != null:
			var strength = event.get_action_strength(action)
			if event_values[device_id][action][action_event] == 0.0 and strength != 0.0:
				just_pressed_actions[device_id].append(action)
				just_pressed_devices.append(device_id)
			if event_values[device_id][action][action_event] != 0.0 and strength == 0.0:
				just_released_actions[device_id].append(action)
				just_released_devices.append(device_id)
			event_values[device_id][action][action_event] = strength
		
		for callable in call_map[device_id]:
			callable.call(event)

# Signal Response
func joypad_connection_changed(device_id: int, connected: bool):
	if connected:
		if not has_joypad(device_id):
			add_joypad(device_id)
		else:
			emit_signal("joypad_reconnected", device_id)
		emit_signal("joypad_connected", device_id)
	else:
		emit_signal("joypad_disconnected", device_id)

# Internal
func find_actions():
	var action_list : Array = InputMap.get_actions()
	if filter_ui_actions:
		action_list = action_list.filter(func(action_name): return not action_name.begins_with("ui_"))
	for action_name in action_list:
		var action : Dictionary = ProjectSettings.get_setting("input/" + action_name)
		if not action.is_empty():
			action_map[action_name] = action
			for event in action.events:
				event_map[event] = action_name

func find_joypads():
	var joy_list : Array = Input.get_connected_joypads()
	for device_id in joy_list:
		emit_signal("joypad_connected", device_id)
		add_joypad(device_id)

func add_joypad(device_id: int):
	call_map[device_id] = []
	just_pressed_actions[device_id] = []
	just_released_actions[device_id] = []
	event_values[device_id] = {}
	for action in action_map.keys():
		event_values[device_id][action] = {}
		for event in action_map[action].events:
			event_values[device_id][action][event] = 0.0
	emit_signal("new_joypad_connected", device_id)

func has_joypad(device_id: int):
	return call_map.has(device_id)
