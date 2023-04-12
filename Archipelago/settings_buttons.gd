extends Button


func _ready():
	pass


func _connect_pressed():
	# Save the AP settings to disk.
	var dir = Directory.new()
	var path = "user://settings"
	if dir.dir_exists(path):
		pass
	else:
		dir.make_dir(path)

	var file = File.new()
	file.open("user://settings/archipelago", File.WRITE)

	var data = [
		self.get_parent().get_node("server_box").text,
		self.get_parent().get_node("player_box").text,
		self.get_parent().get_node("password_box").text
	]

	file.store_var(data, true)
	file.close()


func _back_pressed():
	fader._fade_start("main_menu")
