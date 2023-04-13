extends Spatial


func _ready():
	# Undo the load screen removing our cursor
	get_tree().get_root().set_disable_input(false)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# Create the global AP client, if it doesn't already exist.
	if not global.has_node("Archipelago"):
		var apclient = ResourceLoader.load("user://maps/Archipelago/client.gd")
		var apclient_instance = apclient.new()
		apclient_instance.name = "Archipelago"
		global.add_child(apclient_instance)

	global.get_node("Archipelago").connect("client_connected", self, "connectionSuccessful")

	# Populate textboxes with AP settings.
	self.get_node("Panel/server_box").text = global.get_node("Archipelago").ap_server
	self.get_node("Panel/player_box").text = global.get_node("Archipelago").ap_user
	self.get_node("Panel/password_box").text = global.get_node("Archipelago").ap_pass


func connectionSuccessful():
	# Switch to LL1
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	global.map = "level1"
	var _discard = get_tree().change_scene("res://scenes/load_screen.tscn")
