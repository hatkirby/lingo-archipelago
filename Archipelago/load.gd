extends "res://scripts/load.gd"


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

	# This is the best time to create the location nodes, since the map is now
	# loaded but the panels haven't been solved from the save file yet.
	var panels_parent = self.get_node("Panels")
	var location_script = ResourceLoader.load("user://maps/Archipelago/location.gd")
	for location_name in apclient._location_name_to_id:
		var location = location_script.new()
		location.ap_name = location_name
		location.ap_id = apclient._location_name_to_id[location_name]
		location.name = "AP_location_" + location.ap_id
		self.add_child(location)

		var panels = apclient._panel_ids_by_location[String(location.ap_id)]
		location.total = panels.size()

		for panel in panels:
			var that_panel = panels_parent.get_node(panel)
			that_panel.get_node("Viewport/GUI/Panel/TextEdit").connect(
				"answer_correct", location, "handle_correct"
			)

	# Randomize the panels, if necessary.
	var rng = RandomNumberGenerator.new()
	rng.seed = apclient._slot_seed

	var gamedata = apclient.get_node("Gamedata")
	if apclient._panel_shuffle == apclient.kREARRANGE_PANELS:
		# Move mandatory wall-snipes in front of their respective walls. In
		# the case of ZERO, we need to change it to be a black puzzle because
		# the wall is black.
		self.get_node("Panels/Backside Room/Panel_zero_zero").translation.z = 16.499
		set_static_panel("Backside Room/Panel_zero_zero", "reknits", "stinker")

		self.get_node("Panels/Backside Room/Panel_fourth_fourth").translation.z = -65.001
		self.get_node("Panels/Chemistry Room/Panel_open").translation.x = -87.001

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
	set_static_panel("Entry Room/Panel_write_write", "seed")
	set_static_panel("Entry Room/Panel_same_same", str(apclient._slot_seed))
	set_static_panel("Entry Room/Panel_type_type", "victory")

	var victory_condition = "unknown"
	if apclient._victory_condition == apclient.kTHE_END:
		victory_condition = "the end"
	elif apclient._victory_condition == apclient.kTHE_MASTER:
		victory_condition = "the master"

	set_static_panel("Entry Room/Panel_this_this", victory_condition)
	set_static_panel("Entry Room/Panel_hidden_hidden", "hewwo")
	set_static_panel("Entry Room/Panel_hi_high", "goode", "good")
	set_static_panel("Entry Room/Panel_low_low", "serendipity", "luck")
	set_static_panel("Shuffle Room/Panel_secret_secret", "trans rights", "human rights")

	# Randomize the paintings, if necessary.
	if apclient._painting_shuffle:
		var pd_script = ResourceLoader.load("user://maps/Archipelago/paintingdata.gd")
		var pd = pd_script.new()
		pd.set_name("AP_Paintings")
		self.add_child(pd)

		var all_paintings = pd.kALL_PAINTINGS

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

		for painting in apclient._paintings.keys():
			if randomized.has(painting):
				continue

			var chosen_painting = remaining[rng.randi_range(0, remaining.size() - 1)]
			instantiate_painting(painting, chosen_painting)

	# Attach a script to every panel so that we can do things like conditionally
	# disable them.
	var panel_script = ResourceLoader.load("user://maps/Archipelago/panel.gd")
	for panel in gamedata.panels:
		var panel_node = panels_parent.get_node(panel["id"])
		var script_instance = panel_script.new()
		script_instance.name = "AP_Panel"
		script_instance.data = panel
		panel_node.add_child(script_instance)
		apclient.connect("evaluate_solvability", script_instance, "evaluate_solvability")

	# Hook up the goal panel.
	if apclient._victory_condition == 1:
		var the_master = self.get_node("Panels/Countdown Panels/Panel_master_master")
		the_master.get_node("Viewport/GUI/Panel/TextEdit").connect(
			"answer_correct", apclient, "completedGoal"
		)
	else:
		var the_end = self.get_node("Decorations/EndPanel/Panel_end_end")
		the_end.get_node("Viewport/GUI/Panel/TextEdit").connect(
			"answer_correct", apclient, "completedGoal"
		)

	# Create the messages node.
	var messages_script = ResourceLoader.load("user://maps/Archipelago/messages.gd")
	var messages = messages_script.new()
	messages.set_name("AP_Messages")
	self.add_child(messages)

	# Hook up the scene to be able to handle connection failures.
	apclient.connect("could_not_connect", self, "archipelago_disconnected")

	# Proceed with the rest of the load.
	global._print("Hooked Load End")
	._load()

	# Process any items received while the map was loading, and send the checks
	# from the save load.
	apclient.mapFinishedLoading()


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

	var pconfig = apclient._paintings[name]
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


func archipelago_disconnected(reason):
	var messages_node = self.get_node("AP_Messages")
	messages_node.show_message(reason)
