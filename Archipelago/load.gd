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
					"link": panel["link"]
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

	# Proceed with the rest of the load.
	global._print("Hooked Load End")
	._load()

	# Process any items received while the map was loading, and send the checks
	# from the save load.
	apclient.mapFinishedLoading()


func sort_by_link(a, b):
	return a["link"] < b["link"]
