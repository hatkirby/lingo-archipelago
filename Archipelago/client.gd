extends Node

var ap_server = ""
var ap_user = ""
var ap_pass = ""

const ap_version = {"major": 0, "minor": 4, "build": 0, "class": "Version"}

var _client = WebSocketClient.new()
var _last_state = WebSocketPeer.STATE_CLOSED
var _should_process = false

var _datapackage_checksum = ""
var _item_name_to_id = {}
var _location_name_to_id = {}

const uuid_util = preload("user://maps/Archipelago/vendor/uuid.gd")

# TODO: caching per MW/slot, reset between connections
var _authenticated = false
var _team = 0
var _slot = 0
var _players = []
var _checked_locations = []
var _slot_data = {}
var _door_ids_by_item = {}
var _mentioned_doors = []
var _painting_ids_by_item = {}
var _mentioned_paintings = []
var _panel_ids_by_location = {}

var _map_loaded = false
var _held_items = []
var _held_locations = []

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
			_datapackage_checksum = data[3]
		if data.size() > 4:
			_item_name_to_id = data[4]
		if data.size() > 5:
			_location_name_to_id = data[5]


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
			if message["datapackage_checksums"].has("Lingo"):
				if _datapackage_checksum != message["datapackage_checksums"]["Lingo"]:
					requestDatapackage()
				else:
					connectToRoom()

		elif cmd == "DataPackage":
			if message["data"]["games"].has("Lingo"):
				var lingo_pkg = message["data"]["games"]["Lingo"]
				_datapackage_checksum = lingo_pkg["checksum"]
				_item_name_to_id = lingo_pkg["item_name_to_id"]
				_location_name_to_id = lingo_pkg["location_name_to_id"]
				saveSettings()

				connectToRoom()

		elif cmd == "Connected":
			_authenticated = true
			_team = message["team"]
			_slot = message["slot"]
			_players = message["players"]
			_checked_locations = message["checked_locations"]
			_slot_data = message["slot_data"]

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

			requestSync()

			emit_signal("client_connected")

		elif cmd == "ConnectionRefused":
			global._print("Connection to AP refused")
			global._print(message)

		elif cmd == "ReceivedItems":
			for item in message["items"]:
				if _map_loaded:
					processItem(item["item"])
				else:
					_held_items.append(item["item"])


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

	var data = [
		ap_server, ap_user, ap_pass, _datapackage_checksum, _item_name_to_id, _location_name_to_id
	]
	file.store_var(data, true)
	file.close()


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


func requestDatapackage():
	sendMessage([{"cmd": "GetDataPackage", "games": ["Lingo"]}])


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


func requestSync():
	sendMessage([{"cmd": "Sync"}])


func sendLocation(loc_id):
	if _map_loaded:
		sendMessage([{"cmd": "LocationChecks", "locations": [loc_id]}])
	else:
		_held_locations.append(loc_id)


func mapFinishedLoading():
	if !_map_loaded:
		for item in _held_items:
			processItem(item)

		sendMessage([{"cmd": "LocationChecks", "locations": _held_locations}])

		_map_loaded = true
		_held_items = []
		_held_locations = []


func processItem(item):
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


func doorIsVanilla(door):
	return !_mentioned_doors.has(door)


func paintingIsVanilla(painting):
	return !_mentioned_paintings.has(painting)
