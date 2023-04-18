extends Spatial

var orientation = ""  # north, south, east, west
var move = false
var move_to_x
var move_to_z
var target = null
var key


func _ready():
	var _connected = get_tree().get_root().get_node("Spatial/player").connect(
		"looked_at", self, "_looked_at"
	)
	if move:
		key.get_node("Viewport/GUI/Panel/TextEdit").connect(
			"answer_correct", self, "_answer_correct"
		)


func _answer_correct():
	var apclient = global.get_node("Archipelago")
	if not apclient._door_shuffle or apclient.paintingIsVanilla(self.get_parent().name):
		movePainting()


func movePainting():
	self.get_parent().translation.x = move_to_x
	self.get_parent().translation.z = move_to_z


func _looked_at(body, painting):
	if (
		target != null
		and body.is_in_group("player")
		and (painting.get_name() == self.get_parent().get_name())
	):
		var target_dir = _dir_to_int(target.orientation)
		var source_dir = _dir_to_int(orientation)
		var rotate = target_dir - source_dir
		if rotate < 0:
			rotate += 4
		rotate *= 90

		var target_painting = target.get_parent()

		# this is ACW
		if rotate == 0:
			body.translation.x = (
				target_painting.translation.x + (body.translation.x - painting.translation.x)
			)
			body.translation.y = (
				target_painting.translation.y + (body.translation.y - painting.translation.y)
			)
			body.translation.z = (
				target_painting.translation.z + (body.translation.z - painting.translation.z)
			)
		elif rotate == 180:
			body.translation.x = (
				target_painting.translation.x - (body.translation.x - painting.translation.x)
			)
			body.translation.y = (
				target_painting.translation.y + (body.translation.y - painting.translation.y)
			)
			body.translation.z = (
				target_painting.translation.z - (body.translation.z - painting.translation.z)
			)
			body.rotate_y(PI)
			body.velocity = body.velocity.rotated(Vector3(0, 1, 0), PI)
		elif rotate == 90:
			var diff_x = body.translation.x - painting.translation.x
			var diff_y = body.translation.y - painting.translation.y
			var diff_z = body.translation.z - painting.translation.z
			body.translation.x = target_painting.translation.x + diff_z
			body.translation.y = target_painting.translation.y + diff_y
			body.translation.z = target_painting.translation.z - diff_x
			body.rotate_y(PI / 2)
			body.velocity = body.velocity.rotated(Vector3(0, 1, 0), PI / 2)
		elif rotate == 270:
			var diff_x = body.translation.x - painting.translation.x
			var diff_y = body.translation.y - painting.translation.y
			var diff_z = body.translation.z - painting.translation.z
			body.translation.x = target_painting.translation.x - diff_z
			body.translation.y = target_painting.translation.y + diff_y
			body.translation.z = target_painting.translation.z + diff_x
			body.rotate_y(3 * PI / 2)
			body.velocity = body.velocity.rotated(Vector3(0, 1, 0), 3 * PI / 2)


func _dir_to_int(dir):
	if dir == "north":
		return 0
	elif dir == "west":
		return 1
	elif dir == "south":
		return 2
	elif dir == "east":
		return 3
	return 4
