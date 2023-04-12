extends Spatial


func _ready():
	# Undo the load screen removing our cursor
	get_tree().get_root().set_disable_input(false)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# Read AP settings from file, if there are any
	var file = File.new()
	if file.file_exists("user://settings/archipelago"):
		file.open("user://settings/archipelago", File.READ)
		var data = file.get_var(true)
		file.close()

		if data.size() > 0:
			self.get_node("Panel/server_box").text = data[0]
		if data.size() > 1:
			self.get_node("Panel/player_box").text = data[1]
		if data.size() > 2:
			self.get_node("Panel/password_box").text = data[2]
