extends Node

var ap_server = ""
var ap_user = ""
var ap_pass = ""

const my_version = "0.4.2"
const ap_version = {"major": 0, "minor": 4, "build": 0, "class": "Version"}
const color_items = [
	"White", "Black", "Red", "Blue", "Green", "Brown", "Gray", "Orange", "Purple", "Yellow"
]
const progressive_items = {
	"Progressive Orange Tower":
	[
		{"item": "Orange Tower - Second Floor", "display": "Second Floor"},
		{"item": "Orange Tower - Third Floor", "display": "Third Floor"},
		{"item": "Orange Tower - Fourth Floor", "display": "Fourth Floor"},
		{"item": "Orange Tower - Fifth Floor", "display": "Fifth Floor"},
		{"item": "Orange Tower - Sixth Floor", "display": "Sixth Floor"},
		{"item": "Orange Tower - Seventh Floor", "display": "Seventh Floor"},
	],
	"Progressive Art Gallery":
	[
		{"item": "Art Gallery - Second Floor", "display": "Second Floor"},
		{"item": "Art Gallery - Third Floor", "display": "Third Floor"},
		{"item": "Art Gallery - Fourth Floor", "display": "Fourth Floor"},
		{"item": "Art Gallery - Fifth Floor", "display": "Fifth Floor"},
		{"item": "Art Gallery - Exit", "display": "Exit"},
	],
	"Progressive Hallway Room":
	[
		{"item": "Outside The Agreeable - Hallway Door", "display": "First Door"},
		{"item": "Hallway Room (2) - Exit", "display": "Second Door"},
		{"item": "Hallway Room (3) - Exit", "display": "Third Door"},
		{"item": "Hallway Room (4) - Exit", "display": "Fourth Door"},
	],
	"Progressive Fearless":
	[
		{"item": "The Fearless (First Floor) - Second Floor", "display": "Second Floor"},
		{"item": "The Fearless (Second Floor) - Third Floor", "display": "Third Floor"},
	]
}

const kTHE_END = 0
const kTHE_MASTER = 1

const kNO_PANEL_SHUFFLE = 0
const kREARRANGE_PANELS = 1

var _client = WebSocketClient.new()
var _should_process = false
var _initiated_disconnect = false
var _try_wss = false

var _datapackages = {}
var _pending_packages = []
var _item_id_to_name = {}  # All games
var _location_id_to_name = {}  # All games
var _item_name_to_id = {}  # LINGO only
var _location_name_to_id = {}  # LINGO only

var _remote_version = {"major": 0, "minor": 0, "build": 0}

const uuid_util = preload("user://maps/Archipelago/vendor/uuid.gd")

# TODO: caching per MW/slot, reset between connections
var _authenticated = false
var _seed = ""
var _team = 0
var _slot = 0
var _players = []
var _player_name_by_slot = {}
var _checked_locations = []
var _slot_data = {}
var _door_ids_by_item = {}
var _mentioned_doors = []
var _painting_ids_by_item = {}
var _mentioned_paintings = []
var _panel_ids_by_location = {}
var _paintings = {}
var _paintings_mapping = {}
var _localdata_file = ""
var _death_link = false
var _victory_condition = 0  # THE END, THE MASTER
var _door_shuffle = false
var _color_shuffle = false
var _panel_shuffle = 0  # none, rearrange
var _painting_shuffle = false
var _mastery_achievements = 21
var _slot_seed = 0

var _map_loaded = false
var _held_items = []
var _held_locations = []
var _last_new_item = -1
var _progressive_progress = {}
var _has_colors = ["white"]

signal could_not_connect
signal connect_status
signal client_connected
signal evaluate_solvability


func _init():
	global._print("Instantiated APClient")

	# Read AP settings from file, if there are any
	var file = File.new()
	if file.file_exists("user://settings/archipelago"):
		file.open("user://settings/archipelago", File.READ)
		var data = file.get_var(true)
		file.close()

		if data.size() > 0:
			ap_server = data[0]
		if data.size() > 1:
			ap_user = data[1]
		if data.size() > 2:
			ap_pass = data[2]
		if data.size() > 3:
			_datapackages = data[3]

		processDatapackages()


func _ready():
	_client.connect("connection_closed", self, "_closed")
	_client.connect("connection_failed", self, "_closed")
	_client.connect("server_disconnected", self, "_closed")
	_client.connect("connection_error", self, "_errored")
	_client.connect("connection_established", self, "_connected")
	_client.connect("data_received", self, "_on_data")


func _reset_state():
	_should_process = false
	_authenticated = false
	_map_loaded = false


func _errored():
	if _try_wss:
		global._print("Could not connect to AP with ws://, now trying wss://")
		connectToServer()
	else:
		global._print("AP connection failed")
		_reset_state()

		emit_signal(
			"could_not_connect",
			"Could not connect to Archipelago. Check that your server and port are correct. See the error log for more information."
		)


func _closed(_was_clean = true):
	global._print("Connection closed")
	_reset_state()

	if not _initiated_disconnect:
		emit_signal("could_not_connect", "Disconnected from Archipelago")

	_initiated_disconnect = false


func _connected(_proto = ""):
	global._print("Connected!")
	_try_wss = false


func disconnect_from_ap():
	_initiated_disconnect = true
	_client.disconnect_from_host()


func _on_data():
	var packet = _client.get_peer(1).get_packet()
	global._print("Got data from server: " + packet.get_string_from_utf8())
	var data = JSON.parse(packet.get_string_from_utf8())
	if data.error != OK:
		global._print("Error parsing packet from AP: " + data.error_string)
		return

	for message in data.result:
		var cmd = message["cmd"]
		global._print("Received command: " + cmd)

		if cmd == "RoomInfo":
			_seed = message["seed_name"]
			_remote_version = message["version"]

			var needed_games = []
			for game in message["datapackage_checksums"].keys():
				if (
					!_datapackages.has(game)
					or _datapackages[game]["checksum"] != message["datapackage_checksums"][game]
				):
					needed_games.append(game)

			if !needed_games.empty():
				_pending_packages = needed_games
				var cur_needed = _pending_packages.pop_front()
				requestDatapackages([cur_needed])
			else:
				connectToRoom()

		elif cmd == "DataPackage":
			for game in message["data"]["games"].keys():
				_datapackages[game] = message["data"]["games"][game]
			saveSettings()

			if !_pending_packages.empty():
				var cur_needed = _pending_packages.pop_front()
				requestDatapackages([cur_needed])
			else:
				processDatapackages()
				connectToRoom()

		elif cmd == "Connected":
			_authenticated = true
			_team = message["team"]
			_slot = message["slot"]
			_players = message["players"]
			_checked_locations = message["checked_locations"]
			_slot_data = message["slot_data"]

			for player in _players:
				_player_name_by_slot[player["slot"]] = player["alias"]

			if _slot_data.has("door_ids_by_item_id"):
				_door_ids_by_item = _slot_data["door_ids_by_item_id"]

				_mentioned_doors = []
				for item in _door_ids_by_item.values():
					for door in item:
						_mentioned_doors.append(door)
			if _slot_data.has("painting_ids_by_item_id"):
				_painting_ids_by_item = _slot_data["painting_ids_by_item_id"]

				_mentioned_paintings = []
				for item in _painting_ids_by_item.values():
					for painting in item:
						_mentioned_paintings.append(painting)
			if _slot_data.has("panel_ids_by_location_id"):
				_panel_ids_by_location = _slot_data["panel_ids_by_location_id"]
			if _slot_data.has("paintings"):
				_paintings = _slot_data["paintings"]

			_death_link = _slot_data.has("death_link") and _slot_data["death_link"]
			if _death_link:
				sendConnectUpdate(["DeathLink"])

			if _slot_data.has("victory_condition"):
				_victory_condition = _slot_data["victory_condition"]
			if _slot_data.has("shuffle_colors"):
				_color_shuffle = _slot_data["shuffle_colors"]
			if _slot_data.has("shuffle_doors"):
				_door_shuffle = (_slot_data["shuffle_doors"] > 0)
			if _slot_data.has("shuffle_paintings"):
				_painting_shuffle = (_slot_data["shuffle_paintings"] > 0)
			if _slot_data.has("shuffle_panels"):
				_panel_shuffle = _slot_data["shuffle_panels"]
			if _slot_data.has("seed"):
				_slot_seed = _slot_data["seed"]
			if _slot_data.has("painting_entrance_to_exit"):
				_paintings_mapping = _slot_data["painting_entrance_to_exit"]
			if _slot_data.has("mastery_achievements"):
				_mastery_achievements = _slot_data["mastery_achievements"]

			_localdata_file = "user://archipelago_data/%s_%d" % [_seed, _slot]
			var ap_file = File.new()
			if ap_file.file_exists(_localdata_file):
				ap_file.open(_localdata_file, File.READ)
				var localdata = ap_file.get_var(true)
				ap_file.close()

				if localdata.size() > 0:
					_last_new_item = localdata[0]
				else:
					_last_new_item = -1

			requestSync()

			emit_signal("client_connected")

		elif cmd == "ConnectionRefused":
			var error_message = ""
			for error in message["errors"]:
				var submsg = ""
				if error == "InvalidSlot":
					submsg = "Invalid player name."
				elif error == "InvalidGame":
					submsg = "The specified player is not playing Lingo."
				elif error == "IncompatibleVersion":
					submsg = (
						"The Archipelago server is not the correct version for this client. Expected v%d.%d.%d. Found v%d.%d.%d."
						% [
							ap_version["major"],
							ap_version["minor"],
							ap_version["build"],
							_remote_version["major"],
							_remote_version["minor"],
							_remote_version["build"]
						]
					)
				elif error == "InvalidPassword":
					submsg = "Incorrect password."
				elif error == "InvalidItemsHandling":
					submsg = "Invalid item handling flag. This is a bug with the client. Please report it to the lingo-archipelago GitHub."

				if submsg != "":
					if error_message != "":
						error_message += " "
					error_message += submsg

			if error_message == "":
				error_message = "Unknown error."

			_initiated_disconnect = true
			_client.disconnect_from_host()

			emit_signal("could_not_connect", error_message)
			global._print("Connection to AP refused")
			global._print(message)

		elif cmd == "ReceivedItems":
			if message["index"] == 0:
				# We are being sent all of our items, so lets reset any progress
				# on progressive items.
				_progressive_progress.clear()
				_held_items = []

			var i = 0
			for item in message["items"]:
				if _map_loaded:
					processItem(item["item"], message["index"] + i, item["player"], item["flags"])
				else:
					_held_items.append(
						{
							"item": item["item"],
							"index": message["index"] + i,
							"from": item["player"],
							"flags": item["flags"]
						}
					)
				i += 1

		elif cmd == "PrintJSON":
			if (
				!message.has("receiving")
				or !message.has("item")
				or message["item"]["player"] != _slot
			):
				continue

			var item_name = "Unknown"
			if _item_id_to_name.has(message["item"]["item"]):
				item_name = _item_id_to_name[message["item"]["item"]]

			var location_name = "Unknown"
			if _location_id_to_name.has(message["item"]["location"]):
				location_name = _location_id_to_name[message["item"]["location"]]

			var player_name = "Unknown"
			if _player_name_by_slot.has(message["receiving"]):
				player_name = _player_name_by_slot[message["receiving"]]

			var item_color = colorForItemType(message["item"]["flags"])

			var messages_node = get_tree().get_root().get_node("Spatial/Messages")
			if message["type"] == "Hint":
				var is_for = ""
				if message["receiving"] != _slot:
					is_for = " for %s" % player_name
				if !message.has("found") || !message["found"]:
					messages_node.showMessage(
						(
							"Hint: [color=%s]%s[/color]%s is on %s"
							% [item_color, item_name, is_for, location_name]
						)
					)
			else:
				if message["receiving"] != _slot:
					messages_node.showMessage(
						"Sent [color=%s]%s[/color] to %s" % [item_color, item_name, player_name]
					)

		elif cmd == "Bounced":
			if (
				_death_link
				and message.has("tags")
				and message.has("data")
				and message["tags"].has("DeathLink")
			):
				var messages_node = get_tree().get_root().get_node("Spatial/Messages")
				var first_sentence = "Received Death"
				var second_sentence = ""
				if message["data"].has("source"):
					first_sentence = "Received Death from %s" % message["data"]["source"]
				if message["data"].has("cause"):
					second_sentence = ". Reason: %s" % message["data"]["cause"]
				messages_node.showMessage(first_sentence + second_sentence)

				# Return the player home.
				get_tree().get_root().get_node("Spatial/player/pause_menu")._reload()


func _process(_delta):
	if _should_process:
		_client.poll()


func saveSettings():
	# Save the AP settings to disk.
	var dir = Directory.new()
	var path = "user://settings"
	if dir.dir_exists(path):
		pass
	else:
		dir.make_dir(path)

	var file = File.new()
	file.open("user://settings/archipelago", File.WRITE)

	var data = [ap_server, ap_user, ap_pass, _datapackages]
	file.store_var(data, true)
	file.close()


func saveLocaldata():
	# Save the MW/slot specific settings to disk.
	var dir = Directory.new()
	var path = "user://archipelago_data"
	if dir.dir_exists(path):
		pass
	else:
		dir.make_dir(path)

	var file = File.new()
	file.open(_localdata_file, File.WRITE)

	var data = [_last_new_item]
	file.store_var(data, true)
	file.close()


func getSaveFileName():
	return "zzAP_%s_%d" % [_seed, _slot]


func connectToServer():
	_initiated_disconnect = false

	var url = ""
	if ap_server.begins_with("ws://") or ap_server.begins_with("wss://"):
		url = ap_server
		_try_wss = false
	elif _try_wss:
		url = "wss://" + ap_server
		_try_wss = false
	else:
		url = "ws://" + ap_server
		_try_wss = true

	var err = _client.connect_to_url(url)
	if err != OK:
		emit_signal(
			"could_not_connect",
			(
				"Could not connect to Archipelago. Check that your server and port are correct. See the error log for more information. Error code: %d."
				% err
			)
		)
		global._print("Could not connect to AP: " + err)
		return
	_should_process = true

	emit_signal("connect_status", "Connecting...")


func sendMessage(msg):
	var payload = JSON.print(msg)
	_client.get_peer(1).set_write_mode(WebSocketPeer.WRITE_MODE_TEXT)
	_client.get_peer(1).put_packet(payload.to_utf8())


func requestDatapackages(games):
	emit_signal("connect_status", "Downloading %s data package..." % games[0])

	sendMessage([{"cmd": "GetDataPackage", "games": games}])


func processDatapackages():
	_item_id_to_name = {}
	_location_id_to_name = {}
	for package in _datapackages.values():
		for name in package["item_name_to_id"].keys():
			_item_id_to_name[package["item_name_to_id"][name]] = name

		for name in package["location_name_to_id"].keys():
			_location_id_to_name[package["location_name_to_id"][name]] = name

	if _datapackages.has("Lingo"):
		_item_name_to_id = _datapackages["Lingo"]["item_name_to_id"]
		_location_name_to_id = _datapackages["Lingo"]["location_name_to_id"]


func connectToRoom():
	emit_signal("connect_status", "Authenticating...")

	sendMessage(
		[
			{
				"cmd": "Connect",
				"password": ap_pass,
				"game": "Lingo",
				"name": ap_user,
				"uuid": uuid_util.v4(),
				"version": ap_version,
				"items_handling": 0b111,  # always receive our items
				"tags": [],
				"slot_data": true
			}
		]
	)


func sendConnectUpdate(tags):
	sendMessage([{"cmd": "ConnectUpdate", "tags": tags}])


func requestSync():
	sendMessage([{"cmd": "Sync"}])


func sendLocation(loc_id):
	if _map_loaded:
		sendMessage([{"cmd": "LocationChecks", "locations": [loc_id]}])
	else:
		_held_locations.append(loc_id)


func completedGoal():
	sendMessage([{"cmd": "StatusUpdate", "status": 30}])  # CLIENT_GOAL


func mapFinishedLoading():
	if !_map_loaded:
		_has_colors = ["white"]
		emit_signal("evaluate_solvability")

		for item in _held_items:
			processItem(item["item"], item["index"], item["from"], item["flags"])

		sendMessage([{"cmd": "LocationChecks", "locations": _held_locations}])

		_map_loaded = true
		_held_items = []
		_held_locations = []


func processItem(item, index, from, flags):
	global._print(item)

	var stringified = String(item)
	if _door_ids_by_item.has(stringified):
		var doorsNode = get_tree().get_root().get_node("Spatial/Doors")
		for door_id in _door_ids_by_item[stringified]:
			doorsNode.get_node(door_id).openDoor()

	if _painting_ids_by_item.has(stringified):
		var real_parent_node = get_tree().get_root().get_node("Spatial/Decorations/Paintings")
		var fake_parent_node = get_tree().get_root().get_node("Spatial/AP_Paintings")

		for painting_id in _painting_ids_by_item[stringified]:
			var painting_node = real_parent_node.get_node_or_null(painting_id)
			if painting_node != null:
				painting_node.movePainting()

			if _painting_shuffle:
				painting_node = fake_parent_node.get_node_or_null(painting_id)
				if painting_node != null:
					painting_node.get_node("Script").movePainting()

	# Handle progressive items.
	var item_name = "Unknown"
	if _item_id_to_name.has(item):
		item_name = _item_id_to_name[item]

	if item_name in progressive_items.keys():
		if not item_name in _progressive_progress:
			_progressive_progress[item_name] = 0

		if _progressive_progress[item_name] < progressive_items[item_name].size():
			var subitem_name = progressive_items[item_name][_progressive_progress[item_name]]["item"]
			global._print(subitem_name)
			processItem(_item_name_to_id[subitem_name], null, null, null)
			_progressive_progress[item_name] += 1

	if _color_shuffle and color_items.has(_item_id_to_name[item]):
		var lcol = _item_id_to_name[item].to_lower()
		if not _has_colors.has(lcol):
			_has_colors.append(lcol)
			emit_signal("evaluate_solvability")

	# Show a message about the item if it's new. Also apply effects here.
	if index != null and index > _last_new_item:
		_last_new_item = index
		saveLocaldata()

		if item_name in progressive_items:
			var subitem = progressive_items[item_name][_progressive_progress[item_name] - 1]
			item_name += " (%s)" % subitem["display"]

		var player_name = "Unknown"
		if _player_name_by_slot.has(from):
			player_name = _player_name_by_slot[from]

		var item_color = colorForItemType(flags)

		var messages_node = get_tree().get_root().get_node("Spatial/Messages")
		if from == _slot:
			messages_node.showMessage("Found [color=%s]%s[/color]" % [item_color, item_name])
		else:
			messages_node.showMessage(
				"Received [color=%s]%s[/color] from %s" % [item_color, item_name, player_name]
			)

		var effects_node = get_tree().get_root().get_node("Spatial/AP_Effects")
		if item_name == "Slowness Trap":
			effects_node.trigger_slowness_trap()
		if item_name == "Iceland Trap":
			effects_node.trigger_iceland_trap()


func doorIsVanilla(door):
	return !_mentioned_doors.has(door)


func paintingIsVanilla(painting):
	return !_mentioned_paintings.has(painting)


func colorForItemType(flags):
	var int_flags = int(flags)
	if int_flags & 1:  # progression
		return "#bc51e0"
	elif int_flags & 2:  # useful
		return "#2b67ff"
	elif int_flags & 4:  # trap
		return "#d63a22"
	else:  # filler
		return "#14de9e"
