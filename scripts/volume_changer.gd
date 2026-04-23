extends HSlider

const BUS_NAME := "backgroundMusic"
const CONFIG_PATH := "user://settings.cfg"
const CONFIG_SECTION := "audio"
const CONFIG_KEY := "music_volume"

func _ready() -> void:
	# garante que o slider está no range correto
	min_value = 0.0
	max_value = 1.0
	step = 0.01
	
	# carrega volume salvo
	var config = ConfigFile.new()
	var value := 1.0
	
	if config.load(CONFIG_PATH) == OK:
		value = config.get_value(CONFIG_SECTION, CONFIG_KEY, 1.0)
	
	self.value = value
	_apply_volume(value)

func _on_value_changed(value: float) -> void:
	_apply_volume(value)
	_save_volume(value)

func _apply_volume(value: float) -> void:
	var bus_index = AudioServer.get_bus_index(BUS_NAME)
	
	if value <= 0.0:
		AudioServer.set_bus_volume_db(bus_index, -80.0)
	else:
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(value))

func _save_volume(value: float) -> void:
	var config = ConfigFile.new()
	
	# carrega se já existir (pra não sobrescrever outras configs)
	config.load(CONFIG_PATH)
	
	config.set_value(CONFIG_SECTION, CONFIG_KEY, value)
	config.save(CONFIG_PATH)
