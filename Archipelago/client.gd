extends Node

var ap_server = ""
var ap_user = ""
var ap_pass = ""

var _client = WebSocketClient.new()
var _last_state = WebSocketPeer.STATE_CLOSED
var _should_process = false

var _datapackage_checksum = ""
var _item_name_to_id = {}
var _location_name_to_id = {}


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
		elif cmd == "DataPackage":
			if message["data"]["games"].has("Lingo"):
				var lingo_pkg = message["data"]["games"]["Lingo"]
				_datapackage_checksum = lingo_pkg["checksum"]
				_item_name_to_id = lingo_pkg["item_name_to_id"]
				_location_name_to_id = lingo_pkg["location_name_to_id"]
				saveSettings()


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
