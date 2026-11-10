extends RefCounted

const SETTINGS_PATH := "user://ashfall_audio.cfg"
const DEFAULTS := {"Master": 1.0, "Wind": 1.0, "Footsteps": 1.0, "Effects": 1.0}
var levels: Dictionary = DEFAULTS.duplicate()

func setup() -> void:
	for bus_name in ["Wind", "Footsteps", "Effects"]:
		if AudioServer.get_bus_index(bus_name) < 0:
			AudioServer.add_bus()
			var index := AudioServer.bus_count - 1
			AudioServer.set_bus_name(index, bus_name)
			AudioServer.set_bus_send(index, "Master")
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		for bus_name in levels:
			levels[bus_name] = clampf(float(config.get_value("audio", bus_name, DEFAULTS[bus_name])), 0.0, 1.0)
	for bus_name in levels:
		_apply(bus_name)

func set_level(bus_name: String, value: float) -> void:
	if not levels.has(bus_name):
		return
	levels[bus_name] = clampf(value, 0.0, 1.0)
	_apply(bus_name)
	var config := ConfigFile.new()
	for key in levels:
		config.set_value("audio", key, levels[key])
	if config.save(SETTINGS_PATH) != OK:
		push_warning("Could not save audio settings.")

func _apply(bus_name: String) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index < 0:
		return
	var value: float = levels[bus_name]
	AudioServer.set_bus_mute(index, value <= 0.0)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(value, 0.0001)))
