extends Node

var settings_file = "user://game_settings.save"

var username

func _ready():
	load_settings()

func load_settings():
	var file = File.new()
	if file.file_exists(settings_file):
		file.open(settings_file, File.READ)
		username = file.get_var()
		file.close()
	else:
		username = str("Player")

func save_settings():
	var file = File.new()
	file.open(settings_file, File.WRITE)
	file.store_var(username)
	file.close()
