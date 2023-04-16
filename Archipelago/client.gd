extends Node

var ap_server = ""
var ap_user = ""
var ap_pass = ""

const ap_version = {"major": 0, "minor": 4, "build": 0, "class": "Version"}
const orange_tower = ["Second", "Third", "Fourth", "Fifth", "Sixth", "Seventh"]

var _client = WebSocketClient.new()
var _last_state = WebSocketPeer.STATE_CLOSED
var _should_process = false

var _datapackages = {}
var _item_id_to_name = {}  # All games
var _location_id_to_name = {}  # All games
var _item_name_to_id = {}  # LINGO only
var _location_name_to_id = {}  # LINGO only

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
var _localdata_file = ""
var _death_link = false
var _victory_condition = 0  # THE END, THE MASTER

var _map_loaded = false
var _held_items = []
var _held_locations = []
var _last_new_item = -1
var _tower_floors = 0

signal client_connected


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
	_client.connect("connection_error", self, "_closed")
	_client.connect("connection_established", self, "_connected")
	_client.connect("data_received", self, "_on_data")


func _closed(was_clean = false):
	global._print("Closed, clean: " + was_clean)
	_should_process = false
	_authenticated = false


func _connected(_proto = ""):
	global._print("Connected!")


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

			var needed_games = []
			for game in message["datapackage_checksums"].keys():
				if (
					!_datapackages.has(game)
					or _datapackages[game]["checksum"] != message["datapackage_checksums"][game]
				):
					needed_games.append(game)

			if !needed_games.empty():
				requestDatapackages(needed_games)
			else:
				connectToRoom()

		elif cmd == "DataPackage":
			for game in message["data"]["games"].keys():
				_datapackages[game] = message["data"]["games"][game]
			saveSettings()
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

			_death_link = _slot_data.has("death_link") and _slot_data["death_link"]
			if _death_link:
				sendConnectUpdate(["DeathLink"])

			if _slot_data.has("victory_condition"):
				_victory_condition = _slot_data["victory_condition"]

			_localdata_file = "user://archipelago/%s_%d" % [_seed, _slot]
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
			global._print("Connection to AP refused")
			global._print(message)

		elif cmd == "ReceivedItems":
			if message["index"] == 0:
				# We are being sent all of our items, so lets reset any progress
				# on progressive items.
				_tower_floors = 0
				_held_items = []

			var i = 0
			for item in message["items"]:
				if _map_loaded:
					processItem(item["item"], message["index"] + i, item["player"])
				else:
					_held_items.append(
						{
							"item": item["item"],
							"index": message["index"] + i,
							"from": item["player"]
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

			var messages_node = get_tree().get_root().get_node("Spatial/AP_Messages")
			if message["type"] == "Hint":
				var is_for = ""
				if message["receiving"] != _slot:
					is_for = " for %s" % player_name
				if !message.has("found") || !message["found"]:
					messages_node.showMessage(
						"Hint: %s%s is on %s" % [item_name, is_for, location_name]
					)
			else:
				if message["receiving"] != _slot:
					messages_node.showMessage("Sent %s to %s" % [item_name, player_name])

		elif cmd == "Bounced":
			if (
				_death_link
				and message.has("tags")
				and message.has("data")
				and message["tags"].has("DeathLink")
			):
				var messages_node = get_tree().get_root().get_node("Spatial/AP_Messages")
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
	var path = "user://archipelago"
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
	var url = "ws://" + ap_server
	var err = _client.connect_to_url(url)
	if err != OK:
		global._print("Could not connect to AP: " + err)
		return
	_should_process = true


func sendMessage(msg):
	var payload = JSON.print(msg)
	_client.get_peer(1).set_write_mode(WebSocketPeer.WRITE_MODE_TEXT)
	_client.get_peer(1).put_packet(payload.to_utf8())


func requestDatapackages(games):
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
		for item in _held_items:
			processItem(item["item"], item["index"], item["from"])

		sendMessage([{"cmd": "LocationChecks", "locations": _held_locations}])

		_map_loaded = true
		_held_items = []
		_held_locations = []


func processItem(item, index, from):
	global._print(item)

	var stringified = String(item)
	if _door_ids_by_item.has(stringified):
		var doorsNode = get_tree().get_root().get_node("Spatial/Doors")
		for door_id in _door_ids_by_item[stringified]:
			doorsNode.get_node(door_id).openDoor()

	if _painting_ids_by_item.has(stringified):
		var paintingsNode = get_tree().get_root().get_node("Spatial/Decorations/Paintings")
		for painting_id in _painting_ids_by_item[stringified]:
			paintingsNode.get_node(painting_id).movePainting()

	# Handle progressively opening up the tower.
	if _item_name_to_id["Progressive Orange Tower"] == item and _tower_floors < orange_tower.size():
		var subitem_name = "Orange Tower - %s Floor" % orange_tower[_tower_floors]
		global._print(subitem_name)
		processItem(_item_name_to_id[subitem_name], null, null)
		_tower_floors += 1

	# Show a message about the item if it's new.
	if index != null and index > _last_new_item:
		_last_new_item = index
		saveLocaldata()

		var item_name = "Unknown"
		if _item_id_to_name.has(item):
			item_name = _item_id_to_name[item]

		var player_name = "Unknown"
		if _player_name_by_slot.has(from):
			player_name = _player_name_by_slot[from]

		var messages_node = get_tree().get_root().get_node("Spatial/AP_Messages")
		if from == _slot:
			messages_node.showMessage("Found %s" % item_name)
		else:
			messages_node.showMessage("Received %s from %s" % [item_name, player_name])


func doorIsVanilla(door):
	return !_mentioned_doors.has(door)


func paintingIsVanilla(painting):
	return !_mentioned_paintings.has(painting)
