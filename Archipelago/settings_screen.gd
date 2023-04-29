extends Spatial


func _ready():
	# Undo the load screen removing our cursor
	get_tree().get_root().set_disable_input(false)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# Increase the WebSocket input buffer size so that we can download large
	# data packages.
	ProjectSettings.set_setting("network/limits/websocket_client/max_in_buffer_kb", 8192)

	# Create the global AP client, if it doesn't already exist.
	if not global.has_node("Archipelago"):
		var apclient_script = ResourceLoader.load("user://maps/Archipelago/client.gd")
		var apclient_instance = apclient_script.new()
		apclient_instance.name = "Archipelago"
		global.add_child(apclient_instance)

		var apdata = ResourceLoader.load("user://maps/Archipelago/gamedata.gd")
		var apdata_instance = apdata.new()
		apdata_instance.name = "Gamedata"
		apclient_instance.add_child(apdata_instance)

		# Let's also inject any scripts we need to inject now.
		installScriptExtension("user://maps/Archipelago/doorControl.gd")
		installScriptExtension("user://maps/Archipelago/load.gd")
		installScriptExtension("user://maps/Archipelago/painting_eye.gd")
		installScriptExtension("user://maps/Archipelago/painting_scenery.gd")
		installScriptExtension("user://maps/Archipelago/panelLevelSwitch.gd")
		installScriptExtension("user://maps/Archipelago/panelEnd.gd")
		installScriptExtension("user://maps/Archipelago/pause_menu.gd")

	var apclient = global.get_node("Archipelago")
	apclient.connect("client_connected", self, "connectionSuccessful")
	apclient.connect("could_not_connect", self, "connectionUnsuccessful")
	apclient.connect("connect_status", self, "connectionStatus")

	# Populate textboxes with AP settings.
	self.get_node("Panel/server_box").text = apclient.ap_server
	self.get_node("Panel/player_box").text = apclient.ap_user
	self.get_node("Panel/password_box").text = apclient.ap_pass

	# Show client version.
	self.get_node("Panel/title").text = "ARCHIPELAGO (%s)" % apclient.my_version

	# Increase font size in text boxes.
	var field_font = DynamicFont.new()
	field_font.font_data = load("res://fonts/CutiveMono_Regular.ttf")
	field_font.size = 36

	self.get_node("Panel/server_box").add_font_override("font", field_font)
	self.get_node("Panel/player_box").add_font_override("font", field_font)
	self.get_node("Panel/password_box").add_font_override("font", field_font)


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


func connectionStatus(message):
	var popup = self.get_node("Panel/AcceptDialog")
	popup.window_title = "Connecting to Archipelago"
	popup.dialog_text = message
	popup.popup_exclusive = true
	popup.get_ok().visible = false
	popup.popup_centered()


func connectionSuccessful():
	var apclient = global.get_node("Archipelago")

	# Switch to LL1
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	global.map = "level1"
	global.save_file = apclient.getSaveFileName()
	var _discard = get_tree().change_scene("res://scenes/load_screen.tscn")


func connectionUnsuccessful(error_message):
	self.get_node("Panel/connect_button").disabled = false

	var popup = self.get_node("Panel/AcceptDialog")
	popup.window_title = "Could not connect to Archipelago"
	popup.dialog_text = error_message
	popup.popup_exclusive = true
	popup.get_ok().visible = true
	popup.popup_centered()
