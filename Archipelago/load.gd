extends "res://scripts/load.gd"

const EXCLUDED_PAINTINGS = [
	"ascension.tscn",
	"ascension_ne.tscn",
	"ascension_nw.tscn",
	"ascension_se.tscn",
	"ascension_sw.tscn",
	"frame.tscn",
	"scenery_0.tscn",
	"scenery_1.tscn",
	"scenery_2.tscn",
	"scenery_3.tscn",
	"scenery_4.tscn",
	"scenery_5.tscn",
	"pilgrim.tscn"
]


func _load():
	global._print("Hooked Load Start")

	var apclient = global.get_node("Archipelago")

	# Override the YOU panel with the AP slot name.
	if self.get_node_or_null("Panels/Color Arrow Room/Panel_you") != null:
		self.get_node("Panels/Color Arrow Room/Panel_you").answer = apclient.ap_user
	for node in get_tree().get_nodes_in_group("text_you"):
		if "text" in node:
			node.text = apclient.ap_user
		elif "value" in node:
			node.value = apclient.ap_user
	for node in get_tree().get_nodes_in_group("answer_you"):
		if "answer" in node:
			node.answer = apclient.ap_user

	# Create "The Wanderer".
	set_gridmap_tile(-4.5, 6.5, 56.5, "MeshInstance4")
	set_gridmap_tile(-3.5, 6.5, 56.5, "MeshInstance18")
	set_gridmap_tile(-3.5, 6.5, 57.5, "MeshInstance5")

	var door_scene = load("res://nodes/door.tscn")
	var door_script = load("user://maps/Archipelago/doorControl.gd")
	var wanderer_entrance = door_scene.instance()
	wanderer_entrance.name = "Door_wanderer_entrance"
	wanderer_entrance.translation = Vector3(7.5, 5, 53)
	wanderer_entrance.rotation = Vector3(0, -PI / 2, 0)
	wanderer_entrance.scale = Vector3(1, 1.5, 1)
	wanderer_entrance.set_script(door_script)
	wanderer_entrance.panels.append("../../../Panels/Tower Room/Panel_wanderlust_1234567890")
	get_node("Doors/Tower Room Area Doors").add_child(wanderer_entrance)

	var wanderer_achieve = get_node("Panels/Tower Room/Panel_1234567890_wanderlust")
	wanderer_achieve.get_parent().remove_child(wanderer_achieve)
	get_node("Panels/Countdown Panels").add_child(wanderer_achieve)

	var countdown_scene = load("res://nodes/panel_countdown.tscn")
	var wanderer_cdp = countdown_scene.instance()
	wanderer_cdp.name = "CountdownPanel_wanderer"
	wanderer_cdp.panels = [
		"../../Panels/Tower Room/Panel_wanderlust_1234567890",
		"../../Panels/Orange Room/Panel_lust",
		"../../Panels/Orange Room/Panel_read",
		"../../Panels/Orange Room/Panel_sew",
		"../../Panels/Orange Room/Panel_dead",
		"../../Panels/Orange Room/Panel_learn",
		"../../Panels/Orange Room/Panel_dust",
		"../../Panels/Orange Room/Panel_star",
		"../../Panels/Orange Room/Panel_wander"
	]
	wanderer_cdp.translation = wanderer_achieve.translation
	wanderer_cdp.rotation = wanderer_achieve.rotation
	get_node("CountdownPanels").add_child(wanderer_cdp)

	wanderer_achieve.translation = Vector3(-51, -33, 35)  # way under the map

	# Set up The Master to be variable.
	var old_master_cdp = get_node("CountdownPanels/CountdownPanel_countdown_16")
	var cdp_auto_scene = load("res://nodes/panel_countdown_auto.tscn")
	var new_master_cdp = cdp_auto_scene.instance()
	new_master_cdp.name = "AP_variable_master"
	new_master_cdp.replace_with = old_master_cdp.replace_with
	new_master_cdp.panels = "../../Panels/Countdown Panels"
	new_master_cdp.maxlength = apclient._mastery_achievements
	new_master_cdp.translation = old_master_cdp.translation
	new_master_cdp.rotation = old_master_cdp.rotation
	get_node("CountdownPanels").add_child(new_master_cdp)
	old_master_cdp.queue_free()

	# Configure AN OTHER WAY.
	var another_cdp = get_node("CountdownPanels/CountdownPanel_level2_0")
	another_cdp.maxlength = (apclient._level_2_requirement - 1)

	# This is the best time to create the location nodes, since the map is now
	# loaded but the panels haven't been solved from the save file yet.
	var gamedata = apclient.get_node("Gamedata")
	var panels_parent = self.get_node("Panels")
	var location_script = ResourceLoader.load("user://maps/Archipelago/location.gd")
	for location_id in gamedata.panel_ids_by_location_id.keys():
		if apclient._location_name_to_id.has(location_id):
			var location = location_script.new()
			location.ap_id = int(apclient._location_name_to_id[location_id])
			location.name = "AP_location_%d" % location.ap_id
			self.add_child(location)

			var panels = gamedata.panel_ids_by_location_id[location_id]
			location.total = panels.size()

			for panel in panels:
				var that_panel
				if panel.begins_with("EndPanel"):
					that_panel = self.get_node("Decorations").get_node(panel)
				else:
					that_panel = panels_parent.get_node(panel)

				that_panel.get_node("Viewport/GUI/Panel/TextEdit").connect(
					"answer_correct", location, "handle_correct"
				)
		else:
			global._print("Could not find location ID for %s" % location_id)

	# HOT CRUSTS should be at eye-level, have a yellow block behind it, and
	# not vanish when solved.
	var hotcrusts = panels_parent.get_node("Shuffle Room/Panel_shortcuts")
	hotcrusts.translation.y = 1.5
	hotcrusts.get_node("Viewport/GUI/Panel/TextEdit").disconnect(
		"answer_correct", hotcrusts, "handle_correct"
	)

	set_gridmap_tile(-20.5, 1.5, -79.5, "MeshInstance9")

	# TRANS RIGHTS should be bottom white, like it used to be.
	var trans_rights = panels_parent.get_node("Shuffle Room/Panel_secret_secret")
	trans_rights.translation.y = 0.5

	# Randomize the panels, if necessary.
	var rng = RandomNumberGenerator.new()
	rng.seed = apclient._slot_seed

	# Remove opaque wall in front of FOURTH.
	set_gridmap_tile(-71.5, 1.5, -64.5, "MeshInstance18")

	# Move The Lab's OPEN out of the wall.
	panels_parent.get_node("Chemistry Room/Panel_open").translation.x = -87.001

	# Move ZERO out of the wall and change the wall to be white.
	panels_parent.get_node("Backside Room/Panel_zero_zero").translation.z = 16.499

	set_small_gridmap_tile(-76.25, 1.75, 16.75, "SmallMeshInstance5")
	set_small_gridmap_tile(-76.75, 1.75, 16.75, "SmallMeshInstance5")
	set_small_gridmap_tile(-76.25, 1.25, 16.75, "SmallMeshInstance5")
	set_small_gridmap_tile(-76.75, 1.25, 16.75, "SmallMeshInstance5")

	# Block the roof access to The Wondrous.
	for x in range(0, 3):
		for z in range(0, 3):
			set_gridmap_tile(-95.5 - x, -3.5, -44.5 - z, "MeshInstance4")

	# Block visibility of RAINY from the roof.
	set_gridmap_tile(-88.5, 4.5, -41.5, "MeshInstance8")
	set_gridmap_tile(-89.5, 4.5, -41.5, "MeshInstance4")

	if apclient._panel_shuffle != apclient.kNO_PANEL_SHUFFLE:
		# Make The Wondrous's FIRE solely midred.
		set_gridmap_tile(-76.5, 1.5, -73.5, "MeshInstance18")

		# Reduce double/triple length puzzles in Knight/Night.
		set_gridmap_tile(24.5, 1.5, 11.5, "MeshInstance18")
		set_gridmap_tile(25.5, 1.5, 11.5, "MeshInstance18")
		set_gridmap_tile(47.5, 1.5, 11.5, "MeshInstance18")

	if apclient._panel_shuffle == apclient.kREARRANGE_PANELS:
		# Do the actual shuffling.
		var panel_pools = {}
		for panel in gamedata.panels:
			if not panel_pools.has(panel["tag"]):
				panel_pools[panel["tag"]] = {}
			var pool = panel_pools[panel["tag"]]
			var subtag = "default"
			if panel.has("subtag"):
				subtag = panel["subtag"]
			if not pool.has(subtag):
				pool[subtag] = []

			var panel_node = panels_parent.get_node(panel["id"])
			pool[subtag].append(
				{
					"id": panel["id"],
					"hint": panel_node.text,
					"answer": panel_node.answer,
					"link": panel["link"],
					"copy_to_sign": panel["copy_to_sign"]
				}
			)

		for tag in panel_pools.keys():
			if tag == "forbid":
				continue

			var pool = panel_pools[tag]
			for subtag in pool.keys():
				pool[subtag].sort_custom(self, "sort_by_link")

			var count = pool[pool.keys()[0]].size()
			var iota = range(0, count)
			var order = []
			while not iota.empty():
				var i = rng.randi_range(0, iota.size() - 1)
				order.append(iota[i])
				iota.remove(i)

			for subtag in pool.keys():
				for i in range(0, count):
					var source = pool[subtag][i]
					var target = pool[subtag][order[i]]
					var target_panel_node = panels_parent.get_node(target["id"])

					target_panel_node.text = source["hint"]
					target_panel_node.answer = source["answer"]

					for sign_name in target["copy_to_sign"]:
						self.get_node("Decorations/PanelSign").get_node(sign_name).value = source["hint"]

		# Change the answer to the final puzzle in the art gallery based on the
		# puzzles that were shuffled into the constituent places.
		var new_answer = panels_parent.get_node("Painting Room/Panel_eon_one").answer
		new_answer += " "
		new_answer += panels_parent.get_node("Painting Room/Panel_path_road").answer
		new_answer += " "
		new_answer += panels_parent.get_node("Painting Room/Panel_any_many").answer
		new_answer += " "
		new_answer += panels_parent.get_node("Painting Room/Panel_send_use_turns").answer
		panels_parent.get_node("Painting Room/Panel_order_onepathmanyturns").answer = new_answer

	# Handle our other static panels after panel randomization, so that the old
	# values can enter the pool, if necessary.
	set_static_panel("Entry Room/Panel_hi_hi", "hi")
	set_static_panel("Entry Room/Panel_write_write", apclient.my_version)
	set_static_panel("Entry Room/Panel_same_same", str(apclient._slot_seed))
	set_static_panel("Entry Room/Panel_type_type", "victory")

	var victory_condition = "unknown"
	if apclient._victory_condition == apclient.kTHE_END:
		victory_condition = "the end"
	elif apclient._victory_condition == apclient.kTHE_MASTER:
		victory_condition = "the master"
	elif apclient._victory_condition == apclient.kLEVEL_2:
		victory_condition = "level 2"

	set_static_panel("Entry Room/Panel_this_this", victory_condition)
	set_static_panel("Entry Room/Panel_hidden_hidden", "hewwo")
	set_static_panel("Entry Room/Panel_hi_high", "goode", "good")
	set_static_panel("Entry Room/Panel_low_low", "serendipity", "luck")
	set_static_panel("Shuffle Room/Panel_secret_secret", "trans rights", "human rights")

	# Finish up with The Wanderer.
	wanderer_achieve.text = "12345656"
	wanderer_achieve.answer = "the wanderer"
	wanderer_achieve.achieved_text = "the wanderer"

	wanderer_cdp.replace_with = "../../Panels/Countdown Panels/Panel_1234567890_wanderlust"

	get_node("Doors/Tower Room Area Doors/Door_wanderlust_start").panels = [
		"../../../Panels/Countdown Panels/Panel_1234567890_wanderlust"
	]

	# Randomize the paintings, if necessary.
	if apclient._painting_shuffle:
		var paintings_dir = Directory.new()
		var all_paintings = []
		if paintings_dir.open("res://nodes/paintings") == OK:
			paintings_dir.list_dir_begin()
			var file_name = paintings_dir.get_next()
			while file_name != "":
				if file_name.ends_with(".tscn") and not EXCLUDED_PAINTINGS.has(file_name):
					all_paintings.append(file_name.trim_suffix(".tscn"))
				file_name = paintings_dir.get_next()
			paintings_dir.list_dir_end()

		var pd = Node.new()
		pd.set_name("AP_Paintings")
		self.add_child(pd)

		var classes = {}
		for painting in apclient._paintings_mapping.values():
			if not classes.has(painting):
				var i = rng.randi_range(0, all_paintings.size() - 1)
				var chosen = all_paintings[i]
				classes[painting] = chosen
				all_paintings.remove(i)

		var randomized = []
		for painting in classes.keys():
			var painting_class = classes[painting]
			instantiate_painting(painting, painting_class)
			randomized.append(painting)

		for source_painting in apclient._paintings_mapping.keys():
			var target_painting = apclient._paintings_mapping[source_painting]
			var painting_class = classes[target_painting]
			var new_source = instantiate_painting(source_painting, painting_class)
			new_source.target = pd.get_node(target_painting).get_node("Script")
			randomized.append(source_painting)

		var remaining_size = classes.size() / 2
		if remaining_size >= all_paintings.size():
			remaining_size = all_paintings.size()
		var remaining = []
		for i in range(0, remaining_size):
			var j = rng.randi_range(0, all_paintings.size() - 1)
			remaining.append(all_paintings[j])
			all_paintings.remove(j)

		for painting in gamedata.paintings.keys():
			if randomized.has(painting):
				continue

			var chosen_painting = remaining[rng.randi_range(0, remaining.size() - 1)]
			instantiate_painting(painting, chosen_painting)

	# If door shuffle is on, we need to make some changes to the Art Gallery.
	# The player should always have access to the backroom, but they shouldn't
	# have access to ORDER until getting the fifth floor, so will move the
	# backroom door. Also, the paintings in the backroom should only show up as
	# the player gets the progressive art gallery items.
	#
	# We also need to add an extra door to The Fearless.
	if apclient._door_shuffle:
		var backroom_door = get_node("Doors/Tower Room Area Doors/Door_painting_backroom")
		backroom_door.translation.x = 97
		backroom_door.translation.y = 0
		backroom_door.translation.z = 39
		backroom_door.scale.x = 2
		backroom_door.scale.y = 2.5
		backroom_door.scale.z = 1

		for i in range(2, 6):
			var painting_path = "Decorations/Paintings/scenery_painting_%db" % i
			var painting_node = get_node(painting_path)
			var rotate = painting_node.rotate
			var target = painting_node.target
			painting_node.set_script(load("res://scripts/painting_eye.gd"))
			painting_node.rotate = rotate
			painting_node.target = target
			painting_node.move_to_x = painting_node.translation.x
			painting_node.move_to_z = painting_node.translation.z
			painting_node.translation.x = 88
			painting_node.translation.z = 39

		var fearless_door = get_node("Doors/Naps Room Doors/Door_hider_5").duplicate()
		fearless_door.name = "Door_hider_new1"
		fearless_door.translation.y = 5
		get_node("Doors/Naps Room Doors").add_child(fearless_door)

	# Set up notifiers for each achievement panel, for the tracker.
	var notifier_script = ResourceLoader.load("user://maps/Archipelago/notifier.gd")
	for panel in gamedata.panels:
		if "achievement" in panel:
			var panel_node = panels_parent.get_node(panel["id"])
			var script_instance = notifier_script.new()
			script_instance.name = "Achievement_Notifier"
			script_instance.key = "Achievement|%s" % panel["achievement"]
			panel_node.add_child(script_instance)

	# Attach a script to every panel so that we can do things like conditionally
	# disable them.
	var panel_script = ResourceLoader.load("user://maps/Archipelago/panel.gd")
	for panel in gamedata.panels:
		var panel_node
		if panel["id"].begins_with("EndPanel"):
			panel_node = self.get_node("Decorations").get_node(panel["id"])
		else:
			panel_node = panels_parent.get_node(panel["id"])
		var script_instance = panel_script.new()
		script_instance.name = "AP_Panel"
		script_instance.data = panel
		panel_node.add_child(script_instance)
		apclient.connect("evaluate_solvability", script_instance, "evaluate_solvability")

	# Hook up the goal panel.
	if apclient._victory_condition == apclient.kTHE_MASTER:
		var the_master = self.get_node("Panels/Countdown Panels/Panel_master_master")
		the_master.get_node("Viewport/GUI/Panel/TextEdit").connect(
			"answer_correct", apclient, "completedGoal"
		)
	elif apclient._victory_condition == apclient.kLEVEL_2:
		var level_2 = self.get_node("Decorations/EndPanel/Panel_level_2")
		level_2.get_node("Viewport/GUI/Panel/TextEdit").connect(
			"answer_correct", apclient, "completedGoal"
		)
	else:
		var the_end = self.get_node("Decorations/EndPanel/Panel_end_end")
		the_end.get_node("Viewport/GUI/Panel/TextEdit").connect(
			"answer_correct", apclient, "completedGoal"
		)

	# Create the effects node.
	var effects_script = ResourceLoader.load("user://maps/Archipelago/effects.gd")
	var effects = effects_script.new()
	effects.set_name("AP_Effects")
	self.add_child(effects)

	# Hook up the scene to be able to handle connection failures.
	apclient.connect("could_not_connect", self, "archipelago_disconnected")

	# Proceed with the rest of the load.
	global._print("Hooked Load End")
	._load()

	# Process any items received while the map was loading, and send the checks
	# from the save load.
	apclient.mapFinishedLoading()


func _load_user_textures():
	# We are using this function as a hook to process queued Iceland Traps
	# because it happens after the environment gets set.
	var effects_node = get_tree().get_root().get_node("Spatial/AP_Effects")
	effects_node.activate()

	._load_user_textures()


func sort_by_link(a, b):
	return a["link"] < b["link"]


func set_static_panel(name, question, answer = ""):
	if answer == "":
		answer = question

	var node = self.get_node("Panels").get_node(name)

	node.text = question
	node.answer = answer


func instantiate_painting(name, scene):
	var apclient = global.get_node("Archipelago")

	var scene_path = "res://nodes/paintings/%s.tscn" % scene
	var painting_scene = load(scene_path)
	var new_painting = painting_scene.instance()
	new_painting.set_name(name)

	var old_painting = self.get_node("Decorations/Paintings").get_node(name)
	new_painting.translation = old_painting.translation
	new_painting.rotation = old_painting.rotation

	var mypainting_script = ResourceLoader.load("user://maps/Archipelago/mypainting.gd")
	var mps_inst = mypainting_script.new()
	mps_inst.set_name("Script")

	var gamedata = apclient.get_node("Gamedata")
	var pconfig = gamedata.paintings[name]
	mps_inst.orientation = pconfig["orientation"]
	if pconfig["move"]:
		mps_inst.move = true
		mps_inst.move_to_x = old_painting.move_to_x
		mps_inst.move_to_z = old_painting.move_to_z
		mps_inst.key = old_painting.key

	self.get_node("AP_Paintings").add_child(new_painting)
	new_painting.add_child(mps_inst)
	old_painting.queue_free()
	return mps_inst


func set_gridmap_tile(x, y, z, tile):
	var gridmap = self.get_node("GridMap")
	var mesh_library = gridmap.mesh_library
	var mapvec = gridmap.world_to_map(gridmap.to_local(Vector3(x, y, z)))

	gridmap.set_cell_item(mapvec.x, mapvec.y, mapvec.z, mesh_library.find_item_by_name(tile))


func set_small_gridmap_tile(x, y, z, tile):
	var gridmap = self.get_node("GridMapSmall")
	var mesh_library = gridmap.mesh_library
	var mapvec = gridmap.world_to_map(gridmap.to_local(Vector3(x, y, z)))

	gridmap.set_cell_item(mapvec.x, mapvec.y, mapvec.z, mesh_library.find_item_by_name(tile))


func archipelago_disconnected(reason):
	var messages_node = self.get_node("Messages")
	messages_node.show_message(reason)
