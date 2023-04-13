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

		# Let's also inject any scripts we need to inject now.
		installScriptExtension("user://maps/Archipelago/doorControl.gd")
		installScriptExtension("user://maps/Archipelago/load.gd")
		installScriptExtension("user://maps/Archipelago/painting_eye.gd")

	global.get_node("Archipelago").connect("client_connected", self, "connectionSuccessful")

	# Populate textboxes with AP settings.
	self.get_node("Panel/server_box").text = global.get_node("Archipelago").ap_server
	self.get_node("Panel/player_box").text = global.get_node("Archipelago").ap_user
	self.get_node("Panel/password_box").text = global.get_node("Archipelago").ap_pass


# Adapted from https://gitlab.com/Delta-V-Modding/Mods/-/blob/main/game/ModLoader.gd
func installScriptExtension(childScriptPath: String):
	var childScript = ResourceLoader.load(childScriptPath)

	# Force Godot to compile the script now.
	# We need to do this here to ensure that the inheritance chain is
	# properly set up, and multiple mods can chain-extend the same
	# class multiple times.
	# This is also needed to make Godot instantiate the extended class
	# when creating singletons.
	# The actual instance is thrown away.
	childScript.new()

	var parentScript = childScript.get_base_script()
	var parentScriptPath = parentScript.resource_path
	global._print(
		"ModLoader: Installing script extension: %s <- %s" % [parentScriptPath, childScriptPath]
	)
	childScript.take_over_path(parentScriptPath)


func connectionSuccessful():
	# Switch to LL1
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	global.map = "level1"
	var _discard = get_tree().change_scene("res://scenes/load_screen.tscn")
