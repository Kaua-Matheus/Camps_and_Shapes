extends Control

func _ready() -> void:
	var config = ConfigFile.new()
	var value := 1.0
	
	if config.load("user://settings.cfg") == OK:
		value = config.get_value("audio", "music_volume", 1.0)
	
	var bus_index = AudioServer.get_bus_index("backgroundMusic")
	
	if value <= 0.0:
		AudioServer.set_bus_volume_db(bus_index, -80.0)
	else:
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(value))
